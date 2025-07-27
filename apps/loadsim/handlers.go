package main

import (
	"context"
	"fmt"
	"os"
	"runtime"
	"sync/atomic"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/mem"
)

func rootHandler(c *fiber.Ctx) error {
	statusMutex.RLock()
	defer statusMutex.RUnlock()

	cpuFreq, _ := cpu.Info()
	var totalFreq float64
	var count int
	for _, ci := range cpuFreq {
		if ci.Mhz > 0 {
			totalFreq += float64(ci.Mhz)
			count++
		}
	}
	var currentFreqGHz float64
	if count > 0 {
		currentFreqGHz = totalFreq / float64(count) / 1000.0
	}

	numCPU := runtime.NumCPU()

	// Get CPU usage
	cpuPercent, _ := cpu.Percent(0, false)
	var cpuUsage float64
	if len(cpuPercent) > 0 {
		cpuUsage = cpuPercent[0]
	}

	// Get memory usage
	vmStat, _ := mem.VirtualMemory()

	// Get environment variable values, show (not set, using default) if not set
	envVar := os.Getenv("ENVIRONMENT")
	if envVar == "" {
		envVar = "(not set, using default)"
	}
	cpuLoadEnv := os.Getenv("CPU_LOAD_PERCENT")
	if cpuLoadEnv == "" {
		cpuLoadEnv = "(not set, using default)"
	}
	memMBEnv := os.Getenv("MEMORY_MB")
	if memMBEnv == "" {
		memMBEnv = "(not set, using default)"
	}
	durationEnv := os.Getenv("DURATION_SEC")
	if durationEnv == "" {
		durationEnv = "(not set, using default)"
	}
	portEnv := os.Getenv("PORT")
	if portEnv == "" {
		portEnv = "(not set, using default)"
	}
	crashEnv := os.Getenv("CRASH")
	if crashEnv == "" {
		crashEnv = "(not set, using default)"
	}
	crashTimeEnv := os.Getenv("CRASH_AFTER_TIME_MS")
	if crashTimeEnv == "" {
		crashTimeEnv = "(not set, using default)"
	}
	shutdownEnv := os.Getenv("SHUTDOWN")
	if shutdownEnv == "" {
		shutdownEnv = "(not set, using default)"
	}
	shutdownTimeEnv := os.Getenv("SHUTDOWN_AFTER_TIME_MS")
	if shutdownTimeEnv == "" {
		shutdownTimeEnv = "(not set, using default)"
	}

	usage := fmt.Sprintf(`
<html>
<head><title>LoadSims</title></head>
<body>
<h1>Load-Apps Usage</h1>
<div>
	Load Running: %v <br>
  <button onclick="startLoad()">Start</button>
  <button onclick="stopLoad()">Stop</button>
</div>
<script>
function startLoad() {
  fetch('/start', {method: 'POST'})
    .then(() => location.reload());
}
function stopLoad() {
  fetch('/stop', {method: 'POST'})
    .then(() => location.reload());
}
setInterval(() => {
  location.reload();
}, 1000);
</script>
<h2>Current System Status</h2>
<ul>
<li>Environment: %s</li>
<li>CPU Frequency: %.2f GHz</li>
<li>CPU Cores: %d</li>
<li>CPU Usage: %.2f%%</li>
<li>CPU Load Percent Setting: %d%%</li>
<li>Total Memory: %.2f GB</li>
<li>Memory Usage: %.2f%%</li>
<li>Memory Load Setting: %d MB</li>
<li>Dynamic CPU Load: %d%% (Max: %d%%, Step: %d%%)</li>
</ul>
<h2>Environment Variables</h2>
<ul>
<li>ENVIRONMENT: string (optional) - application environment (development, staging, production) <b>(current: %s)</b></li>
<li>PORT: integer (optional) - server port, default 8080 <b>(current: %s)</b></li>
<li>CPU_LOAD_PERCENT: integer (max 80) - target CPU load percentage <b>(current: %s)</b></li>
<li>MEMORY_MB: integer - target memory load in MB <b>(current: %s)</b></li>
<li>DURATION_SEC: integer (optional) - duration in seconds to run load, 0 means run until stopped <b>(current: %s)</b></li>
<li>CRASH: boolean (optional) - simulate application crash (panic) for CrashLoopBackOff testing <b>(current: %s)</b></li>
<li>CRASH_AFTER_TIME_MS: integer (optional) - time in milliseconds before auto-crash. If 0 or not set, crash immediately <b>(current: %s)</b></li>
<li>SHUTDOWN: boolean (optional) - simulate rolling update/scale down <b>(current: %s)</b></li>
<li>SHUTDOWN_AFTER_TIME_MS: integer (optional) - time in milliseconds before auto-shutdown. If 0 or not set, shutdown immediately <b>(current: %s)</b></li>
</ul>
<h3>Crash/Shutdown Behavior</h3>
<ul>
<li><strong>Immediate Crash:</strong> Set CRASH=true and CRASH_AFTER_TIME_MS=0 (or don't set CRASH_AFTER_TIME_MS)</li>
<li><strong>Delayed Crash:</strong> Set CRASH=true and CRASH_AFTER_TIME_MS=5000 (crashes after 5 seconds)</li>
<li><strong>Immediate Shutdown:</strong> Set SHUTDOWN=true and SHUTDOWN_AFTER_TIME_MS=0 (or don't set SHUTDOWN_AFTER_TIME_MS)</li>
<li><strong>Delayed Shutdown:</strong> Set SHUTDOWN=true and SHUTDOWN_AFTER_TIME_MS=10000 (shutdowns after 10 seconds)</li>
</ul>
<h3>Dynamic Load Endpoints</h3>
<ul>
<li><strong>/load:</strong> GET - Increment CPU load by %d%% (max %d%%)</li>
<li><strong>/load/reset:</strong> GET - Reset CPU load to 0%%</li>
</ul>
<h2>API Endpoints</h2>
<table border="1" cellpadding="5" cellspacing="0">
<tr><th>Endpoint</th><th>Method</th><th>Body (JSON)</th><th>Description</th></tr>
<tr><td>/start</td><td>POST</td><td></td><td>Start CPU and/or memory load</td></tr>
<tr><td>/stop</td><td>POST</td><td></td><td>Stop load</td></tr>
<tr><td>/status</td><td>GET</td><td></td><td>Get current load status</td></tr>
<tr><td>/setting</td><td>POST</td><td>{ "cpu_load_percent": int, "memory_mb": int, "duration_sec": int (optional) }</td><td>Update load settings</td></tr>
<tr><td>/health</td><td>GET</td><td></td><td>Health check</td></tr>
<tr><td>/database</td><td>POST</td><td>{ "engine": "mysql|postgres|sqlite|dynamodb", "connection_string": "string" }</td><td>Check DB connection</td></tr>
<tr><td>/error</td><td>GET</td><td></td><td>Simulate error for alert testing</td></tr>
<tr><td>/crash</td><td>GET</td><td></td><td>Simulate application crash (panic) for CrashLoopBackOff testing</td></tr>
<tr><td>/shutdown</td><td>GET</td><td></td><td>Gracefully shutdown the server (simulate rolling update/scale down)</td></tr>
<tr><td>/load</td><td>GET</td><td></td><td>Increment dynamic CPU load</td></tr>
<tr><td>/load/reset</td><td>GET</td><td></td><td>Reset dynamic CPU load to 0</td></tr>
</table>
</body>
</html>
`,
		status.Running,
		appConfig.Environment,
		currentFreqGHz,
		numCPU,
		cpuUsage,
		status.CPULoadPercent,
		float64(vmStat.Total)/1024/1024/1024,
		vmStat.UsedPercent,
		status.MemoryMB,
		dynamicLoad.CurrentCPULoad,
		dynamicLoad.MaxCPULoad,
		dynamicLoad.IncrementStep,
		envVar, portEnv, cpuLoadEnv, memMBEnv, durationEnv, crashEnv, crashTimeEnv, shutdownEnv, shutdownTimeEnv,
		dynamicLoad.IncrementStep,
		dynamicLoad.MaxCPULoad)

	return c.Type("html").SendString(usage)
}

