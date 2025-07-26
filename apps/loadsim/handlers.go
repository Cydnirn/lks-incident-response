package main

import (
	"context"
	"fmt"
	"log"
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
<li>CPU Frequency: %.2f GHz</li>
<li>CPU Cores: %d</li>
<li>CPU Usage: %.2f%%</li>
<li>CPU Load Percent Setting: %d%%</li>
<li>Total Memory: %.2f GB</li>
<li>Memory Usage: %.2f%%</li>
<li>Memory Load Setting: %d MB</li>
</ul>
<h2>Environment Variables</h2>
<ul>
<li>CPU_LOAD_PERCENT: integer (max 80) - target CPU load percentage <b>(current: %s)</b></li>
<li>MEMORY_MB: integer - target memory load in MB <b>(current: %s)</b></li>
<li>DURATION_SEC: integer (optional) - duration in seconds to run load, 0 means run until stopped <b>(current: %s)</b></li>
<li>PORT: integer (optional) - server port, default 8080 <b>(current: %s)</b></li>
<li>CRASH: boolean (optional) - simulate application crash (panic) for CrashLoopBackOff testing <b>(current: %s)</b></li>
<li>CRASH_AFTER_TIME_MS: integer (optional) - time in milliseconds before auto-crash <b>(current: %s)</b></li>
<li>SHUTDOWN: boolean (optional) - simulate rolling update/scale down <b>(current: %s)</b></li>
<li>SHUTDOWN_AFTER_TIME_MS: integer (optional) - time in milliseconds before auto-shutdown <b>(current: %s)</b></li>
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
</table>
</body>
</html>
`,
		status.Running,
		currentFreqGHz,
		numCPU,
		cpuUsage,
		status.CPULoadPercent,
		float64(vmStat.Total)/1024/1024/1024,
		vmStat.UsedPercent,
		status.MemoryMB,
		cpuLoadEnv, memMBEnv, durationEnv, portEnv, crashEnv, crashTimeEnv, shutdownEnv, shutdownTimeEnv)

	return c.Type("html").SendString(usage)
}

func startHandler(c *fiber.Ctx) error {
	statusMutex.Lock()
	defer statusMutex.Unlock()

	if status.Running {
		return c.Status(fiber.StatusBadRequest).SendString("Load already running")
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancelFunc = cancel

	status.Running = true
	status.CPULoadPercent = settings.CPULoadPercent
	status.MemoryMB = settings.MemoryMB

	go runLoad(ctx, settings)

	return c.SendString("Load started")
}

func stopHandler(c *fiber.Ctx) error {
	statusMutex.Lock()
	defer statusMutex.Unlock()

	if !status.Running {
		return c.Status(fiber.StatusBadRequest).SendString("Load not running")
	}

	cancelFunc()
	status.Running = false
	status.CPULoadPercent = 0
	status.MemoryMB = 0
	memoryBlocks = nil
	atomic.StoreInt32(&cpuLoadActive, 0)

	return c.SendString("Load stopped")
}

func statusHandler(c *fiber.Ctx) error {
	statusMutex.RLock()
	defer statusMutex.RUnlock()

	updateSystemStatus()

	return c.JSON(status)
}

func settingHandler(c *fiber.Ctx) error {
	if c.Method() != fiber.MethodPost {
		return c.Status(fiber.StatusMethodNotAllowed).SendString("Method not allowed")
	}

	var newSettings LoadSettings
	if err := c.BodyParser(&newSettings); err != nil {
		return c.Status(fiber.StatusBadRequest).SendString("Invalid JSON body")
	}

	statusMutex.Lock()
	defer statusMutex.Unlock()

	// Cap CPU load percent at 80%
	if newSettings.CPULoadPercent > 80 {
		newSettings.CPULoadPercent = 80
	}

	settings.CPULoadPercent = newSettings.CPULoadPercent
	settings.MemoryMB = newSettings.MemoryMB
	settings.DurationSec = newSettings.DurationSec

	status.CPULoadPercent = settings.CPULoadPercent
	status.MemoryMB = settings.MemoryMB

	return c.SendString("Settings updated")
}

func healthHandler(c *fiber.Ctx) error {
	return c.SendString("OK")
}

func databaseHandler(c *fiber.Ctx) error {
	var dbRequest DatabaseRequest
	if err := c.BodyParser(&dbRequest); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(DatabaseResponse{
			Success: false,
			Message: "Invalid JSON body",
			Engine:  "",
		})
	}

	// Validate required fields
	if dbRequest.Engine == "" {
		return c.Status(fiber.StatusBadRequest).JSON(DatabaseResponse{
			Success: false,
			Message: "Engine field is required",
			Engine:  "",
		})
	}

	if dbRequest.ConnectionString == "" {
		return c.Status(fiber.StatusBadRequest).JSON(DatabaseResponse{
			Success: false,
			Message: "Connection string field is required",
			Engine:  dbRequest.Engine,
		})
	}

	// Test the database connection
	response := testDatabaseConnection(dbRequest.Engine, dbRequest.ConnectionString)

	// Return appropriate HTTP status code
	if response.Success {
		return c.JSON(response)
	} else {
		return c.Status(fiber.StatusInternalServerError).JSON(response)
	}
}

func errorHandler(c *fiber.Ctx) error {
	errMsg := "Simulated database connection error for alert testing"
	log.Printf("ERROR: %s (HTTP 500)", errMsg)
	return c.Status(fiber.StatusInternalServerError).SendString(errMsg)
}

func crashHandler(c *fiber.Ctx) error {
	log.Printf("CRASH: Simulating application crash for CrashLoopBackOff testing (Exit Code: 1)")
	go func() {
		time.Sleep(500 * time.Millisecond)
		panic("Simulated application crash for testing CrashLoopBackOff")
	}()
	return c.SendString("Server will crash in 500ms... (Exit Code: 1)")
}

func makeShutdownHandler(app *fiber.App) fiber.Handler {
	return func(c *fiber.Ctx) error {
		log.Printf("SHUTDOWN: Graceful shutdown initiated (Exit Code: 0)")
		go func() {
			time.Sleep(500 * time.Millisecond)
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			log.Printf("SHUTDOWN: Server shutdown completed successfully. Please restart the server to continue using the service... (Exit Code: 0)")
			_ = app.ShutdownWithContext(ctx)
		}()
		return c.SendString("Server is shutting down gracefully, please restart the server to continue using the service... (Exit Code: 0)")
	}
}
