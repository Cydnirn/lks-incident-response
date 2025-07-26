import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { 
  FileText, 
  Clock, 
  Server, 
  AlertTriangle 
} from 'lucide-react';
import type { KeyMetricsProps } from '../types';

const KeyMetrics: React.FC<KeyMetricsProps> = ({ tickets }) => {
  const getActionStatusCount = (actionStatus: string) => {
    return tickets.filter(ticket => ticket.actionStatus === actionStatus).length;
  };

  const getCategoryCount = (category: string) => {
    return tickets.filter(ticket => ticket.category === category).length;
  };

  const getStatusCount = (status: string) => {
    return tickets.filter(ticket => ticket.status === status).length;
  };

  return (
    <div className="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-4 gap-2 sm:gap-3">
      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-xs font-medium text-slate-900 dark:text-white">Total Incidents</CardTitle>
          <FileText className="h-4 w-4 text-amber-500 dark:text-amber-400" />
        </CardHeader>
        <CardContent>
          <div className="text-lg font-bold text-slate-900 dark:text-white">{tickets.length}</div>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            +15.2% from last week
          </p>
        </CardContent>
      </Card>

      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-xs font-medium text-slate-900 dark:text-white">Pending Actions</CardTitle>
          <Clock className="h-4 w-4 text-amber-500 dark:text-amber-400" />
        </CardHeader>
        <CardContent>
          <div className="text-lg font-bold text-slate-900 dark:text-white">{getActionStatusCount('pending')}</div>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            {getActionStatusCount('auto')} auto, {getActionStatusCount('manual')} manual
          </p>
        </CardContent>
      </Card>

      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-xs font-medium text-slate-900 dark:text-white">Kubernetes Issues</CardTitle>
          <Server className="h-4 w-4 text-amber-500 dark:text-amber-400" />
        </CardHeader>
        <CardContent>
          <div className="text-lg font-bold text-slate-900 dark:text-white">{getCategoryCount('kubernetes')}</div>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            {tickets.filter(t => t.category === 'kubernetes' && t.severity === 'critical').length} critical
          </p>
        </CardContent>
      </Card>

      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-xs font-medium text-slate-900 dark:text-white">Open Incidents</CardTitle>
          <AlertTriangle className="h-4 w-4 text-amber-500 dark:text-amber-400" />
        </CardHeader>
        <CardContent>
          <div className="text-lg font-bold text-slate-900 dark:text-white">{getStatusCount('open')}</div>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            {getStatusCount('in-progress')} in progress, {getStatusCount('solved')} solved
          </p>
        </CardContent>
      </Card>
    </div>
  );
};

export default KeyMetrics; 