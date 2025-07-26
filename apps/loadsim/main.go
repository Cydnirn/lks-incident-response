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
	app.Post("/start", startHandler)
	app.Post("/stop", stopHandler)
	app.Get("/status", statusHandler)
	app.Post("/setting", settingHandler)
	app.Get("/health", healthHandler)
	app.Post("/database", databaseHandler)
	app.Get("/error", errorHandler)
	app.Get("/crash", crashHandler)
	app.Get("/shutdown", makeShutdownHandler(app))

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
		CPULoadPercent: 50,
		MemoryGB:       1.0,
		DurationSec:    0,
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

	if memGB := os.Getenv("MEMORY_GB"); memGB != "" {
		if val, err := strconv.ParseFloat(memGB, 64); err == nil {
			settings.MemoryGB = val
		}
	}

	if duration := os.Getenv("DURATION_SEC"); duration != "" {
		if val, err := strconv.Atoi(duration); err == nil {
			settings.DurationSec = val
		}
	}

	// Initialize status
	status = LoadStatus{
		Running:        false,
		CPULoadPercent: 0,
		MemoryGB:       0,
		DatabaseStatus: "Not tested",
	}

	log.Printf("Initialized with settings: CPU=%d%%, Memory=%.2fGB, Duration=%ds",
		settings.CPULoadPercent, settings.MemoryGB, settings.DurationSec)
}
