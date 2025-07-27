package main

import (
	"context"
	"encoding/json"
	"fmt"
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
	appConfig     AppConfig
	dynamicLoad   DynamicLoadConfig
	statusMutex   sync.RWMutex
	cancelFunc    context.CancelFunc
	memoryBlocks  [][]byte
	cpuLoadActive int32
)

// JSONLogger is a custom logger that outputs JSON formatted logs
type JSONLogger struct{}

func (l *JSONLogger) Write(p []byte) (n int, err error) {
	logEntry := LogEntry{
		Timestamp:   time.Now(),
		Level:       "INFO",
		Message:     string(p),
		Service:     "loadsim",
		Environment: appConfig.Environment,
	}

	jsonData, err := json.Marshal(logEntry)
	if err != nil {
		// Fallback to standard log if JSON marshaling fails
		return os.Stderr.Write(p)
	}

	// Add newline for readability
	jsonData = append(jsonData, '\n')
	return os.Stderr.Write(jsonData)
}

// logJSON logs a structured JSON message
func logJSON(level, message string, extra map[string]interface{}) {
	logEntry := LogEntry{
		Timestamp:   time.Now(),
		Level:       level,
		Message:     message,
		Service:     "loadsim",
		Environment: appConfig.Environment,
		Extra:       extra,
	}

	jsonData, err := json.Marshal(logEntry)
	if err != nil {
		log.Printf("Failed to marshal JSON log: %v", err)
		return
	}

	os.Stderr.Write(append(jsonData, '\n'))
}

// logError logs an error with stack trace and status code
func logError(message string, err error, statusCode int) {
	extra := map[string]interface{}{
		"error": err.Error(),
	}

	if err != nil {
		extra["error_type"] = "error"
	}

	logEntry := LogEntry{
		Timestamp:   time.Now(),
		Level:       "ERROR",
		Message:     message,
		Service:     "loadsim",
		Environment: appConfig.Environment,
		StatusCode:  statusCode,
		Error:       err.Error(),
		Extra:       extra,
	}

	jsonData, err := json.Marshal(logEntry)
	if err != nil {
		log.Printf("Failed to marshal JSON log: %v", err)
		return
	}

	os.Stderr.Write(append(jsonData, '\n'))
}

// logInfo logs an info message
func logInfo(message string, extra map[string]interface{}) {
	logJSON("INFO", message, extra)
}

// logWarn logs a warning message
func logWarn(message string, extra map[string]interface{}) {
	logJSON("WARN", message, extra)
}

// logDebug logs a debug message
func logDebug(message string, extra map[string]interface{}) {
	logJSON("DEBUG", message, extra)
}

func main() {
	// Initialize configuration first
	initializeConfig()

	// Set up JSON logging
	log.SetOutput(&JSONLogger{})

	// Initialize default settings from environment variables
	initializeSettings()

	// Create Fiber app
	app := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			// Log error in JSON format with status code
			logError("HTTP request error", err, code)

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

	// Dynamic load endpoints
	app.Get("/load", dynamicLoadHandler)
	app.Get("/load/reset", dynamicLoadResetHandler)

	// Start server in a goroutine
	go func() {
		logInfo("Server starting", map[string]interface{}{
			"port":        appConfig.Port,
			"environment": appConfig.Environment,
		})
		if err := app.Listen(":" + appConfig.Port); err != nil {
			logError("Server failed to start", err, 500)
		}
	}()

	// Handle immediate crash/shutdown if configured
	handleImmediateActions()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)

	<-quit
	logInfo("Gracefully shutting down", nil)

	// Stop any running load first
	statusMutex.Lock()
	if status.Running && cancelFunc != nil {
		logInfo("Stopping running load", nil)
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

	logInfo("Shutting down server", nil)
	if err := app.ShutdownWithContext(ctx); err != nil {
		logError("Server forced to shutdown", err, 500)
		os.Exit(1)
	}

	logInfo("Server exited successfully", nil)
}

