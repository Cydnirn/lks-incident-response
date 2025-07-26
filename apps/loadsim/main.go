package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

var (
	// Global variables for load management
	status        LoadStatus
	settings      LoadSettings
	statusMutex   sync.RWMutex
	cancelFunc    context.CancelFunc
	memoryBlocks  [][]byte
	cpuLoadActive int32
)

func main() {
	// Initialize default settings from environment variables
	initializeSettings()

	// Create Fiber app
	app := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).SendString(err.Error())
		},
	})

	// Middleware
	app.Use(logger.New())
	app.Use(cors.New())

	// Routes
	app.Get("/", rootHandler)
	app.Get("/status", statusHandler)
	app.Get("/health", healthHandler)
	app.Get("/error", errorHandler)
	app.Get("/crash", crashHandler)
	app.Get("/shutdown", makeShutdownHandler(app))
	app.Post("/start", startHandler)
	app.Post("/stop", stopHandler)
	app.Post("/setting", settingHandler)
	app.Post("/database", databaseHandler)

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %s", port)
		if err := app.Listen(":" + port); err != nil {
			log.Printf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)

	<-quit
	log.Println("Gracefully shutting down...")

	// Stop any running load first
	statusMutex.Lock()
	if status.Running && cancelFunc != nil {
		log.Println("Stopping running load...")
		cancelFunc()
		status.Running = false
		memoryBlocks = nil
		atomic.StoreInt32(&cpuLoadActive, 0)
	}
	statusMutex.Unlock()

	// Give a moment for load to stop
	time.Sleep(100 * time.Millisecond)

	// Shutdown server with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	log.Println("Shutting down server...")
	if err := app.ShutdownWithContext(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
		os.Exit(1)
	}

	log.Println("Server exited successfully")
}

func initializeSettings() {
	// Initialize default settings
	settings = LoadSettings{
		CPULoadPercent:      50,
		MemoryMB:            1024, // 1GB in MB
		DurationSec:         0,
		CrashAfterTimeMs:    5000,  // 5 seconds default
		ShutdownAfterTimeMs: 10000, // 10 seconds default
	}

	// Override with environment variables if present
	if cpuLoad := os.Getenv("CPU_LOAD_PERCENT"); cpuLoad != "" {
		if val, err := strconv.Atoi(cpuLoad); err == nil {
			if val > 80 {
				val = 80
			}
			settings.CPULoadPercent = val
		}
	}

	if memMB := os.Getenv("MEMORY_MB"); memMB != "" {
		if val, err := strconv.Atoi(memMB); err == nil {
			settings.MemoryMB = val
		}
	}

	if duration := os.Getenv("DURATION_SEC"); duration != "" {
		if val, err := strconv.Atoi(duration); err == nil {
			settings.DurationSec = val
		}
	}

	// Handle crash environment variable
	if crashEnv := os.Getenv("CRASH"); crashEnv != "" {
		if crashEnabled, err := strconv.ParseBool(crashEnv); err == nil && crashEnabled {
			if crashTime := os.Getenv("CRASH_AFTER_TIME_MS"); crashTime != "" {
				if val, err := strconv.Atoi(crashTime); err == nil {
					settings.CrashAfterTimeMs = val
				}
			}
		}
	}

	// Handle shutdown environment variable
	if shutdownEnv := os.Getenv("SHUTDOWN"); shutdownEnv != "" {
		if shutdownEnabled, err := strconv.ParseBool(shutdownEnv); err == nil && shutdownEnabled {
			if shutdownTime := os.Getenv("SHUTDOWN_AFTER_TIME_MS"); shutdownTime != "" {
				if val, err := strconv.Atoi(shutdownTime); err == nil {
					settings.ShutdownAfterTimeMs = val
				}
			}
		}
	}

	// Initialize status
	status = LoadStatus{
		Running:             false,
		CPULoadPercent:      0,
		MemoryMB:            0,
		DatabaseStatus:      "Not tested",
		CrashAfterTimeMs:    settings.CrashAfterTimeMs,
		ShutdownAfterTimeMs: settings.ShutdownAfterTimeMs,
	}

	log.Printf("Initialized with settings: CPU=%d%%, Memory=%dMB, Duration=%ds, CrashAfter=%dms, ShutdownAfter=%dms",
		settings.CPULoadPercent, settings.MemoryMB, settings.DurationSec, settings.CrashAfterTimeMs, settings.ShutdownAfterTimeMs)
}
