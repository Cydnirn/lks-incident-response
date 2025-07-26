import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { 
  PieChart,
  Activity
} from 'lucide-react';
import type { IncidentTicket } from '../../../types/ticket';

interface DashboardGraphsProps {
  tickets: IncidentTicket[];
}

export const DashboardGraphs: React.FC<DashboardGraphsProps> = ({ tickets }) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('severity');

  // Calculate data for charts
  const getIncidentTypeData = () => {
    const typeCounts: Record<string, number> = {};
    
    tickets.forEach(ticket => {
      typeCounts[ticket.insident_type] = (typeCounts[ticket.insident_type] || 0) + 1;
    });
    
    return typeCounts;
  };

  const incidentTypeData = getIncidentTypeData();

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      
      {/* Incident Types Chart */}
      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
            <Activity className="h-4 w-4" />
            <span>Incident Types</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {Object.entries(incidentTypeData).map(([type, count]) => (
              <div key={type} className="flex items-center justify-between p-2 bg-slate-50/50 dark:bg-slate-700/50 rounded-lg">
                <span className="text-xs font-medium text-slate-700 dark:text-slate-300">
                  {type.replace('_', ' ')}
                </span>
                <span className="text-xs text-slate-600 dark:text-slate-400 font-mono">
                  {count}
                </span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Pie Chart with Category Selection */}
      <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
              <PieChart className="h-4 w-4" />
              <span>Distribution Chart</span>
            </CardTitle>
            <Select defaultValue="severity" onValueChange={(value) => setSelectedCategory(value)}>
              <SelectTrigger className="w-32 h-8 text-xs">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="severity">Severity</SelectItem>
                <SelectItem value="actionStatus">Action Status</SelectItem>
                <SelectItem value="environment">Environment</SelectItem>
                <SelectItem value="insident_type">Incident Type</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          <PieChartComponent tickets={tickets} category={selectedCategory} />
        </CardContent>
      </Card>
    </div>
  );
};

// Pie Chart Component
interface PieChartComponentProps {
  tickets: IncidentTicket[];
  category: string;
}

