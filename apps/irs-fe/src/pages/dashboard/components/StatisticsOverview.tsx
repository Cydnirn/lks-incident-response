import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { 
  TrendingUp,
  Zap,
  Server
} from 'lucide-react';
import type { StatisticsOverviewProps } from '../types';

const StatisticsOverview: React.FC<StatisticsOverviewProps> = ({ tickets }) => {
  const getSeverityCount = (severity: string) => {
    return tickets.filter(ticket => ticket.severity === severity).length;
  };

  const getActionStatusCount = (actionStatus: string) => {
    return tickets.filter(ticket => ticket.actionStatus === actionStatus).length;
  };

  const getEnvironmentCount = (environment: string) => {
    return tickets.filter(ticket => ticket.environment === environment).length;
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
      {/* Severity Breakdown */}
      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
            <TrendingUp className="h-4 w-4" />
            <span>Severity Distribution</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {Object.entries({
              critical: getSeverityCount('critical'),
              high: getSeverityCount('high'),
              medium: getSeverityCount('medium'),
              low: getSeverityCount('low')
            }).map(([severity, count]) => (
              <div key={severity} className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div 
                    className={`w-3 h-3 rounded-full ${
                      severity === 'critical' ? 'bg-red-500' :
                      severity === 'high' ? 'bg-orange-500' :
                      severity === 'medium' ? 'bg-yellow-500' : 'bg-green-500'
                    }`}
                  />
                  <span className="text-xs font-medium text-slate-700 dark:text-slate-300 capitalize">
                    {severity}
                  </span>
                </div>
                <div className="flex items-center space-x-1">
                  <div className="w-20 bg-slate-100 dark:bg-slate-700 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full ${
                        severity === 'critical' ? 'bg-red-500' :
                        severity === 'high' ? 'bg-orange-500' :
                        severity === 'medium' ? 'bg-yellow-500' : 'bg-green-500'
                      }`}
                      style={{ width: `${tickets.length > 0 ? (count / tickets.length) * 100 : 0}%` }}
                    />
                  </div>
                  <div className="flex items-center space-x-1">
                    <span className="text-xs text-slate-600 dark:text-slate-400 w-8 text-right">
                      {count}
                    </span>
                    <span className="text-xs font-medium text-slate-900 dark:text-white w-8 text-right">
                      {tickets.length > 0 ? Math.round((count / tickets.length) * 100) : 0}%
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Action Status Breakdown */}
      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
            <Zap className="h-4 w-4" />
            <span>Action Status</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {Object.entries({
              auto: getActionStatusCount('auto'),
              manual: getActionStatusCount('manual'),
              pending: getActionStatusCount('pending')
            }).map(([status, count]) => (
              <div key={status} className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div 
                    className={`w-3 h-3 rounded-full ${
                      status === 'auto' ? 'bg-green-500' :
                      status === 'manual' ? 'bg-blue-500' : 'bg-yellow-500'
                    }`}
                  />
                  <span className="text-xs font-medium text-slate-700 dark:text-slate-300 capitalize">
                    {status === 'auto' ? 'Auto-Healing' : status}
                  </span>
                </div>
                <div className="flex items-center space-x-2">
                  <div className="w-20 bg-slate-100 dark:bg-slate-700 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full ${
                        status === 'auto' ? 'bg-green-500' :
                        status === 'manual' ? 'bg-blue-500' : 'bg-yellow-500'
                      }`}
                      style={{ width: `${tickets.length > 0 ? (count / tickets.length) * 100 : 0}%` }}
                    />
                  </div>
                  <div className="flex items-center space-x-1">
                    <span className="text-xs text-slate-600 dark:text-slate-400 w-8 text-right">
                      {count}
                    </span>
                    <span className="text-xs font-medium text-slate-900 dark:text-white w-8 text-right">
                      {tickets.length > 0 ? Math.round((count / tickets.length) * 100) : 0}%
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Environment Breakdown */}
      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
            <Server className="h-4 w-4" />
            <span>Environment</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {Object.entries({
              production: getEnvironmentCount('production'),
              staging: getEnvironmentCount('staging'),
              development: getEnvironmentCount('development')
            }).map(([environment, count]) => (
              <div key={environment} className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div 
                    className={`w-3 h-3 rounded-full ${
                      environment === 'production' ? 'bg-red-500' :
                      environment === 'staging' ? 'bg-orange-500' : 'bg-blue-500'
                    }`}
                  />
                  <span className="text-xs font-medium text-slate-700 dark:text-slate-300 capitalize">
                    {environment}
                  </span>
                </div>
                <div className="flex items-center space-x-2">
                  <div className="w-20 bg-slate-100 dark:bg-slate-700 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full ${
                        environment === 'production' ? 'bg-red-500' :
                        environment === 'staging' ? 'bg-orange-500' : 'bg-blue-500'
                      }`}
                      style={{ width: `${tickets.length > 0 ? (count / tickets.length) * 100 : 0}%` }}
                    />
                  </div>
                  <div className="flex items-center space-x-1">
                    <span className="text-xs text-slate-600 dark:text-slate-400 w-8 text-right">
                      {count}
                    </span>
                    <span className="text-xs font-medium text-slate-900 dark:text-white w-8 text-right">
                      {tickets.length > 0 ? Math.round((count / tickets.length) * 100) : 0}%
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default StatisticsOverview; 