func startHandler(c *fiber.Ctx) error {
	statusMutex.Lock()
	defer statusMutex.Unlock()

	if status.Running {
		logWarn("Load start requested but already running", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
		})
		return c.Status(fiber.StatusBadRequest).SendString("Load already running")
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancelFunc = cancel

	status.Running = true
	status.CPULoadPercent = settings.CPULoadPercent
	status.MemoryMB = settings.MemoryMB

	logInfo("Load started", map[string]interface{}{
		"remote_addr":      c.IP(),
		"user_agent":       c.Get("User-Agent"),
		"cpu_load_percent": settings.CPULoadPercent,
		"memory_mb":        settings.MemoryMB,
	})

	go runLoad(ctx, settings)

	return c.SendString("Load started")
}

func stopHandler(c *fiber.Ctx) error {
	statusMutex.Lock()
	defer statusMutex.Unlock()

	if !status.Running {
		logWarn("Load stop requested but not running", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
		})
		return c.Status(fiber.StatusBadRequest).SendString("Load not running")
	}

	cancelFunc()
	status.Running = false
	status.CPULoadPercent = 0
	status.MemoryMB = 0
	memoryBlocks = nil
	atomic.StoreInt32(&cpuLoadActive, 0)

	logInfo("Load stopped", map[string]interface{}{
		"remote_addr": c.IP(),
		"user_agent":  c.Get("User-Agent"),
	})

	return c.SendString("Load stopped")
}