const PieChartComponent: React.FC<PieChartComponentProps> = ({ tickets, category }) => {
  // Get smooth colors for category based on StatisticsOverview colors
  const getColorForCategory = (category: string, value: string) => {
    switch (category) {
      case 'severity':
        switch (value) {
          case 'critical': return '#dc2626'; // red-600 - darker, more sophisticated
          case 'high': return '#ea580c'; // orange-600 - warmer
          case 'medium': return '#d97706'; // amber-600 - golden
          case 'low': return '#16a34a'; // green-600 - deeper green
          default: return '#6b7280'; // gray-500
        }
      case 'actionStatus':
        switch (value) {
          case 'auto': return '#16a34a'; // green-600 - success green
          case 'manual': return '#2563eb'; // blue-600 - professional blue
          case 'pending': return '#d97706'; // amber-600 - warning amber
          default: return '#6b7280'; // gray-500
        }
      case 'environment':
        switch (value) {
          case 'production': return '#dc2626'; // red-600 - danger red
          case 'staging': return '#ea580c'; // orange-600 - warning orange
          case 'development': return '#2563eb'; // blue-600 - info blue
          default: return '#6b7280'; // gray-500
        }
      case 'insident_type':
      default: {
        // Smooth color palette with better contrast
        const incidentTypeColors = [
          '#2563eb', // blue-600
          '#dc2626', // red-600
          '#059669', // emerald-600
          '#d97706', // amber-600
          '#7c3aed', // violet-600
          '#0891b2', // cyan-600
          '#65a30d', // lime-600
          '#ea580c', // orange-600
          '#db2777', // pink-600
          '#4f46e5', // indigo-600
          '#0d9488', // teal-600
          '#ca8a04'  // yellow-600
        ];
        return incidentTypeColors[value.length % incidentTypeColors.length];
      }
    }
  };

  // Calculate data for pie chart
  const getPieData = () => {
    const data: Record<string, number> = {};
    
    tickets.forEach(ticket => {
      let value: string;
      switch (category) {
        case 'severity':
          value = ticket.severity;
          break;
        case 'actionStatus':
          value = ticket.actionStatus;
          break;
        case 'environment':
          value = ticket.environment;
          break;
        case 'insident_type':
          value = ticket.insident_type;
          break;
        default:
          value = ticket.severity;
      }
      data[value] = (data[value] || 0) + 1;
    });
    
    return Object.entries(data).map(([label, value]) => ({
      label,
      value,
      color: getColorForCategory(category, label)
    }));
  };

  const pieData = getPieData();
  const total = pieData.reduce((sum, item) => sum + item.value, 0);

  if (pieData.length === 0) {
    return (
      <div className="h-32 flex items-center justify-center">
        <div className="text-center">
          <PieChart className="h-8 w-8 mx-auto mb-2 text-slate-300 dark:text-slate-600" />
          <p className="text-xs text-slate-500 dark:text-slate-400">
            No data available
          </p>
        </div>
      </div>
    );
  }

  // Calculate pie chart segments
  const radius = 80; // Increased from 60 to 80
  const centerX = 100; // Increased from 80 to 100
  const centerY = 100; // Increased from 80 to 100
  let currentAngle = -Math.PI / 2; // Start from top

  return (
    <div className="flex items-center justify-center space-x-8">
      {/* Pie Chart SVG */}
      <div className="relative">
        <svg width="200" height="200" className="transform -rotate-90">
          <defs>
            {/* Create gradients for each segment */}
            {pieData.map((item, index) => (
              <linearGradient key={`gradient-${index}`} id={`pieGradient-${index}`} x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor={item.color} stopOpacity="0.9" />
                <stop offset="50%" stopColor={item.color} stopOpacity="0.7" />
                <stop offset="100%" stopColor={item.color} stopOpacity="0.5" />
              </linearGradient>
            ))}
          </defs>
          {pieData.map((item, index) => {
            const percentage = item.value / total;
            const angle = percentage * 2 * Math.PI;
            const endAngle = currentAngle + angle;
            
            const x1 = centerX + radius * Math.cos(currentAngle);
            const y1 = centerY + radius * Math.sin(currentAngle);
            const x2 = centerX + radius * Math.cos(endAngle);
            const y2 = centerY + radius * Math.sin(endAngle);
            
            const largeArcFlag = angle > Math.PI ? 1 : 0;
            
            const pathData = [
              `M ${centerX} ${centerY}`,
              `L ${x1} ${y1}`,
              `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2}`,
              'Z'
            ].join(' ');
            
            currentAngle = endAngle;
            
            return (
              <path
                key={index}
                d={pathData}
                fill={`url(#pieGradient-${index})`}
                stroke="white"
                strokeWidth="1.5"
                className="transition-all duration-500 hover:opacity-90 hover:scale-105"
                style={{
                  filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))'
                }}
              />
            );
          })}
        </svg>
        
        {/* Center text */}
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center bg-white/80 dark:bg-slate-800/80 rounded-full p-2 shadow-lg backdrop-blur-sm">
            <div className="text-sm font-bold text-slate-900 dark:text-white">
              {total}
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400 font-medium">
              Total
            </div>
          </div>
        </div>
      </div>
      
      {/* Legend */}
      <div className="space-y-2">
        {pieData.map((item, index) => (
          <div key={index} className="flex items-center space-x-2 p-1 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors duration-200">
            <div 
              className="w-3 h-3 rounded-full shadow-sm"
              style={{ 
                backgroundColor: item.color,
                boxShadow: `0 1px 3px ${item.color}40`
              }}
            />
            <span className="text-xs font-medium text-slate-700 dark:text-slate-300 capitalize">
              {item.label.replace(/_/g, ' ')}
            </span>
            <span className="text-xs text-slate-500 dark:text-slate-400 font-mono">
              ({Math.round((item.value / total) * 100)}%)
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}; 