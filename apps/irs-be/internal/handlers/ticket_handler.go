package handlers

import (
	"net/http"
	"strings"

	"irs-be/internal/models"
	"irs-be/internal/services"

	"github.com/gofiber/fiber/v2"
)

type TicketHandler struct {
	ticketService *services.TicketService
}

// NewTicketHandler creates a new ticket handler
func NewTicketHandler(ticketService *services.TicketService) *TicketHandler {
	return &TicketHandler{
		ticketService: ticketService,
	}
}

// GetAllTickets handles GET /api/tickets
func (h *TicketHandler) GetAllTickets(c *fiber.Ctx) error {
	tickets, err := h.ticketService.GetAllTickets()
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(models.APIResponse{
			Success: false,
			Error:   "Failed to fetch tickets: " + err.Error(),
		})
	}

	return c.JSON(models.APIResponse{
		Success: true,
		Data:    tickets,
	})
}

// GetTicketByID handles GET /api/tickets/:id
func (h *TicketHandler) GetTicketByID(c *fiber.Ctx) error {
	id := c.Params("id")
	if id == "" {
		return c.Status(http.StatusBadRequest).JSON(models.APIResponse{
			Success: false,
			Error:   "Ticket ID is required",
		})
	}

	ticket, err := h.ticketService.GetTicketByID(id)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(models.APIResponse{
			Success: false,
			Error:   "Failed to fetch ticket: " + err.Error(),
		})
	}

	if ticket == nil {
		return c.Status(http.StatusNotFound).JSON(models.APIResponse{
			Success: false,
			Error:   "Ticket not found",
		})
	}

	return c.JSON(models.APIResponse{
		Success: true,
		Data:    ticket,
	})
}

// GetTicketsByStatus handles GET /api/tickets/status/:status
func (h *TicketHandler) GetTicketsByStatus(c *fiber.Ctx) error {
	status := c.Params("status")
	if status == "" {
		return c.Status(http.StatusBadRequest).JSON(models.APIResponse{
			Success: false,
			Error:   "Status is required",
		})
	}

	tickets, err := h.ticketService.GetTicketsByStatus(status)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(models.APIResponse{
			Success: false,
			Error:   "Failed to fetch tickets by status: " + err.Error(),
		})
	}

	return c.JSON(models.APIResponse{
		Success: true,
		Data:    tickets,
	})
}

// GetTicketsBySeverity handles GET /api/tickets/severity/:severity
func (h *TicketHandler) GetTicketsBySeverity(c *fiber.Ctx) error {
	severity := c.Params("severity")
	if severity == "" {
		return c.Status(http.StatusBadRequest).JSON(models.APIResponse{
			Success: false,
			Error:   "Severity is required",
		})
	}

	tickets, err := h.ticketService.GetTicketsBySeverity(severity)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(models.APIResponse{
			Success: false,
			Error:   "Failed to fetch tickets by severity: " + err.Error(),
		})
	}

	return c.JSON(models.APIResponse{
		Success: true,
		Data:    tickets,
	})
}

// GetTicketsByIncidentType handles GET /api/tickets/incident-type/:incidentType
func (h *TicketHandler) GetTicketsByIncidentType(c *fiber.Ctx) error {
	incidentType := c.Params("incidentType")
	if incidentType == "" {
		return c.Status(http.StatusBadRequest).JSON(models.APIResponse{
			Success: false,
			Error:   "Incident type is required",
		})
	}

	tickets, err := h.ticketService.GetTicketsByIncidentType(incidentType)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(models.APIResponse{
			Success: false,
			Error:   "Failed to fetch tickets by incident type: " + err.Error(),
		})
	}

	return c.JSON(models.APIResponse{
		Success: true,
		Data:    tickets,
	})
}

// SearchTickets handles GET /api/tickets/search
func (h *TicketHandler) SearchTickets(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return c.Status(http.StatusBadRequest).JSON(models.APIResponse{
			Success: false,
			Error:   "Search query is required",
		})
	}

	tickets, err := h.ticketService.SearchTickets(query)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(models.APIResponse{
			Success: false,
			Error:   "Failed to search tickets: " + err.Error(),
		})
	}

	return c.JSON(models.APIResponse{
		Success: true,
		Data:    tickets,
	})
}

