package services

import (
	"context"
	"fmt"
	"irs-be/internal/config"
	"strings"

	"irs-be/internal/models"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type TicketService struct {
	client    *dynamodb.Client
	tableName string
}

// NewTicketService creates a new Ticket service instance
func NewTicketService(cfg config.Config) (*TicketService, error) {
	region := cfg.AWS.Region
	if region == "" {
		region = "us-east-1"
	}

	accessKeyID := cfg.AWS.AccessKeyID
	secretAccessKey := cfg.AWS.SecretAccessKey
	sessionToken := cfg.AWS.SessionToken
	tableName := cfg.DynamoDB.TableName
	if tableName == "" {
		tableName = "insident"
	}

	var awsCfg aws.Config
	var err error

	// Always use provided credentials if they exist
	if accessKeyID != "" && secretAccessKey != "" {
		fmt.Printf("Using provided AWS credentials for region: %s, table: %s\n", region, tableName)
		awsCfg, err = awsconfig.LoadDefaultConfig(context.TODO(),
			awsconfig.WithRegion(region),
			awsconfig.WithCredentialsProvider(credentials.StaticCredentialsProvider{
				Value: aws.Credentials{
					AccessKeyID:     accessKeyID,
					SecretAccessKey: secretAccessKey,
					SessionToken:    sessionToken,
				},
			}),
		)
	} else {
		// Fallback to default credentials (IAM role, shared credentials file, etc.)
		fmt.Printf("No explicit credentials provided, using default AWS credential chain for region: %s, table: %s\n", region, tableName)
		awsCfg, err = awsconfig.LoadDefaultConfig(context.TODO(),
			awsconfig.WithRegion(region),
		)
	}

	if err != nil {
		return nil, fmt.Errorf("unable to load AWS SDK config: %v", err)
	}

	client := dynamodb.NewFromConfig(awsCfg)

	// Test the credentials by trying to list tables
	// Commented out due to permission issues - uncomment when credentials are properly configured
	/*
		_, err = client.ListTables(context.TODO(), &dynamodb.ListTablesInput{Limit: aws.Int32(1)})
		if err != nil {
			return nil, fmt.Errorf("failed to test AWS credentials: %v", err)
		}
	*/

	fmt.Printf("Successfully initialized DynamoDB client for table: %s\n", tableName)

	return &TicketService{
		client:    client,
		tableName: tableName,
	}, nil
}

// GetAllTickets retrieves all tickets from DynamoDB
func (s *TicketService) GetAllTickets() ([]models.IncidentTicket, error) {
	input := &dynamodb.ScanInput{
		TableName: aws.String(s.tableName),
	}

	result, err := s.client.Scan(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to scan table: %v", err)
	}

	var tickets []models.IncidentTicket
	for _, item := range result.Items {
		ticket := s.unmarshalTicket(item)
		tickets = append(tickets, ticket)
	}

	return tickets, nil
}

// GetTicketByID retrieves a specific ticket by ID
func (s *TicketService) GetTicketByID(id string) (*models.IncidentTicket, error) {
	input := &dynamodb.GetItemInput{
		TableName: aws.String(s.tableName),
		Key: map[string]types.AttributeValue{
			"id": &types.AttributeValueMemberS{Value: id},
		},
	}

	result, err := s.client.GetItem(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to get item: %v", err)
	}

	if result.Item == nil {
		return nil, nil // Item not found
	}

	ticket := s.unmarshalTicket(result.Item)
	return &ticket, nil
}

// GetTicketsByStatus retrieves tickets by status using GSI
func (s *TicketService) GetTicketsByStatus(status string) ([]models.IncidentTicket, error) {
	input := &dynamodb.QueryInput{
		TableName:              aws.String(s.tableName),
		IndexName:              aws.String("StatusIndex"),
		KeyConditionExpression: aws.String("#status = :status"),
		ExpressionAttributeNames: map[string]string{
			"#status": "status",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":status": &types.AttributeValueMemberS{Value: status},
		},
	}

	result, err := s.client.Query(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to query by status: %v", err)
	}

	var tickets []models.IncidentTicket
	for _, item := range result.Items {
		ticket := s.unmarshalTicket(item)
		tickets = append(tickets, ticket)
	}

	return tickets, nil
}

// GetTicketsBySeverity retrieves tickets by severity using GSI
func (s *TicketService) GetTicketsBySeverity(severity string) ([]models.IncidentTicket, error) {
	input := &dynamodb.QueryInput{
		TableName:              aws.String(s.tableName),
		IndexName:              aws.String("SeverityIndex"),
		KeyConditionExpression: aws.String("#severity = :severity"),
		ExpressionAttributeNames: map[string]string{
			"#severity": "severity",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":severity": &types.AttributeValueMemberS{Value: severity},
		},
	}

	result, err := s.client.Query(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to query by severity: %v", err)
	}

	var tickets []models.IncidentTicket
	for _, item := range result.Items {
		ticket := s.unmarshalTicket(item)
		tickets = append(tickets, ticket)
	}

	return tickets, nil
}

// GetTicketsByIncidentType retrieves tickets by incident type using GSI
func (s *TicketService) GetTicketsByIncidentType(incidentType string) ([]models.IncidentTicket, error) {
	input := &dynamodb.QueryInput{
		TableName:              aws.String(s.tableName),
		IndexName:              aws.String("IncidentTypeIndex"),
		KeyConditionExpression: aws.String("#incident_type = :incident_type"),
		ExpressionAttributeNames: map[string]string{
			"#incident_type": "insident_type",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":incident_type": &types.AttributeValueMemberS{Value: incidentType},
		},
	}

	result, err := s.client.Query(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to query by incident type: %v", err)
	}

	var tickets []models.IncidentTicket
	for _, item := range result.Items {
		ticket := s.unmarshalTicket(item)
		tickets = append(tickets, ticket)
	}

	return tickets, nil
}

// SearchTickets searches tickets by title, description, or report
func (s *TicketService) SearchTickets(query string) ([]models.IncidentTicket, error) {
	// For simple search, we'll scan and filter
	// In production, you might want to use Elasticsearch or DynamoDB Streams with Lambda
	input := &dynamodb.ScanInput{
		TableName: aws.String(s.tableName),
	}

	result, err := s.client.Scan(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to scan table: %v", err)
	}

	var tickets []models.IncidentTicket
	queryLower := strings.ToLower(query)

	for _, item := range result.Items {
		ticket := s.unmarshalTicket(item)

		// Check if query matches title, description, or report
		if strings.Contains(strings.ToLower(ticket.Title), queryLower) ||
			strings.Contains(strings.ToLower(ticket.Description), queryLower) ||
			strings.Contains(strings.ToLower(ticket.Report), queryLower) {
			tickets = append(tickets, ticket)
		}
	}

	return tickets, nil
}

// unmarshalTicket converts DynamoDB item to IncidentTicket
func (s *TicketService) unmarshalTicket(item map[string]types.AttributeValue) models.IncidentTicket {
	ticket := models.IncidentTicket{}

	if v, ok := item["id"].(*types.AttributeValueMemberS); ok {
		ticket.ID = v.Value
	}
	if v, ok := item["title"].(*types.AttributeValueMemberS); ok {
		ticket.Title = v.Value
	}
	if v, ok := item["description"].(*types.AttributeValueMemberS); ok {
		ticket.Description = v.Value
	}
	if v, ok := item["report"].(*types.AttributeValueMemberS); ok {
		ticket.Report = v.Value
	}
	if v, ok := item["severity"].(*types.AttributeValueMemberS); ok {
		ticket.Severity = v.Value
	}
	if v, ok := item["category"].(*types.AttributeValueMemberS); ok {
		ticket.Category = v.Value
	}
	if v, ok := item["insident_type"].(*types.AttributeValueMemberS); ok {
		ticket.IncidentType = v.Value
	}
	if v, ok := item["environment"].(*types.AttributeValueMemberS); ok {
		ticket.Environment = v.Value
	}
	if v, ok := item["actionStatus"].(*types.AttributeValueMemberS); ok {
		ticket.ActionStatus = v.Value
	}
	if v, ok := item["status"].(*types.AttributeValueMemberS); ok {
		ticket.Status = v.Value
	}
	if v, ok := item["reporter"].(*types.AttributeValueMemberS); ok {
		ticket.Reporter = v.Value
	}
	if v, ok := item["createdAt"].(*types.AttributeValueMemberS); ok {
		ticket.CreatedAt = v.Value
	}
	if v, ok := item["emailSent"].(*types.AttributeValueMemberBOOL); ok {
		ticket.EmailSent = v.Value
	}

	// Handle optional fields
	if v, ok := item["resolutionTime"].(*types.AttributeValueMemberS); ok {
		ticket.ResolutionTime = &v.Value
	}
	if v, ok := item["emailSentAt"].(*types.AttributeValueMemberS); ok {
		ticket.EmailSentAt = &v.Value
	}
	if v, ok := item["actionTaken"].(*types.AttributeValueMemberS); ok {
		ticket.ActionTaken = &v.Value
	}

	// Handle string arrays
	if v, ok := item["suggestions"].(*types.AttributeValueMemberL); ok {
		for _, suggestion := range v.Value {
			if s, ok := suggestion.(*types.AttributeValueMemberS); ok {
				ticket.Suggestions = append(ticket.Suggestions, s.Value)
			}
		}
	}
	if v, ok := item["affectedServices"].(*types.AttributeValueMemberL); ok {
		for _, service := range v.Value {
			if s, ok := service.(*types.AttributeValueMemberS); ok {
				ticket.AffectedServices = append(ticket.AffectedServices, s.Value)
			}
		}
	}
	if v, ok := item["tags"].(*types.AttributeValueMemberL); ok {
		for _, tag := range v.Value {
			if t, ok := tag.(*types.AttributeValueMemberS); ok {
				ticket.Tags = append(ticket.Tags, t.Value)
			}
		}
	}

	return ticket
}

// HealthCheck checks if DynamoDB connection is working
func (s *TicketService) HealthCheck() error {
	input := &dynamodb.DescribeTableInput{
		TableName: aws.String(s.tableName),
	}

	_, err := s.client.DescribeTable(context.TODO(), input)
	if err != nil {
		return fmt.Errorf("health check failed: %v", err)
	}

	return nil
}
