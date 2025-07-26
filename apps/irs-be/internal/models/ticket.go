package models

// IncidentTicket represents an incident ticket in the system
type IncidentTicket struct {
	ID               string   `json:"id" dynamodbav:"id"`
	Title            string   `json:"title" dynamodbav:"title"`
	Description      string   `json:"description" dynamodbav:"description"`
	Report           string   `json:"report" dynamodbav:"report"`
	Suggestions      []string `json:"suggestions,omitempty" dynamodbav:"suggestions,omitempty"`
	Severity         string   `json:"severity" dynamodbav:"severity"`
	Category         string   `json:"category" dynamodbav:"category"`
	IncidentType     string   `json:"insident_type" dynamodbav:"insident_type"`
	Environment      string   `json:"environment" dynamodbav:"environment"`
	ActionStatus     string   `json:"actionStatus" dynamodbav:"actionStatus"`
	Status           string   `json:"status" dynamodbav:"status"`
	Reporter         string   `json:"reporter" dynamodbav:"reporter"`
	CreatedAt        string   `json:"createdAt" dynamodbav:"createdAt"`
	ResolutionTime   *string  `json:"resolutionTime,omitempty" dynamodbav:"resolutionTime,omitempty"`
	EmailSent        bool     `json:"emailSent" dynamodbav:"emailSent"`
	EmailSentAt      *string  `json:"emailSentAt,omitempty" dynamodbav:"emailSentAt,omitempty"`
	ActionTaken      *string  `json:"actionTaken,omitempty" dynamodbav:"actionTaken,omitempty"`
	AffectedServices []string `json:"affectedServices,omitempty" dynamodbav:"affectedServices,omitempty"`
	Tags             []string `json:"tags,omitempty" dynamodbav:"tags,omitempty"`
}

// TicketFilters represents filters for querying tickets
type TicketFilters struct {
	ActionStatus string `json:"actionStatus,omitempty"`
	Severity     string `json:"severity,omitempty"`
	Category     string `json:"category,omitempty"`
	Environment  string `json:"environment,omitempty"`
	Search       string `json:"search,omitempty"`
	Status       string `json:"status,omitempty"`
	IncidentType string `json:"incidentType,omitempty"`
}

// APIResponse represents a standard API response
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// PaginationResponse represents a paginated response
type PaginationResponse struct {
	Data       interface{} `json:"data"`
	Total      int         `json:"total"`
	Page       int         `json:"page"`
	Limit      int         `json:"limit"`
	TotalPages int         `json:"totalPages"`
}
