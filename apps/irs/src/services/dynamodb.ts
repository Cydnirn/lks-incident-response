import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, ScanCommand, GetCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import type { IncidentTicket } from '../types/ticket';
import { mockTickets } from './mockData';

// Initialize DynamoDB client
const client = new DynamoDBClient({
  region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: import.meta.env.VITE_AWS_ACCESS_KEY_ID || '',
    secretAccessKey: import.meta.env.VITE_AWS_SECRET_ACCESS_KEY || '',
    sessionToken: import.meta.env.VITE_AWS_SESSION_TOKEN || '',
  },
});

const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = import.meta.env.VITE_DYNAMODB_TABLE_NAME || 'insident';

// Use mock data for development
const USE_MOCK_DATA = import.meta.env.VITE_USE_MOCK_DATA === 'true' || !import.meta.env.VITE_AWS_ACCESS_KEY_ID;

export class TicketService {
  // Get all tickets
  static async getAllTickets(): Promise<IncidentTicket[]> {
    console.log('getAllTickets', USE_MOCK_DATA);
    if (USE_MOCK_DATA) {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 500));
      return mockTickets;
    }

    try {
      const command = new ScanCommand({
        TableName: TABLE_NAME,
      });

      const response = await docClient.send(command);
      return (response.Items || []) as IncidentTicket[];
    } catch (error) {
      console.error('Error fetching tickets:', error);
      throw error;
    }
  }

  // Get ticket by ID
  static async getTicketById(id: string): Promise<IncidentTicket | null> {
    if (USE_MOCK_DATA) {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 100));
      return mockTickets.find(ticket => ticket.id === id) || null;
    }

    try {
      const command = new GetCommand({
        TableName: TABLE_NAME,
        Key: { id },
      });

      const response = await docClient.send(command);
      return response.Item as IncidentTicket || null;
    } catch (error) {
      console.error('Error fetching ticket:', error);
      throw error;
    }
  }

  // Get tickets by status
  static async getTicketsByStatus(status: string): Promise<IncidentTicket[]> {
    if (USE_MOCK_DATA) {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 400));
      return mockTickets.filter(ticket => ticket.status === status);
    }

    try {
      const command = new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: 'StatusIndex', // Assuming you have a GSI on status
        KeyConditionExpression: '#status = :status',
        ExpressionAttributeNames: {
          '#status': 'status',
        },
        ExpressionAttributeValues: {
          ':status': status,
        },
      });

      const response = await docClient.send(command);
      return (response.Items || []) as IncidentTicket[];
    } catch (error) {
      console.error('Error fetching tickets by status:', error);
      throw error;
    }
  }

  // Get tickets by severity
  static async getTicketsBySeverity(severity: string): Promise<IncidentTicket[]> {
    if (USE_MOCK_DATA) {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 400));
      return mockTickets.filter(ticket => ticket.severity === severity);
    }

    try {
      const command = new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: 'SeverityIndex', // Assuming you have a GSI on severity
        KeyConditionExpression: '#severity = :severity',
        ExpressionAttributeNames: {
          '#severity': 'severity',
        },
        ExpressionAttributeValues: {
          ':severity': severity,
        },
      });

      const response = await docClient.send(command);
      return (response.Items || []) as IncidentTicket[];
    } catch (error) {
      console.error('Error fetching tickets by severity:', error);
      throw error;
    }
  }

  // Get tickets by incident type
  static async getTicketsByIncidentType(incidentType: string): Promise<IncidentTicket[]> {
    if (USE_MOCK_DATA) {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 400));
      return mockTickets.filter(ticket => ticket.insident_type === incidentType);
    }

    try {
      const command = new QueryCommand({
        TableName: TABLE_NAME,
        IndexName: 'IncidentTypeIndex', // Assuming you have a GSI on insident_type
        KeyConditionExpression: '#insident_type = :insident_type',
        ExpressionAttributeNames: {
          '#insident_type': 'insident_type',
        },
        ExpressionAttributeValues: {
          ':insident_type': incidentType,
        },
      });

      const response = await docClient.send(command);
      return (response.Items || []) as IncidentTicket[];
    } catch (error) {
      console.error('Error fetching tickets by incident type:', error);
      throw error;
    }
  }
} 