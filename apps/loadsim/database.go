package main

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	_ "github.com/go-sql-driver/mysql"
	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
)

// testDatabaseConnection tests connectivity to various database engines
func testDatabaseConnection(engine, connectionString string) DatabaseResponse {
	response := DatabaseResponse{
		Engine:  engine,
		Success: false,
		Message: "",
	}

	switch engine {
	case "mysql":
		response = testMySQLConnection(connectionString)
	case "postgres":
		response = testPostgreSQLConnection(connectionString)
	case "sqlite":
		response = testSQLiteConnection(connectionString)
	case "dynamodb":
		response = testDynamoDBConnection(connectionString)
	default:
		response.Message = fmt.Sprintf("Unsupported database engine: %s. Supported engines: mysql, postgres, sqlite, dynamodb", engine)
	}

	// Update global status
	statusMutex.Lock()
	if response.Success {
		status.DatabaseStatus = fmt.Sprintf("%s: Connected", engine)
	} else {
		status.DatabaseStatus = fmt.Sprintf("%s: Failed - %s", engine, response.Message)
	}
	statusMutex.Unlock()

	log.Printf("Database connection test - Engine: %s, Success: %v, Message: %s", 
		engine, response.Success, response.Message)

	return response
}

// testMySQLConnection tests MySQL database connectivity
func testMySQLConnection(connectionString string) DatabaseResponse {
	response := DatabaseResponse{
		Engine:  "mysql",
		Success: false,
	}

	db, err := sql.Open("mysql", connectionString)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to open MySQL connection: %v", err)
		return response
	}
	defer db.Close()

	// Test the connection
	err = db.Ping()
	if err != nil {
		response.Message = fmt.Sprintf("Failed to ping MySQL database: %v", err)
		return response
	}

	// Try a simple query
	var version string
	err = db.QueryRow("SELECT VERSION()").Scan(&version)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to query MySQL version: %v", err)
		return response
	}

	response.Success = true
	response.Message = fmt.Sprintf("Successfully connected to MySQL. Version: %s", version)
	return response
}

// testPostgreSQLConnection tests PostgreSQL database connectivity
func testPostgreSQLConnection(connectionString string) DatabaseResponse {
	response := DatabaseResponse{
		Engine:  "postgres",
		Success: false,
	}

	db, err := sql.Open("postgres", connectionString)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to open PostgreSQL connection: %v", err)
		return response
	}
	defer db.Close()

	// Test the connection
	err = db.Ping()
	if err != nil {
		response.Message = fmt.Sprintf("Failed to ping PostgreSQL database: %v", err)
		return response
	}

	// Try a simple query
	var version string
	err = db.QueryRow("SELECT version()").Scan(&version)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to query PostgreSQL version: %v", err)
		return response
	}

	response.Success = true
	response.Message = fmt.Sprintf("Successfully connected to PostgreSQL. Version: %s", version[:100])
	return response
}

// testSQLiteConnection tests SQLite database connectivity
func testSQLiteConnection(connectionString string) DatabaseResponse {
	response := DatabaseResponse{
		Engine:  "sqlite",
		Success: false,
	}

	db, err := sql.Open("sqlite3", connectionString)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to open SQLite connection: %v", err)
		return response
	}
	defer db.Close()

	// Test the connection
	err = db.Ping()
	if err != nil {
		response.Message = fmt.Sprintf("Failed to ping SQLite database: %v", err)
		return response
	}

	// Try a simple query
	var version string
	err = db.QueryRow("SELECT sqlite_version()").Scan(&version)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to query SQLite version: %v", err)
		return response
	}

	response.Success = true
	response.Message = fmt.Sprintf("Successfully connected to SQLite. Version: %s", version)
	return response
}

// testDynamoDBConnection tests DynamoDB connectivity
func testDynamoDBConnection(region string) DatabaseResponse {
	response := DatabaseResponse{
		Engine:  "dynamodb",
		Success: false,
	}

	// For DynamoDB, the connection string is treated as the AWS region
	if region == "" {
		region = "us-east-1" // Default region
	}

	// Create AWS session
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		response.Message = fmt.Sprintf("Failed to create AWS session: %v", err)
		return response
	}

	// Create DynamoDB client
	svc := dynamodb.New(sess)

	// Test the connection by listing tables
	input := &dynamodb.ListTablesInput{}
	result, err := svc.ListTables(input)
	if err != nil {
		response.Message = fmt.Sprintf("Failed to connect to DynamoDB: %v", err)
		return response
	}

	tableCount := len(result.TableNames)
	response.Success = true
	response.Message = fmt.Sprintf("Successfully connected to DynamoDB in region %s. Found %d tables", region, tableCount)
	return response
}
