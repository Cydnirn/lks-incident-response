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
  Wrench,
  X
} from 'lucide-react';
import type { IncidentDetailDialogProps } from '../../dashboard/types';

const IncidentDetailDialog: React.FC<IncidentDetailDialogProps> = ({ incident, isOpen, onClose }) => {
  if (!incident || !isOpen) return null;

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

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-2 sm:p-4 animate-in fade-in duration-300">
      <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-2xl max-w-5xl w-full max-h-[95vh] sm:max-h-[90vh] overflow-hidden border border-slate-200/50 dark:border-slate-700/50 animate-in slide-in-from-bottom-4 duration-300">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-r from-slate-50 to-amber-50/30 dark:from-slate-700/50 dark:to-slate-600/50">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-gradient-to-r from-amber-500 to-orange-500 rounded-xl shadow-lg">
              {getCategoryIcon(incident.category)}
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900 dark:text-white">{incident.title}</h2>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-mono">ID: {incident.id}</p>
            </div>
          </div>
          <Button variant="ghost" size="sm" onClick={onClose} className="text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 hover:bg-slate-100/50 dark:hover:bg-slate-700/50">
            <X className="h-5 w-5" />
          </Button>
        </div>

        {/* Content */}
        <div className="p-4 sm:p-6 overflow-y-auto max-h-[calc(95vh-140px)] sm:max-h-[calc(90vh-140px)]">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6">
            {/* Main Content */}
            <div className="lg:col-span-2 space-y-4">
              {/* Description */}
              <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-semibold text-slate-900 dark:text-white">Description</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-slate-700 dark:text-slate-300 leading-relaxed">{incident.description}</p>
                </CardContent>
              </Card>

              {/* Incident Report */}
              <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-semibold text-slate-900 dark:text-white">Incident Report</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-slate-700 dark:text-slate-300 leading-relaxed">{incident.report}</p>
                </CardContent>
              </Card>

              {/* AI Suggestions */}
              {incident.suggestions && incident.suggestions.length > 0 && (
                <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                  <CardHeader className="pb-3">
                    <CardTitle className="text-sm font-semibold text-slate-900 dark:text-white">AI Suggestions</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <ul className="space-y-2">
                      {incident.suggestions.map((suggestion, index) => (
                        <li key={index} className="flex items-start space-x-2">
                          <span className="text-amber-500 mt-1">•</span>
                          <span className="text-sm text-slate-700 dark:text-slate-300">{suggestion}</span>
                        </li>
                      ))}
                    </ul>
                  </CardContent>
                </Card>
              )}

              {/* Action Taken */}
              {incident.actionTaken && (
                <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-blue-50/50 to-indigo-50/30 dark:from-blue-900/20 dark:to-indigo-900/20 shadow-sm hover:shadow-md transition-all duration-300">
                  <CardHeader className="pb-3">
                    <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
                      <Wrench className="h-4 w-4" />
                      <span>Action Taken</span>
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="p-3 bg-blue-100/50 dark:bg-blue-900/30 rounded-lg">
                      <p className="text-sm text-blue-800 dark:text-blue-200">{incident.actionTaken}</p>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* Affected Services */}
              {incident.affectedServices && incident.affectedServices.length > 0 && (
                <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                  <CardHeader className="pb-3">
                    <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
                      <Server className="h-4 w-4" />
                      <span>Affected Services</span>
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="flex flex-wrap gap-2">
                      {incident.affectedServices.map((service, index) => (
                        <Badge key={index} variant="secondary" className="text-xs">
                          {service}
                        </Badge>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>

            {/* Sidebar */}
            <div className="space-y-4">
              {/* Status Cards */}
              <div className="grid grid-cols-2 gap-3">
                <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                  <CardContent className="p-3">
                    <div className="text-center">
                      <Badge variant={getSeverityVariant(incident.severity)} className="mb-2 text-xs">
                        {incident.severity}
                      </Badge>
                      <p className="text-xs text-slate-500 dark:text-slate-400">Severity</p>
                    </div>
                  </CardContent>
                </Card>
                <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                  <CardContent className="p-3">
                    <div className="text-center">
                      <Badge variant={getActionStatusVariant(incident.actionStatus)} className="mb-2 text-xs">
                        {incident.actionStatus === 'auto' ? 'Auto' : incident.actionStatus === 'manual' ? 'Manual' : 'Pending'}
                      </Badge>
                      <p className="text-xs text-slate-500 dark:text-slate-400">Action</p>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Incident Details */}
              <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-semibold text-slate-900 dark:text-white">Details</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Category</span>
                    <div className="flex items-center space-x-2">
                      {getCategoryIcon(incident.category)}
                      <span className="text-xs text-slate-600 dark:text-slate-400">{incident.category}</span>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Incident Type</span>
                    <Badge variant="outline" className="text-xs">
                      {incident.insident_type}
                    </Badge>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Environment</span>
                    <Badge variant="outline" className="text-xs">
                      {incident.environment}
                    </Badge>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Reporter</span>
                    <span className="text-xs text-slate-600 dark:text-slate-400">{incident.reporter}</span>
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Created</span>
                    <span className="text-xs text-slate-600 dark:text-slate-400">
                      {new Date(incident.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                  
                  {incident.resolutionTime && (
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Resolution</span>
                      <span className="text-xs text-slate-600 dark:text-slate-400">{incident.resolutionTime}</span>
                    </div>
                  )}
                  
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">Email Sent</span>
                    <Badge variant={incident.emailSent ? 'success' : 'secondary'} className="text-xs">
                      {incident.emailSent ? 'Yes' : 'No'}
                    </Badge>
                  </div>
                </CardContent>
              </Card>

              {/* Tags */}
              {incident.tags && incident.tags.length > 0 && (
                <Card className="border-slate-200/50 dark:border-slate-700/50 bg-gradient-to-br from-slate-50/50 to-amber-50/30 dark:from-slate-700/30 dark:to-slate-600/30 shadow-sm hover:shadow-md transition-all duration-300">
                  <CardHeader className="pb-3">
                    <CardTitle className="text-sm font-semibold text-slate-900 dark:text-white">Tags</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="flex flex-wrap gap-2">
                      {incident.tags.map((tag, index) => (
                        <Badge key={index} variant="outline" className="text-xs">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default IncidentDetailDialog; 