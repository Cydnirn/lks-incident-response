package main

import (
	"time"
)

// LoadSettings represents the configuration for load generation
type LoadSettings struct {
	CPULoadPercent      int `json:"cpu_load_percent"`       // Target CPU load percentage (max 80)
	MemoryMB            int `json:"memory_mb"`              // Target memory load in MB
	DurationSec         int `json:"duration_sec"`           // Duration in seconds, 0 means run until stopped
	CrashAfterTimeMs    int `json:"crash_after_time_ms"`    // Time in milliseconds before crash (if crash is enabled)
	ShutdownAfterTimeMs int `json:"shutdown_after_time_ms"` // Time in milliseconds before shutdown (if shutdown is enabled)
}

// LoadStatus represents the current status of load generation
type LoadStatus struct {
	Running             bool   `json:"running"`                // Whether load is currently running
	CPULoadPercent      int    `json:"cpu_load_percent"`       // Current CPU load percentage setting
	MemoryMB            int    `json:"memory_mb"`              // Current memory load setting in MB
	DatabaseStatus      string `json:"database_status"`        // Status of last database connection test
	CrashAfterTimeMs    int    `json:"crash_after_time_ms"`    // Time in milliseconds before crash
	ShutdownAfterTimeMs int    `json:"shutdown_after_time_ms"` // Time in milliseconds before shutdown
}

// DatabaseRequest represents a database connection test request
type DatabaseRequest struct {
	Engine           string `json:"engine"`            // Database engine: mysql, postgres, sqlite, dynamodb
	ConnectionString string `json:"connection_string"` // Connection string for the database
}

// DatabaseResponse represents the response from a database connection test
type DatabaseResponse struct {
	Success bool   `json:"success"` // Whether the connection was successful
	Message string `json:"message"` // Success or error message
	Engine  string `json:"engine"`  // Database engine that was tested
}

// LogEntry represents a structured JSON log entry
type LogEntry struct {
	Timestamp   time.Time              `json:"timestamp"`
	Level       string                 `json:"level"`
	Message     string                 `json:"message"`
	Service     string                 `json:"service"`
	Environment string                 `json:"environment"`
	StatusCode  int                    `json:"status_code,omitempty"`
	RequestID   string                 `json:"request_id,omitempty"`
	UserAgent   string                 `json:"user_agent,omitempty"`
	RemoteAddr  string                 `json:"remote_addr,omitempty"`
	Method      string                 `json:"method,omitempty"`
	Path        string                 `json:"path,omitempty"`
	Duration    string                 `json:"duration,omitempty"`
	Error       string                 `json:"error,omitempty"`
	Stack       string                 `json:"stack,omitempty"`
	Extra       map[string]interface{} `json:"extra,omitempty"`
}

// CrashConfig represents crash configuration
type CrashConfig struct {
	Enabled     bool `json:"enabled"`
	AfterTimeMs int  `json:"after_time_ms"`
}

// ShutdownConfig represents shutdown configuration
type ShutdownConfig struct {
	Enabled     bool `json:"enabled"`
	AfterTimeMs int  `json:"after_time_ms"`
}

// AppConfig represents application configuration
type AppConfig struct {
	Environment string         `json:"environment"`
	Port        string         `json:"port"`
	Crash       CrashConfig    `json:"crash"`
	Shutdown    ShutdownConfig `json:"shutdown"`
}

// DynamicLoadConfig represents dynamic load configuration
type DynamicLoadConfig struct {
	CurrentCPULoad int `json:"current_cpu_load"` // Current dynamic CPU load percentage
	MaxCPULoad     int `json:"max_cpu_load"`     // Maximum allowed CPU load percentage
	IncrementStep  int `json:"increment_step"`   // CPU load increment per request
}

// LoadResponse represents the response from load operations
type LoadResponse struct {
	Success       bool   `json:"success"`
	Message       string `json:"message"`
	CurrentLoad   int    `json:"current_load"`
	MaxLoad       int    `json:"max_load"`
	IncrementStep int    `json:"increment_step"`
}
