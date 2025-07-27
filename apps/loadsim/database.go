package main

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
)

// testDatabaseConnection tests the connection to the specified database
func testDatabaseConnection(engine, connectionString string) DatabaseResponse {
	startTime := time.Now()

	logInfo("Testing database connection", map[string]interface{}{
		"engine":            engine,
		"connection_string": connectionString,
	})

	var db *sql.DB
	var err error

	switch engine {
	case "mysql":
		db, err = sql.Open("mysql", connectionString)
	case "postgres":
		db, err = sql.Open("postgres", connectionString)
	case "sqlite":
		db, err = sql.Open("sqlite3", connectionString)
	case "dynamodb":
		// For DynamoDB, the connection string is treated as the AWS region
		if connectionString == "" {
			connectionString = "us-east-1" // Default region
		}
		sess, err := session.NewSession(&aws.Config{
			Region: aws.String(connectionString),
		})
		if err != nil {
			logError("Failed to create AWS session for DynamoDB", err, 500)
			return DatabaseResponse{
				Success: false,
				Message: fmt.Sprintf("Failed to create AWS session for DynamoDB: %v", err),
				Engine:  engine,
			}
		}

		// Test DynamoDB connection by listing tables
		svc := dynamodb.New(sess)
		input := &dynamodb.ListTablesInput{}
		_, err = svc.ListTables(input)
		if err != nil {
			logError("Failed to connect to DynamoDB", err, 500)
			return DatabaseResponse{
				Success: false,
				Message: fmt.Sprintf("Failed to connect to DynamoDB: %v", err),
				Engine:  engine,
			}
		}

		duration := time.Since(startTime)
		logInfo("DynamoDB connection test successful", map[string]interface{}{
			"engine":      engine,
			"region":      connectionString,
			"duration":    duration.String(),
			"duration_ms": duration.Milliseconds(),
		})

		return DatabaseResponse{
			Success: true,
			Message: fmt.Sprintf("Successfully connected to DynamoDB in region %s in %v", connectionString, duration),
			Engine:  engine,
		}
	default:
		logError("Unsupported database engine", fmt.Errorf("engine %s not supported", engine), 400)
		return DatabaseResponse{
			Success: false,
			Message: fmt.Sprintf("Unsupported database engine: %s", engine),
			Engine:  engine,
		}
	}

	if err != nil {
		logError("Failed to open database connection", err, 500)
		return DatabaseResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to open database connection: %v", err),
			Engine:  engine,
		}
	}
	defer db.Close()

	// Set connection timeout
	db.SetConnMaxLifetime(time.Second * 5)
	db.SetMaxOpenConns(1)

	// Test the connection
	if err := db.Ping(); err != nil {
		logError("Database ping failed", err, 500)
		return DatabaseResponse{
			Success: false,
			Message: fmt.Sprintf("Database ping failed: %v", err),
			Engine:  engine,
		}
	}

	duration := time.Since(startTime)
	logInfo("Database connection test successful", map[string]interface{}{
		"engine":      engine,
		"duration":    duration.String(),
		"duration_ms": duration.Milliseconds(),
	})

	return DatabaseResponse{
		Success: true,
		Message: fmt.Sprintf("Successfully connected to %s database in %v", engine, duration),
		Engine:  engine,
	}
}
