import React from 'react';
import {
  Filters,
  IncidentsList,
  IncidentDetailDialog
} from './components';
import { useIncidents } from './hooks/useIncidents';

const Incidents: React.FC = () => {
  const {
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
  } = useIncidents();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-sm text-slate-600 dark:text-slate-300">Loading incidents...</div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
        <div>
          <h1 className="text-lg sm:text-xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
            Incident Management
          </h1>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1">View and manage all incidents</p>
        </div>
        <div className="flex items-center space-x-2">
          <span className="text-sm text-slate-500 dark:text-slate-400">
            {filteredTickets.length} of {tickets.length} incidents
          </span>
        </div>
      </div>

      {/* Filters */}
      <Filters
        filterState={filterState}
        onFilterChange={handleFilterChange}
        onClearFilters={clearFilters}
      />

      {/* Incidents List */}
      <IncidentsList
        tickets={filteredTickets}
        onIncidentClick={openIncidentDetails}
      />

      {/* Incident Detail Dialog */}
      <IncidentDetailDialog
        incident={selectedIncident}
        isOpen={isDialogOpen}
        onClose={closeIncidentDetails}
      />
    </div>
  );
};

export default Incidents; 