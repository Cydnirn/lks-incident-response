import React from 'react';
import {
  DashboardHeader,
  KeyMetrics,
  StatisticsOverview,
  AdvancedDashboardGraphs,
  DashboardGraphs
} from './components';
import { RealtimeStatus } from '../../components/ui/RealtimeStatus';
import { EmptyState } from '../../components/ui/EmptyState';
import { useDashboard } from './hooks/useDashboard';

const Dashboard: React.FC = () => {
  const {
    tickets,
    loading,
    error,
    isInitialized,
    lastUpdated,
    isRefreshing,
    refreshData
  } = useDashboard();

  // Show loading only during initial load
  if (loading && !isInitialized) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-sm text-slate-600 dark:text-slate-300">Loading dashboard...</div>
      </div>
    );
  }

  // Show empty state if no data and initialized
  if (isInitialized && tickets.length === 0) {
    return (
      <div className="space-y-4">
        {/* Real-time Status */}
        <div className="flex justify-end">
          <RealtimeStatus
            lastUpdated={lastUpdated}
            isRefreshing={isRefreshing}
            error={error}
            isInitialized={isInitialized}
            onRefresh={refreshData}
          />
        </div>

        <EmptyState
          title="No Incidents Found"
          description="There are currently no incidents in the system. New incidents will appear here automatically."
          icon="inbox"
          action={{
            label: "Refresh Data",
            onClick: refreshData
          }}
        />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <DashboardHeader tickets={tickets} lastUpdated={lastUpdated} isRefreshing={isRefreshing} error={error} isInitialized={isInitialized} refreshData={refreshData} />

      {/* Key Metrics */}
      <KeyMetrics tickets={tickets} />

      {/* Statistics Overview */}
      <StatisticsOverview tickets={tickets} />

      {/* Dashboard Graphs */}
      <DashboardGraphs tickets={tickets} />

      {/* Advanced Dashboard Graphs */}
      <AdvancedDashboardGraphs tickets={tickets} />
    </div>
  );
};

export default Dashboard; 