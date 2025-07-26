package dto

type CreateTicketRequest struct {
	Title            string   `json:"title" validate:"required"`
	Description      string   `json:"description" validate:"required"`
	Severity         string   `json:"severity" validate:"required"`
	Category         string   `json:"category" validate:"required"`
	IncidentType     string   `json:"insident_type" validate:"required"`
	Environment      string   `json:"environment" validate:"required"`
	ActionStatus     string   `json:"actionStatus"`
	Status           string   `json:"status"`
	Reporter         string   `json:"reporter"`
	Suggestions      []string `json:"suggestions,omitempty"`
	AffectedServices []string `json:"affectedServices,omitempty"`
	Tags             []string `json:"tags,omitempty"`
}

type TicketResponse struct {
	ID               string   `json:"id"`
	Title            string   `json:"title"`
	Description      string   `json:"description"`
	Severity         string   `json:"severity"`
	Category         string   `json:"category"`
	IncidentType     string   `json:"insident_type"`
	Environment      string   `json:"environment"`
	ActionStatus     string   `json:"actionStatus"`
	Status           string   `json:"status"`
	Reporter         string   `json:"reporter"`
	CreatedAt        string   `json:"createdAt"`
	ResolutionTime   *string  `json:"resolutionTime,omitempty"`
	EmailSent        bool     `json:"emailSent"`
	EmailSentAt      *string  `json:"emailSentAt,omitempty"`
	ActionTaken      *string  `json:"actionTaken,omitempty"`
	Suggestions      []string `json:"suggestions,omitempty"`
	AffectedServices []string `json:"affectedServices,omitempty"`
	Tags             []string `json:"tags,omitempty"`
}
