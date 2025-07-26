import type { IncidentTicket } from '../../types/ticket';

export interface DashboardStats {
  totalIncidents: number;
  criticalIncidents: number;
  pendingActions: number;
  kubernetesIssues: number;
  openIncidents: number;
}

export interface FilterState {
  searchTerm: string;
  selectedSeverity: string;
  selectedCategory: string;
  selectedIncidentType: string;
  selectedEnvironment: string;
  selectedActionStatus: string;
  selectedStatus: string;
}

export interface IncidentDetailDialogProps {
  incident: IncidentTicket | null;
  isOpen: boolean;
  onClose: () => void;
}

export interface DashboardHeaderProps {
  tickets: IncidentTicket[];
  lastUpdated: Date | null;
  isRefreshing: boolean;
  error: string | null;
  isInitialized: boolean;
  refreshData: () => void;
}

export interface KeyMetricsProps {
  tickets: IncidentTicket[];
}

export interface StatisticsOverviewProps {
  tickets: IncidentTicket[];
}

export interface FiltersProps {
  filterState: FilterState;
  onFilterChange: (key: keyof FilterState, value: string) => void;
  onClearFilters: () => void;
}

export interface IncidentsListProps {
  tickets: IncidentTicket[];
  onIncidentClick: (incident: IncidentTicket) => void;
} 