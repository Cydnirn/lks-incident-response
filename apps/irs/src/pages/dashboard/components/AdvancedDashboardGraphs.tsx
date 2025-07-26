import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../../components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { XAxis, YAxis, ResponsiveContainer, Area, AreaChart, CartesianGrid, Tooltip } from 'recharts';
import { TrendingUp, Calendar, AlertTriangle, Server, Settings } from 'lucide-react';
import type { IncidentTicket } from '../../../types/ticket';

interface AdvancedDashboardGraphsProps {
  tickets: IncidentTicket[];
}

interface MonthlyData {
  month: string;
  total: number;
  [key: string]: string | number;
}

const AdvancedDashboardGraphs: React.FC<AdvancedDashboardGraphsProps> = ({ tickets }) => {
  const [selectedYear, setSelectedYear] = useState<string>('2025');
  const [activeTab, setActiveTab] = useState<string>('incident-type');

  // Get available years from data
  const availableYears = useMemo(() => {
    const years = new Set<string>();
    tickets.forEach(ticket => {
      const year = new Date(ticket.createdAt).getFullYear().toString();
      years.add(year);
    });
    return Array.from(years).sort((a, b) => parseInt(b) - parseInt(a));
  }, [tickets]);

  // Filter tickets by selected year
  const filteredTickets = useMemo(() => {
    return tickets.filter(ticket => {
      const ticketYear = new Date(ticket.createdAt).getFullYear().toString();
      return ticketYear === selectedYear;
    });
  }, [tickets, selectedYear]);

  // Generate monthly data for the selected year
  const generateMonthlyData = (getValue: (ticket: IncidentTicket) => string) => {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // Get all unique values for this category
    const uniqueValues = getUniqueValues(getValue);

    const monthlyData: MonthlyData[] = months.map(month => {
      const data: MonthlyData = {
        month,
        total: 0
      };
      
      // Initialize all category values to 0
      uniqueValues.forEach(value => {
        data[value] = 0;
      });
      
      return data;
    });

    // Count incidents by month and category
    filteredTickets.forEach(ticket => {
      const monthIndex = new Date(ticket.createdAt).getMonth();
      const categoryValue = getValue(ticket);
      
      if (monthIndex >= 0 && monthIndex < 12) {
        monthlyData[monthIndex][categoryValue] = (monthlyData[monthIndex][categoryValue] as number) + 1;
        monthlyData[monthIndex].total += 1;
      }
    });

    return monthlyData;
  };

  // Get unique values for each category
  const getUniqueValues = (getValue: (ticket: IncidentTicket) => string) => {
    const values = new Set<string>();
    filteredTickets.forEach(ticket => {
      values.add(getValue(ticket));
    });
    return Array.from(values);
  };

  // Get unique values for current tab
  const uniqueValues = useMemo(() => {
    switch (activeTab) {
      case 'incident-type':
        return getUniqueValues(ticket => ticket.insident_type);
      case 'severity':
        return getUniqueValues(ticket => ticket.severity);
      case 'environment':
        return getUniqueValues(ticket => ticket.environment);
      case 'action-status':
        return getUniqueValues(ticket => ticket.actionStatus);
      default:
        return getUniqueValues(ticket => ticket.insident_type);
    }
  }, [filteredTickets, activeTab]);

  // Generate chart data based on active tab
  const chartData = useMemo(() => {
    const data = (() => {
      switch (activeTab) {
        case 'incident-type':
          return generateMonthlyData(ticket => ticket.insident_type);
        case 'severity':
          return generateMonthlyData(ticket => ticket.severity);
        case 'environment':
          return generateMonthlyData(ticket => ticket.environment);
        case 'action-status':
          return generateMonthlyData(ticket => ticket.actionStatus);
        default:
          return generateMonthlyData(ticket => ticket.insident_type);
      }
    })();
    

    
    return data;
  }, [filteredTickets, activeTab, selectedYear, uniqueValues]);

  // Color palette based on StatisticsOverview colors
  const getColorForCategory = (category: string, value: string) => {
    const incidentTypeColors = [
      '#3b82f6', '#ef4444', '#10b981', '#f59e0b', 
      '#8b5cf6', '#06b6d4', '#84cc16', '#f97316',
      '#ec4899', '#6366f1', '#14b8a6', '#fbbf24'
    ];

    switch (category) {
      case 'severity':
        switch (value) {
          case 'critical': return '#ef4444'; // red-500
          case 'high': return '#f97316'; // orange-500
          case 'medium': return '#eab308'; // yellow-500
          case 'low': return '#22c55e'; // green-500
          default: return '#6b7280'; // gray-500
        }
      case 'action-status':
        switch (value) {
          case 'auto': return '#22c55e'; // green-500
          case 'manual': return '#3b82f6'; // blue-500
          case 'pending': return '#eab308'; // yellow-500
          default: return '#6b7280'; // gray-500
        }
      case 'environment':
        switch (value) {
          case 'production': return '#ef4444'; // red-500
          case 'staging': return '#f97316'; // orange-500
          case 'development': return '#3b82f6'; // blue-500
          default: return '#6b7280'; // gray-500
        }
      case 'incident-type':
      default:
        // For incident types, use a broader color palette
        return incidentTypeColors[value.length % incidentTypeColors.length];
    }
  };



  // Get tab title
  const getTabTitle = () => {
    switch (activeTab) {
      case 'incident-type':
        return 'Incident Type';
      case 'severity':
        return 'Severity';
      case 'environment':
        return 'Environment';
      case 'action-status':
        return 'Action Status';
      default:
        return 'Incident Type';
    }
  };

  // Get tab icon
  const getTabIcon = () => {
    switch (activeTab) {
      case 'incident-type':
        return <AlertTriangle className="h-4 w-4" />;
      case 'severity':
        return <TrendingUp className="h-4 w-4" />;
      case 'environment':
        return <Server className="h-4 w-4" />;
      case 'action-status':
        return <Settings className="h-4 w-4" />;
      default:
        return <AlertTriangle className="h-4 w-4" />;
    }
  };

  return (
    <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
      <CardHeader className="pb-3">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
          <CardTitle className="flex items-center space-x-2 text-sm font-semibold text-slate-900 dark:text-white">
            {getTabIcon()}
            <span>Total {getTabTitle()} - {selectedYear}</span>
          </CardTitle>
          
          {/* Year Selection */}
          <div className="flex items-center space-x-2">
            <Calendar className="h-4 w-4 text-slate-500" />
            <Select value={selectedYear} onValueChange={setSelectedYear}>
              <SelectTrigger className="w-24 h-8 text-xs">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {availableYears.map(year => (
                  <SelectItem key={year} value={year}>
                    {year}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardHeader>
      
      <CardContent>
        {/* Tabs */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="inline-flex h-10 items-center justify-center rounded-md bg-amber-50/50 p-1 text-slate-500 dark:bg-slate-700 dark:text-slate-400">
            <TabsTrigger 
              value="incident-type" 
              className="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-600 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-white data-[state=active]:text-amber-700 data-[state=active]:shadow-sm dark:ring-offset-slate-950 dark:focus-visible:ring-amber-400 dark:data-[state=active]:bg-amber-100/80 dark:data-[state=active]:text-amber-900"
            >
              Incident Type
            </TabsTrigger>
            <TabsTrigger 
              value="severity" 
              className="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-600 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-white data-[state=active]:text-amber-700 data-[state=active]:shadow-sm dark:ring-offset-slate-950 dark:focus-visible:ring-amber-400 dark:data-[state=active]:bg-amber-100/80 dark:data-[state=active]:text-amber-900"
            >
              Severity
            </TabsTrigger>
            <TabsTrigger 
              value="environment" 
              className="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-600 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-white data-[state=active]:text-amber-700 data-[state=active]:shadow-sm dark:ring-offset-slate-950 dark:focus-visible:ring-amber-400 dark:data-[state=active]:bg-amber-100/80 dark:data-[state=active]:text-amber-900"
            >
              Environment
            </TabsTrigger>
            <TabsTrigger 
              value="action-status" 
              className="inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-white transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-600 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-white data-[state=active]:text-amber-700 data-[state=active]:shadow-sm dark:ring-offset-slate-950 dark:focus-visible:ring-amber-400 dark:data-[state=active]:bg-amber-100/80 dark:data-[state=active]:text-amber-900"
            >
              Action Status
            </TabsTrigger>
          </TabsList>
          
          <TabsContent value={activeTab} className="mt-4">
            {filteredTickets.length > 0 ? (
              <div className="space-y-4">
                {/* Main Chart */}
                <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={chartData} margin={{ top: 10, right: 10, left: 10, bottom: 10 }}>
                      <defs>
                        {uniqueValues.map((value) => {
                          const baseColor = getColorForCategory(activeTab, value);
                          return (
                            <linearGradient key={`gradient-${value}`} id={`fill${value}`} x1="0" y1="0" x2="0" y2="1">
                              <stop
                                offset="0%"
                                stopColor={baseColor}
                                stopOpacity={0.9}
                              />
                              <stop
                                offset="50%"
                                stopColor={baseColor}
                                stopOpacity={0.6}
                              />
                              <stop
                                offset="100%"
                                stopColor={baseColor}
                                stopOpacity={0.1}
                              />
                            </linearGradient>
                          );
                        })}
                      </defs>
                      <CartesianGrid strokeDasharray="0" stroke="#64748b" strokeOpacity={0.2} horizontal={true} vertical={false} />
                      <XAxis 
                        dataKey="month" 
                        stroke="#64748b"
                        fontSize={12}
                        axisLine={false}
                        tickLine={false}
                      />
                      <YAxis 
                        stroke="#64748b"
                        fontSize={12}
                        axisLine={false}
                        tickLine={false}
                      />
                      <Tooltip 
                        contentStyle={{
                          backgroundColor: 'white',
                          border: '1px solid #e2e8f0',
                          borderRadius: '8px',
                          fontSize: '12px',
                          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
                        }}
                        labelStyle={{
                          fontWeight: 'bold',
                          color: '#374151'
                        }}
                      />
                      
                      {/* Render areas with gradient fills */}
                      {uniqueValues.map((value, index) => {
                        const baseColor = getColorForCategory(activeTab, value);
                        return (
                          <Area
                            key={value}
                            type="monotone"
                            dataKey={value}
                            stackId="1"
                            stroke={baseColor}
                            fill={`url(#fill${value})`}
                            strokeWidth={1}
                            strokeOpacity={1}
                            animationDuration={1000}
                            animationBegin={index * 200}
                          />
                        );
                      })}
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
                
                {/* Legend */}
                <div className="flex flex-wrap gap-3 justify-center mt-4">
                  {uniqueValues.map((value) => (
                    <div key={value} className="flex items-center space-x-2 px-3 py-1 bg-slate-50 dark:bg-slate-800 rounded-lg">
                      <div 
                        className="w-3 h-3 rounded-full shadow-sm"
                        style={{ backgroundColor: getColorForCategory(activeTab, value) }}
                      />
                      <span className="text-xs font-medium text-slate-700 dark:text-slate-300 capitalize">
                        {value.replace(/_/g, ' ').toLowerCase()}
                      </span>
                    </div>
                  ))}
                </div>
                
                {/* Summary Stats */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-center">
                  <div className="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-2">
                    <div className="text-lg font-semibold text-slate-900 dark:text-white">
                      {filteredTickets.length}
                    </div>
                    <div className="text-xs text-slate-500 dark:text-slate-400">Total Incidents</div>
                  </div>
                  <div className="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-2">
                    <div className="text-lg font-semibold text-slate-900 dark:text-white">
                      {uniqueValues.length}
                    </div>
                    <div className="text-xs text-slate-500 dark:text-slate-400">Categories</div>
                  </div>
                  <div className="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-2">
                    <div className="text-lg font-semibold text-slate-900 dark:text-white">
                      {Math.max(...chartData.map(d => d.total))}
                    </div>
                    <div className="text-xs text-slate-500 dark:text-slate-400">Peak Month</div>
                  </div>
                  <div className="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-2">
                    <div className="text-lg font-semibold text-slate-900 dark:text-white">
                      {Math.round(filteredTickets.length / 12)}
                    </div>
                    <div className="text-xs text-slate-500 dark:text-slate-400">Avg/Month</div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="h-64 flex items-center justify-center">
                <div className="text-center">
                  <TrendingUp className="h-12 w-12 mx-auto mb-3 text-slate-300 dark:text-slate-600" />
                  <p className="text-sm text-slate-500 dark:text-slate-400">
                    No incidents data for {selectedYear}
                  </p>
                  <p className="text-xs text-slate-400 dark:text-slate-500 mt-1">
                    Available years: {availableYears.join(', ')}
                  </p>
                </div>
              </div>
            )}
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
};

export default AdvancedDashboardGraphs; 