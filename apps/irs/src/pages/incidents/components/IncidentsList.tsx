import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { Badge } from '../../../components/ui/badge';
import { Button } from '../../../components/ui/button';
import { 
  Server,
  Settings,
  Activity,
  Shield,
  Database,
  Network,
  HardDrive,
  GitBranch,
  FileText,
  Eye,
  ExternalLink,
  Calendar,
  Mail
} from 'lucide-react';
import type { IncidentsListProps } from '../../dashboard/types';

const IncidentsList: React.FC<IncidentsListProps> = ({ tickets, onIncidentClick }) => {
  const getSeverityVariant = (severity: string) => {
    switch (severity) {
      case 'critical': return 'destructive';
      case 'high': return 'warning';
      case 'medium': return 'default';
      case 'low': return 'secondary';
      default: return 'default';
    }
  };

  const getActionStatusVariant = (actionStatus: string) => {
    switch (actionStatus) {
      case 'auto': return 'success';
      case 'manual': return 'warning';
      case 'pending': return 'info';
      default: return 'default';
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'kubernetes': return <Server className="h-4 w-4" />;
      case 'infrastructure': return <Settings className="h-4 w-4" />;
      case 'monitoring': return <Activity className="h-4 w-4" />;
      case 'security': return <Shield className="h-4 w-4" />;
      case 'database': return <Database className="h-4 w-4" />;
      case 'network': return <Network className="h-4 w-4" />;
      case 'storage': return <HardDrive className="h-4 w-4" />;
      case 'ci-cd': return <GitBranch className="h-4 w-4" />;
      default: return <FileText className="h-4 w-4" />;
    }
  };

  const getStatusVariant = (status: string) => {
    switch (status) {
      case 'open': return 'destructive';
      case 'in-progress': return 'warning';
      case 'solved': return 'success';
      case 'closed': return 'secondary';
      case 'pending': return 'info';
      default: return 'default';
    }
  };

  return (
    <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center justify-between text-sm font-semibold text-slate-900 dark:text-white">
          <span>Recent Incidents ({tickets.length})</span>
          <div className="flex items-center space-x-2 text-xs text-slate-500 dark:text-slate-400">
            <Eye className="h-3 w-3" />
            <span>Read-only Dashboard</span>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {tickets.map((ticket) => (
            <div 
              key={ticket.id} 
              className="bg-white/80 dark:bg-slate-800/80 border border-slate-200/50 dark:border-slate-700/50 rounded-xl p-4 hover:shadow-lg hover:bg-white/90 dark:hover:bg-slate-800/90 transition-all duration-300 cursor-pointer group backdrop-blur-sm"
              onClick={() => onIncidentClick(ticket)}
            >
              {/* Header */}
              <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between mb-3 space-y-2 sm:space-y-0">
                <div className="flex items-center space-x-2">
                  <span className="text-xs font-mono text-slate-500 dark:text-slate-400 bg-slate-100/50 dark:bg-slate-700/50 px-2 py-1 rounded">
                    {ticket.id}
                  </span>
                  <h3 className="text-sm font-semibold text-slate-900 dark:text-white group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors duration-200">
                    {ticket.title}
                  </h3>
                </div>
                <div className="flex items-center space-x-2">
                  <Badge variant={getSeverityVariant(ticket.severity)} className="text-xs">
                    {ticket.severity}
                  </Badge>
                  <Badge variant={getStatusVariant(ticket.status)} className="text-xs">
                    {ticket.status === 'in-progress' ? 'In Progress' : ticket.status.charAt(0).toUpperCase() + ticket.status.slice(1)}
                  </Badge>
                </div>
              </div>

              {/* Description */}
              <p className="text-xs text-slate-600 dark:text-slate-400 mb-3 line-clamp-2">
                {ticket.description}
              </p>

              {/* Metadata */}
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-3 space-y-2 sm:space-y-0">
                <div className="flex flex-wrap items-center gap-2 sm:gap-3 text-xs text-slate-500 dark:text-slate-400">
                  <div className="flex items-center space-x-1">
                    {getCategoryIcon(ticket.category)}
                    <span>{ticket.category}</span>
                  </div>
                  <div className="flex items-center space-x-1">
                    <Calendar className="h-3 w-3" />
                    <span>{new Date(ticket.createdAt).toLocaleDateString()}</span>
                  </div>
                  <Badge variant="outline" className="text-xs bg-white/50 dark:bg-slate-800/50">
                    {ticket.environment}
                  </Badge>
                </div>
                
                <div className="flex items-center space-x-2">
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="opacity-0 group-hover:opacity-100 text-slate-500 hover:text-amber-600 dark:hover:text-amber-400 text-xs transition-all duration-200"
                  >
                    <ExternalLink className="h-3 w-3 mr-1" />
                    View
                  </Button>
                </div>
              </div>

              {/* Action Section */}
              {ticket.actionTaken && (
                <div className="p-3 bg-gradient-to-r from-blue-50/50 to-indigo-50/50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200/50 dark:border-blue-800/50">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center space-x-2">
                      <Badge variant={getActionStatusVariant(ticket.actionStatus)} className="text-xs">
                        {ticket.actionStatus === 'auto' ? 'Auto-Healing' : ticket.actionStatus === 'manual' ? 'Manual' : 'Pending'}
                      </Badge>
                      {ticket.resolutionTime && (
                        <div className="flex items-center space-x-1 text-xs text-slate-500 dark:text-slate-400">
                          <Calendar className="h-3 w-3" />
                          <span>{ticket.resolutionTime}</span>
                        </div>
                      )}
                    </div>
                    {ticket.emailSent && (
                      <div className="flex items-center space-x-1 text-xs text-slate-500 dark:text-slate-400">
                        <Mail className="h-3 w-3" />
                        <span>Email sent</span>
                      </div>
                    )}
                  </div>
                  <p className="text-xs text-blue-800 dark:text-blue-200">
                    {ticket.actionTaken}
                  </p>
                </div>
              )}

              {/* Affected Services */}
              {ticket.affectedServices && ticket.affectedServices.length > 0 && (
                <div className="mt-3">
                  <div className="flex items-center space-x-2 mb-2">
                    <Server className="h-3 w-3 text-slate-500 dark:text-slate-400" />
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Affected Services</span>
                  </div>
                  <div className="flex flex-wrap gap-1">
                    {ticket.affectedServices.map((service: string, index: number) => (
                      <Badge key={index} variant="secondary" className="text-xs">
                        {service}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ))}
          
          {tickets.length === 0 && (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <FileText className="h-8 w-8 mx-auto mb-4 text-slate-300 dark:text-slate-600" />
              <p className="text-sm">No incidents found matching your filters</p>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default IncidentsList; 