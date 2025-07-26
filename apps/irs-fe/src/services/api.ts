import type { IncidentTicket } from '../types/ticket';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api';

export class APIService {
  // Get all tickets
  static async getAllTickets(): Promise<IncidentTicket[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/tickets`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      return result.data || [];
    } catch (error) {
      console.error('Error fetching tickets:', error);
      throw error;
    }
  }

  // Get ticket by ID
  static async getTicketById(id: string): Promise<IncidentTicket | null> {
    try {
      const response = await fetch(`${API_BASE_URL}/tickets/${id}`);
      if (!response.ok) {
        if (response.status === 404) {
          return null;
        }
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      return result.data || null;
    } catch (error) {
      console.error('Error fetching ticket:', error);
      throw error;
    }
  }

  // Get tickets by status
  static async getTicketsByStatus(status: string): Promise<IncidentTicket[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/tickets/status/${status}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      return result.data || [];
    } catch (error) {
      console.error('Error fetching tickets by status:', error);
      throw error;
    }
  }

  // Get tickets by severity
  static async getTicketsBySeverity(severity: string): Promise<IncidentTicket[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/tickets/severity/${severity}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      return result.data || [];
    } catch (error) {
      console.error('Error fetching tickets by severity:', error);
      throw error;
    }
  }

  // Get tickets by incident type
  static async getTicketsByIncidentType(incidentType: string): Promise<IncidentTicket[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/tickets/incident-type/${incidentType}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      return result.data || [];
    } catch (error) {
      console.error('Error fetching tickets by incident type:', error);
      throw error;
    }
  }

  // Search tickets
  static async searchTickets(query: string): Promise<IncidentTicket[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/tickets/search?q=${encodeURIComponent(query)}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      return result.data || [];
    } catch (error) {
      console.error('Error searching tickets:', error);
      throw error;
    }
  }

  // Get tickets with filters
  static async getTicketsWithFilters(filters: {
    severity?: string;
    category?: string;
    environment?: string;
    status?: string;
    actionStatus?: string;
    incidentType?: string;
    search?: string;
  }): Promise<IncidentTicket[]> {
    try {
      const params = new URLSearchParams();
      Object.entries(filters).forEach(([key, value]) => {
        if (value) {
          params.append(key, value);
        }
      });

      const response = await fetch(`${API_BASE_URL}/tickets/filter?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      return result.data || [];
    } catch (error) {
      console.error('Error fetching tickets with filters:', error);
      throw error;
    }
  }

  // Health check
  static async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL.replace('/api', '')}/health`);
      return response.ok;
    } catch (error) {
      console.error('Health check failed:', error);
      return false;
    }
  }
} 