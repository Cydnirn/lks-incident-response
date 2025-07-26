package main

// LoadSettings represents the configuration for load generation
type LoadSettings struct {
	CPULoadPercent int     `json:"cpu_load_percent"` // Target CPU load percentage (max 80)
	MemoryGB       float64 `json:"memory_gb"`        // Target memory load in GB
	DurationSec    int     `json:"duration_sec"`     // Duration in seconds, 0 means run until stopped
}

// LoadStatus represents the current status of load generation
type LoadStatus struct {
	Running         bool    `json:"running"`           // Whether load is currently running
	CPULoadPercent  int     `json:"cpu_load_percent"`  // Current CPU load percentage setting
	MemoryGB        float64 `json:"memory_gb"`         // Current memory load setting in GB
	DatabaseStatus  string  `json:"database_status"`   // Status of last database connection test
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
