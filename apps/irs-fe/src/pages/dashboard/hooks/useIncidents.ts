import { useState, useEffect } from 'react';
import type { IncidentTicket } from '../../../types/ticket';
import type { FilterState } from '../types';
import { useRealtimeData } from '../../../hooks/useRealtimeData';

export const useIncidents = () => {
  const {
    data: tickets,
    loading,
    error,
    isInitialized,
    lastUpdated,
    refreshData,
    isRefreshing
  } = useRealtimeData({
    refreshInterval: 3000, // 3 seconds
    enableRealtime: true
  });

  const [filteredTickets, setFilteredTickets] = useState<IncidentTicket[]>([]);
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

  // Apply filters whenever tickets change
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
    error,
    isInitialized,
    lastUpdated,
    isRefreshing,
    filterState,
    selectedIncident,
    isDialogOpen,
    handleFilterChange,
    clearFilters,
    openIncidentDetails,
    closeIncidentDetails,
    refreshData
  };
}; 