func statusHandler(c *fiber.Ctx) error {
	statusMutex.RLock()
	defer statusMutex.RUnlock()

	updateSystemStatus()

	logDebug("Status requested", map[string]interface{}{
		"remote_addr": c.IP(),
		"user_agent":  c.Get("User-Agent"),
	})

	return c.JSON(status)
}

func settingHandler(c *fiber.Ctx) error {
	if c.Method() != fiber.MethodPost {
		logWarn("Invalid method for settings", map[string]interface{}{
			"method":      c.Method(),
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
		})
		return c.Status(fiber.StatusMethodNotAllowed).SendString("Method not allowed")
	}

	var newSettings LoadSettings
	if err := c.BodyParser(&newSettings); err != nil {
		logError("Failed to parse settings JSON", err, 400)
		return c.Status(fiber.StatusBadRequest).SendString("Invalid JSON body")
	}

	statusMutex.Lock()
	defer statusMutex.Unlock()

	// Cap CPU load percent at 80%
	if newSettings.CPULoadPercent > 80 {
		newSettings.CPULoadPercent = 80
		logWarn("CPU load percent capped at 80%", map[string]interface{}{
			"requested_percent": newSettings.CPULoadPercent,
			"capped_percent":    80,
		})
	}

	settings.CPULoadPercent = newSettings.CPULoadPercent
	settings.MemoryMB = newSettings.MemoryMB
	settings.DurationSec = newSettings.DurationSec

	status.CPULoadPercent = settings.CPULoadPercent
	status.MemoryMB = settings.MemoryMB

	logInfo("Settings updated", map[string]interface{}{
		"remote_addr":      c.IP(),
		"user_agent":       c.Get("User-Agent"),
		"cpu_load_percent": settings.CPULoadPercent,
		"memory_mb":        settings.MemoryMB,
		"duration_sec":     settings.DurationSec,
	})

	return c.SendString("Settings updated")
}

