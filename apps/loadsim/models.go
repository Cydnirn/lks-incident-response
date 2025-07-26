package main

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
