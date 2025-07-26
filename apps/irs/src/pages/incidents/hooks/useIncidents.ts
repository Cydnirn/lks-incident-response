import { useState, useEffect } from 'react';
import type { IncidentTicket } from '../../../types/ticket';
import type { FilterState } from '../../dashboard/types';
import { TicketService } from '../../../services/dynamodb';

export const useIncidents = () => {
  const [tickets, setTickets] = useState<IncidentTicket[]>([]);
  const [filteredTickets, setFilteredTickets] = useState<IncidentTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedIncident, setSelectedIncident] = useState<IncidentTicket | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);

  const [filterState, setFilterState] = useState<FilterState>({
    searchTerm: '',
    selectedSeverity: '',
    selectedCategory: '',
    selectedIncidentType: '',
    selectedEnvironment: '',
    selectedActionStatus: '',
    selectedStatus: ''
  });

  useEffect(() => {
    const fetchTickets = async () => {
      try {
        setLoading(true);
        const data = await TicketService.getAllTickets();
        setTickets(data);
        setFilteredTickets(data);
      } catch (error) {
        console.error('Error fetching tickets:', error);
        // Fallback to mock data if DynamoDB fails
        const { mockTickets } = await import('../../../services/mockData');
        setTickets(mockTickets);
        setFilteredTickets(mockTickets);
      } finally {
        setLoading(false);
      }
    };

    fetchTickets();
  }, []);

  useEffect(() => {
    let filtered = tickets;

    if (filterState.searchTerm) {
      filtered = filtered.filter(ticket =>
        ticket.title.toLowerCase().includes(filterState.searchTerm.toLowerCase()) ||
        ticket.description.toLowerCase().includes(filterState.searchTerm.toLowerCase()) ||
        ticket.report.toLowerCase().includes(filterState.searchTerm.toLowerCase())
      );
    }

    if (filterState.selectedSeverity) {
      filtered = filtered.filter(ticket => ticket.severity === filterState.selectedSeverity);
    }

    if (filterState.selectedCategory) {
      filtered = filtered.filter(ticket => ticket.category === filterState.selectedCategory);
    }

    if (filterState.selectedIncidentType) {
      filtered = filtered.filter(ticket => ticket.insident_type === filterState.selectedIncidentType);
    }

    if (filterState.selectedEnvironment) {
      filtered = filtered.filter(ticket => ticket.environment === filterState.selectedEnvironment);
    }

    if (filterState.selectedActionStatus) {
      filtered = filtered.filter(ticket => ticket.actionStatus === filterState.selectedActionStatus);
    }

    if (filterState.selectedStatus) {
      filtered = filtered.filter(ticket => ticket.status === filterState.selectedStatus);
    }

    setFilteredTickets(filtered);
  }, [tickets, filterState]);

  const handleFilterChange = (key: keyof FilterState, value: string) => {
    setFilterState(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const clearFilters = () => {
    setFilterState({
      searchTerm: '',
      selectedSeverity: '',
      selectedCategory: '',
      selectedIncidentType: '',
      selectedEnvironment: '',
      selectedActionStatus: '',
      selectedStatus: ''
    });
  };

  const openIncidentDetails = (incident: IncidentTicket) => {
    setSelectedIncident(incident);
    setIsDialogOpen(true);
  };

  const closeIncidentDetails = () => {
    setIsDialogOpen(false);
    setSelectedIncident(null);
  };

  return {
    tickets,
    filteredTickets,
    loading,
    filterState,
    selectedIncident,
    isDialogOpen,
    handleFilterChange,
    clearFilters,
    openIncidentDetails,
    closeIncidentDetails
  };
}; 