func healthHandler(c *fiber.Ctx) error {
	logDebug("Health check requested", map[string]interface{}{
		"remote_addr": c.IP(),
		"user_agent":  c.Get("User-Agent"),
	})
	return c.SendString("OK")
}

func databaseHandler(c *fiber.Ctx) error {
	var dbRequest DatabaseRequest
	if err := c.BodyParser(&dbRequest); err != nil {
		logError("Failed to parse database request JSON", err, 400)
		return c.Status(fiber.StatusBadRequest).JSON(DatabaseResponse{
			Success: false,
			Message: "Invalid JSON body",
			Engine:  "",
		})
	}

	// Validate required fields
	if dbRequest.Engine == "" {
		logWarn("Database request missing engine", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
		})
		return c.Status(fiber.StatusBadRequest).JSON(DatabaseResponse{
			Success: false,
			Message: "Engine field is required",
			Engine:  "",
		})
	}

	if dbRequest.ConnectionString == "" {
		logWarn("Database request missing connection string", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
			"engine":      dbRequest.Engine,
		})
		return c.Status(fiber.StatusBadRequest).JSON(DatabaseResponse{
			Success: false,
			Message: "Connection string field is required",
			Engine:  dbRequest.Engine,
		})
	}

	// Test the database connection
	response := testDatabaseConnection(dbRequest.Engine, dbRequest.ConnectionString)

	// Log the database test result
	if response.Success {
		logInfo("Database connection test successful", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
			"engine":      dbRequest.Engine,
		})
	} else {
		logError("Database connection test failed", fmt.Errorf(response.Message), 500)
	}

	// Return appropriate HTTP status code
	if response.Success {
		return c.JSON(response)
	} else {
		return c.Status(fiber.StatusInternalServerError).JSON(response)
	}
}

func errorHandler(c *fiber.Ctx) error {
	errMsg := "Simulated database connection error for alert testing"
	logError("Simulated error triggered", fmt.Errorf(errMsg), 500)
	return c.Status(fiber.StatusInternalServerError).SendString(errMsg)
}

func crashHandler(c *fiber.Ctx) error {
	logError("Manual crash triggered", fmt.Errorf("Simulated application crash for testing CrashLoopBackOff"), 1)
	go func() {
		time.Sleep(500 * time.Millisecond)
		panic("Simulated application crash for testing CrashLoopBackOff")
	}()
	return c.SendString("Server will crash in 500ms... (Exit Code: 1)")
}

func makeShutdownHandler(app *fiber.App) fiber.Handler {
	return func(c *fiber.Ctx) error {
		logInfo("Manual shutdown initiated", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
		})
		go func() {
			time.Sleep(500 * time.Millisecond)
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			logInfo("Server shutdown completed successfully", map[string]interface{}{
				"message": "Please restart the server to continue using the service",
			})
			_ = app.ShutdownWithContext(ctx)
		}()
		return c.SendString("Server is shutting down gracefully, please restart the server to continue using the service... (Exit Code: 0)")
	}
}

