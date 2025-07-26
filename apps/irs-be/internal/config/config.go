package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type AWSConfig struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	SessionToken    string
}

type DynamoDBConfig struct {
	TableName string
}

type ServerConfig struct {
	Host       string
	Port       string
	CORSOrigin string
}

type Config struct {
	AWS      AWSConfig
	DynamoDB DynamoDBConfig
	Server   ServerConfig
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && value != "" {
		return value
	}
	return fallback
}

func LoadConfig() Config {
	// Load .env file if present
	if err := godotenv.Load(); err != nil {
		fmt.Printf("No .env file found, using environment variables\n")
	}

	cfg := Config{
		AWS: AWSConfig{
			Region:          getEnv("AWS_REGION", "us-east-1"),
			AccessKeyID:     getEnv("AWS_ACCESS_KEY_ID", ""),
			SecretAccessKey: getEnv("AWS_SECRET_ACCESS_KEY", ""),
			SessionToken:    getEnv("AWS_SESSION_TOKEN", ""),
		},
		DynamoDB: DynamoDBConfig{
			TableName: getEnv("DYNAMODB_TABLE_NAME", "insident"),
		},
		Server: ServerConfig{
			Host:       getEnv("HOST", "0.0.0.0"),
			Port:       getEnv("PORT", "8080"),
			CORSOrigin: getEnv("CORS_ORIGIN", "*"),
		},
	}

	// Log configuration (without sensitive data)
	fmt.Printf("Configuration loaded:\n")
	fmt.Printf("  AWS Region: %s\n", cfg.AWS.Region)
	fmt.Printf("  AWS Access Key ID: %s\n", maskString(cfg.AWS.AccessKeyID))
	fmt.Printf("  AWS Secret Access Key: %s\n", maskString(cfg.AWS.SecretAccessKey))
	fmt.Printf("  AWS Session Token: %s\n", maskString(cfg.AWS.SessionToken))
	fmt.Printf("  DynamoDB Table: %s\n", cfg.DynamoDB.TableName)
	fmt.Printf("  Server Host: %s\n", cfg.Server.Host)
	fmt.Printf("  Server Port: %s\n", cfg.Server.Port)
	fmt.Printf("  CORS Origin: %s\n", cfg.Server.CORSOrigin)

	return cfg
}

// maskString masks sensitive strings for logging
func maskString(s string) string {
	if s == "" {
		return "<not set>"
	}
	if len(s) <= 4 {
		return "****"
	}
	return s[:4] + "****"
}