func initializeConfig() {
	// Initialize app configuration
	appConfig = AppConfig{
		Environment: "development", // default
		Port:        "8080",        // default
		Crash: CrashConfig{
			Enabled:     false,
			AfterTimeMs: 5000, // default 5 seconds
		},
		Shutdown: ShutdownConfig{
			Enabled:     false,
			AfterTimeMs: 10000, // default 10 seconds
		},
	}

	// Initialize dynamic load configuration
	dynamicLoad = DynamicLoadConfig{
		CurrentCPULoad: 0,  // Start with 0% CPU load
		MaxCPULoad:     70, // Maximum 70% CPU load
		IncrementStep:  10, // Increment by 10% per request
	}

	// Load environment from ENV
	if env := os.Getenv("ENVIRONMENT"); env != "" {
		appConfig.Environment = env
	}

	// Load port from ENV
	if port := os.Getenv("PORT"); port != "" {
		appConfig.Port = port
	}

	// Load crash configuration
	if crashEnv := os.Getenv("CRASH"); crashEnv != "" {
		if enabled, err := strconv.ParseBool(crashEnv); err == nil {
			appConfig.Crash.Enabled = enabled
		}
	}

	if crashTimeEnv := os.Getenv("CRASH_AFTER_TIME_MS"); crashTimeEnv != "" {
		if val, err := strconv.Atoi(crashTimeEnv); err == nil {
			appConfig.Crash.AfterTimeMs = val
		}
	}

	// Load shutdown configuration
	if shutdownEnv := os.Getenv("SHUTDOWN"); shutdownEnv != "" {
		if enabled, err := strconv.ParseBool(shutdownEnv); err == nil {
			appConfig.Shutdown.Enabled = enabled
		}
	}

	if shutdownTimeEnv := os.Getenv("SHUTDOWN_AFTER_TIME_MS"); shutdownTimeEnv != "" {
		if val, err := strconv.Atoi(shutdownTimeEnv); err == nil {
			appConfig.Shutdown.AfterTimeMs = val
		}
	}

	logInfo("Application configuration loaded", map[string]interface{}{
		"environment":            appConfig.Environment,
		"port":                   appConfig.Port,
		"crash_enabled":          appConfig.Crash.Enabled,
		"crash_after_time_ms":    appConfig.Crash.AfterTimeMs,
		"shutdown_enabled":       appConfig.Shutdown.Enabled,
		"shutdown_after_time_ms": appConfig.Shutdown.AfterTimeMs,
		"dynamic_load_max":       dynamicLoad.MaxCPULoad,
		"dynamic_load_step":      dynamicLoad.IncrementStep,
	})
}

func handleImmediateActions() {
	// Handle immediate crash if enabled and no time specified (or time = 0)
	if appConfig.Crash.Enabled && appConfig.Crash.AfterTimeMs <= 0 {
		logError("Immediate crash triggered", fmt.Errorf("CRASH=true with no delay specified"), 1)
		panic("Immediate crash triggered by CRASH environment variable")
	}

	// Handle immediate shutdown if enabled and no time specified (or time = 0)
	if appConfig.Shutdown.Enabled && appConfig.Shutdown.AfterTimeMs <= 0 {
		logInfo("Immediate shutdown triggered", map[string]interface{}{
			"reason": "SHUTDOWN=true with no delay specified",
		})
		os.Exit(0)
	}

	// Handle delayed crash if enabled and time > 0
	if appConfig.Crash.Enabled && appConfig.Crash.AfterTimeMs > 0 {
		go func() {
			logInfo("Crash timer started", map[string]interface{}{
				"crash_after_time_ms": appConfig.Crash.AfterTimeMs,
			})
			time.Sleep(time.Duration(appConfig.Crash.AfterTimeMs) * time.Millisecond)
			logError("Delayed crash triggered", fmt.Errorf("CRASH=true with %dms delay", appConfig.Crash.AfterTimeMs), 1)
			panic("Delayed crash triggered by CRASH environment variable")
		}()
	}

	// Handle delayed shutdown if enabled and time > 0
	if appConfig.Shutdown.Enabled && appConfig.Shutdown.AfterTimeMs > 0 {
		go func() {
			logInfo("Shutdown timer started", map[string]interface{}{
				"shutdown_after_time_ms": appConfig.Shutdown.AfterTimeMs,
			})
			time.Sleep(time.Duration(appConfig.Shutdown.AfterTimeMs) * time.Millisecond)
			logInfo("Delayed shutdown triggered", map[string]interface{}{
				"reason": fmt.Sprintf("SHUTDOWN=true with %dms delay", appConfig.Shutdown.AfterTimeMs),
			})
			os.Exit(0)
		}()
	}
}

func initializeSettings() {
	// Initialize default settings
	settings = LoadSettings{
		CPULoadPercent:      5,    // Changed from 50% to 5% as requested
		MemoryMB:            1024, // 1GB in MB
		DurationSec:         0,
		CrashAfterTimeMs:    appConfig.Crash.AfterTimeMs,
		ShutdownAfterTimeMs: appConfig.Shutdown.AfterTimeMs,
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

	// Initialize status
	status = LoadStatus{
		Running:             false,
		CPULoadPercent:      0,
		MemoryMB:            0,
		DatabaseStatus:      "Not tested",
		CrashAfterTimeMs:    settings.CrashAfterTimeMs,
		ShutdownAfterTimeMs: settings.ShutdownAfterTimeMs,
	}

	logInfo("Load settings initialized", map[string]interface{}{
		"cpu_load_percent":       settings.CPULoadPercent,
		"memory_mb":              settings.MemoryMB,
		"duration_sec":           settings.DurationSec,
		"crash_after_time_ms":    settings.CrashAfterTimeMs,
		"shutdown_after_time_ms": settings.ShutdownAfterTimeMs,
	})
}