// GetTicketsWithFilters handles GET /api/tickets/filter
func (h *TicketHandler) GetTicketsWithFilters(c *fiber.Ctx) error {
	// Get all tickets first
	tickets, err := h.ticketService.GetAllTickets()
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(models.APIResponse{
			Success: false,
			Error:   "Failed to fetch tickets: " + err.Error(),
		})
	}

	// Apply filters
	filteredTickets := h.applyFilters(tickets, c)

	return c.JSON(models.APIResponse{
		Success: true,
		Data:    filteredTickets,
	})
}

// applyFilters applies query parameters as filters
func (h *TicketHandler) applyFilters(tickets []models.IncidentTicket, c *fiber.Ctx) []models.IncidentTicket {
	filtered := tickets

	// Filter by severity
	if severity := c.Query("severity"); severity != "" {
		var filteredBySeverity []models.IncidentTicket
		for _, ticket := range filtered {
			if ticket.Severity == severity {
				filteredBySeverity = append(filteredBySeverity, ticket)
			}
		}
		filtered = filteredBySeverity
	}

	// Filter by category
	if category := c.Query("category"); category != "" {
		var filteredByCategory []models.IncidentTicket
		for _, ticket := range filtered {
			if ticket.Category == category {
				filteredByCategory = append(filteredByCategory, ticket)
			}
		}
		filtered = filteredByCategory
	}

	// Filter by environment
	if environment := c.Query("environment"); environment != "" {
		var filteredByEnvironment []models.IncidentTicket
		for _, ticket := range filtered {
			if ticket.Environment == environment {
				filteredByEnvironment = append(filteredByEnvironment, ticket)
			}
		}
		filtered = filteredByEnvironment
	}

	// Filter by status
	if status := c.Query("status"); status != "" {
		var filteredByStatus []models.IncidentTicket
		for _, ticket := range filtered {
			if ticket.Status == status {
				filteredByStatus = append(filteredByStatus, ticket)
			}
		}
		filtered = filteredByStatus
	}

	// Filter by action status
	if actionStatus := c.Query("actionStatus"); actionStatus != "" {
		var filteredByActionStatus []models.IncidentTicket
		for _, ticket := range filtered {
			if ticket.ActionStatus == actionStatus {
				filteredByActionStatus = append(filteredByActionStatus, ticket)
			}
		}
		filtered = filteredByActionStatus
	}

	// Filter by incident type
	if incidentType := c.Query("incidentType"); incidentType != "" {
		var filteredByIncidentType []models.IncidentTicket
		for _, ticket := range filtered {
			if ticket.IncidentType == incidentType {
				filteredByIncidentType = append(filteredByIncidentType, ticket)
			}
		}
		filtered = filteredByIncidentType
	}

	// Search filter
	if search := c.Query("search"); search != "" {
		var filteredBySearch []models.IncidentTicket
		searchLower := strings.ToLower(search)
		for _, ticket := range filtered {
			if strings.Contains(strings.ToLower(ticket.Title), searchLower) ||
				strings.Contains(strings.ToLower(ticket.Description), searchLower) ||
				strings.Contains(strings.ToLower(ticket.Report), searchLower) {
				filteredBySearch = append(filteredBySearch, ticket)
			}
		}
		filtered = filteredBySearch
	}

	return filtered
}

// HealthCheck handles GET /health
func (h *TicketHandler) HealthCheck(c *fiber.Ctx) error {
	err := h.ticketService.HealthCheck()
	if err != nil {
		return c.Status(http.StatusServiceUnavailable).JSON(models.APIResponse{
			Success: false,
			Error:   "Service unhealthy: " + err.Error(),
		})
	}

	return c.JSON(models.APIResponse{
		Success: true,
		Message: "Service is healthy",
	})
}
