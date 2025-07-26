import React from 'react';
import { Badge } from '../../../components/ui/badge';
import type { DashboardHeaderProps } from '../types';
import { RealtimeStatus } from '../../../components/ui/RealtimeStatus';

const DashboardHeader: React.FC<DashboardHeaderProps> = ({ tickets, lastUpdated, isRefreshing, error, isInitialized, refreshData }) => {
  const getSeverityCount = (severity: string) => {
    return tickets.filter(ticket => ticket.severity === severity).length;
  };

  return (
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
      <div>
        <h1 className="text-lg sm:text-xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
          Incident Response Dashboard
        </h1>
        <p className="text-xs text-slate-600 dark:text-slate-400 mt-1">Real-time monitoring and incident management overview</p>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <Badge variant="outline" className="text-xs bg-white/80 dark:bg-slate-800/80">
          {tickets.length} Total
        </Badge>
        <Badge variant="destructive" className="text-xs">
          {getSeverityCount('critical')} Critical
        </Badge>
        <div className="flex justify-end">
        <RealtimeStatus
          lastUpdated={lastUpdated}
          isRefreshing={isRefreshing}
          error={error}
          isInitialized={isInitialized}
          onRefresh={refreshData}
        />
      </div>  
      </div>

    </div>
  );
};

export default DashboardHeader; 