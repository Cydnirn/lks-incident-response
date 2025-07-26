package main

import (
	"irs-be/internal/config"
	"irs-be/internal/handlers"
	"irs-be/internal/services"
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

func main() {
	cfg := config.LoadConfig()

	ticketService, err := services.NewTicketService(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize TicketService: %v", err)
	}
	ticketHandler := handlers.NewTicketHandler(ticketService)

	app := fiber.New(fiber.Config{
		AppName: "IRS Backend API",
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).JSON(fiber.Map{
				"success": false,
				"error":   err.Error(),
			})
		},
	})

	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: cfg.Server.CORSOrigin,
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",
	}))

	app.Get("/health", ticketHandler.HealthCheck)
	api := app.Group("/api")
	tickets := api.Group("/tickets")
	tickets.Get("/", ticketHandler.GetAllTickets)
	tickets.Get("/:id", ticketHandler.GetTicketByID)
	tickets.Get("/status/:status", ticketHandler.GetTicketsByStatus)
	tickets.Get("/severity/:severity", ticketHandler.GetTicketsBySeverity)
	tickets.Get("/incident-type/:incidentType", ticketHandler.GetTicketsByIncidentType)
	tickets.Get("/search", ticketHandler.SearchTickets)
	tickets.Get("/filter", ticketHandler.GetTicketsWithFilters)

	app.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"success": true,
			"message": "IRS Backend API is running",
			"version": "1.0.0",
			"endpoints": fiber.Map{
				"health":                   "/health",
				"tickets":                  "/api/tickets",
				"ticket_by_id":             "/api/tickets/:id",
				"tickets_by_status":        "/api/tickets/status/:status",
				"tickets_by_severity":      "/api/tickets/severity/:severity",
				"tickets_by_incident_type": "/api/tickets/incident-type/:incidentType",
				"search_tickets":           "/api/tickets/search?q=query",
				"filter_tickets":           "/api/tickets/filter?severity=critical&category=kubernetes",
			},
		})
	})

	port := cfg.Server.Port
	if port == "" {
		port = "8080"
	}
	host := cfg.Server.Host
	if host == "" {
		host = "0.0.0.0"
	}

	log.Printf("Starting server on %s:%s", host, port)
	if err := app.Listen(host + ":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