// dynamicLoadHandler increments the dynamic CPU load and starts load generation
func dynamicLoadHandler(c *fiber.Ctx) error {
	statusMutex.Lock()
	defer statusMutex.Unlock()

	// Check if we can increment the load
	if dynamicLoad.CurrentCPULoad >= dynamicLoad.MaxCPULoad {
		logWarn("Dynamic load increment rejected - maximum reached", map[string]interface{}{
			"remote_addr":    c.IP(),
			"user_agent":     c.Get("User-Agent"),
			"current_load":   dynamicLoad.CurrentCPULoad,
			"max_load":       dynamicLoad.MaxCPULoad,
			"increment_step": dynamicLoad.IncrementStep,
		})
		return c.JSON(LoadResponse{
			Success:       false,
			Message:       fmt.Sprintf("Maximum CPU load (%d%%) already reached", dynamicLoad.MaxCPULoad),
			CurrentLoad:   dynamicLoad.CurrentCPULoad,
			MaxLoad:       dynamicLoad.MaxCPULoad,
			IncrementStep: dynamicLoad.IncrementStep,
		})
	}

	// Increment the load
	oldLoad := dynamicLoad.CurrentCPULoad
	dynamicLoad.CurrentCPULoad += dynamicLoad.IncrementStep

	// Ensure we don't exceed the maximum
	if dynamicLoad.CurrentCPULoad > dynamicLoad.MaxCPULoad {
		dynamicLoad.CurrentCPULoad = dynamicLoad.MaxCPULoad
	}

	// Stop any existing load first
	if status.Running && cancelFunc != nil {
		logInfo("Stopping existing load for dynamic load update", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
		})
		cancelFunc()
		status.Running = false
		memoryBlocks = nil
		atomic.StoreInt32(&cpuLoadActive, 0)
	}

	// Start new load with the incremented CPU percentage
	ctx, cancel := context.WithCancel(context.Background())
	cancelFunc = cancel

	status.Running = true
	status.CPULoadPercent = dynamicLoad.CurrentCPULoad
	status.MemoryMB = 0 // No memory load for dynamic load

	logInfo("Dynamic load incremented and started", map[string]interface{}{
		"remote_addr":    c.IP(),
		"user_agent":     c.Get("User-Agent"),
		"old_load":       oldLoad,
		"new_load":       dynamicLoad.CurrentCPULoad,
		"increment_step": dynamicLoad.IncrementStep,
		"max_load":       dynamicLoad.MaxCPULoad,
		"load_running":   status.Running,
	})

	// Start the load generation in background
	go runLoad(ctx, LoadSettings{
		CPULoadPercent:      dynamicLoad.CurrentCPULoad,
		MemoryMB:            0, // No memory load
		DurationSec:         0, // Run until stopped
		CrashAfterTimeMs:    settings.CrashAfterTimeMs,
		ShutdownAfterTimeMs: settings.ShutdownAfterTimeMs,
	})

	return c.JSON(LoadResponse{
		Success:       true,
		Message:       fmt.Sprintf("CPU load incremented from %d%% to %d%% and load generation started", oldLoad, dynamicLoad.CurrentCPULoad),
		CurrentLoad:   dynamicLoad.CurrentCPULoad,
		MaxLoad:       dynamicLoad.MaxCPULoad,
		IncrementStep: dynamicLoad.IncrementStep,
	})
}

// dynamicLoadResetHandler resets the dynamic CPU load to initial settings and stops load generation
func dynamicLoadResetHandler(c *fiber.Ctx) error {
	statusMutex.Lock()
	defer statusMutex.Unlock()

	oldLoad := dynamicLoad.CurrentCPULoad
	dynamicLoad.CurrentCPULoad = 0

	// Stop any running load
	if status.Running && cancelFunc != nil {
		logInfo("Stopping load generation for dynamic load reset", map[string]interface{}{
			"remote_addr": c.IP(),
			"user_agent":  c.Get("User-Agent"),
		})
		cancelFunc()
		status.Running = false
		status.CPULoadPercent = 0
		status.MemoryMB = 0
		memoryBlocks = nil
		atomic.StoreInt32(&cpuLoadActive, 0)
	}

	logInfo("Dynamic load reset and load generation stopped", map[string]interface{}{
		"remote_addr":  c.IP(),
		"user_agent":   c.Get("User-Agent"),
		"old_load":     oldLoad,
		"new_load":     dynamicLoad.CurrentCPULoad,
		"load_running": status.Running,
	})

	return c.JSON(LoadResponse{
		Success:       true,
		Message:       fmt.Sprintf("CPU load reset from %d%% to 0%% and load generation stopped", oldLoad),
		CurrentLoad:   dynamicLoad.CurrentCPULoad,
		MaxLoad:       dynamicLoad.MaxCPULoad,
		IncrementStep: dynamicLoad.IncrementStep,
	})
}
