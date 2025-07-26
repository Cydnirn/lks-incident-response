import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { 
  Filter,
  Search,
  ChevronDown,
  ChevronUp
} from 'lucide-react';
import type { FiltersProps } from '../../dashboard/types';

const Filters: React.FC<FiltersProps> = ({ filterState, onFilterChange, onClearFilters }) => {
  const [isFilterCollapsed, setIsFilterCollapsed] = useState(false);

  const hasActiveFilters = Object.values(filterState).some(value => value !== '');

  return (
    <Card className="bg-white/80 dark:bg-slate-800/80 border-slate-200/50 dark:border-slate-700/50 shadow-sm hover:shadow-md transition-all duration-300 backdrop-blur-sm">
      <CardHeader className="pb-3">
        <CardTitle 
          className="flex items-center justify-between text-sm font-semibold text-slate-900 dark:text-white cursor-pointer"
          onClick={() => setIsFilterCollapsed(!isFilterCollapsed)}
        >
          <div className="flex items-center space-x-2">
            <Filter className="h-4 w-4" />
            <span>Filters</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-xs text-slate-500 dark:text-slate-400">
              {hasActiveFilters ? 'Active' : 'Inactive'}
            </span>
            {isFilterCollapsed ? (
              <ChevronDown className="h-4 w-4 text-slate-500 dark:text-slate-400 transition-transform duration-200" />
            ) : (
              <ChevronUp className="h-4 w-4 text-slate-500 dark:text-slate-400 transition-transform duration-200" />
            )}
          </div>
        </CardTitle>
      </CardHeader>
      
      {!isFilterCollapsed && (
        <CardContent className="space-y-3">
          {/* Row 1: Search */}
          <div className="relative">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search incidents..."
              value={filterState.searchTerm}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => onFilterChange('searchTerm', e.target.value)}
              className="w-full pl-10 pr-3 py-2 border border-slate-200/50 dark:border-slate-600/50 rounded-lg focus:ring-2 focus:ring-amber-500/50 focus:border-transparent bg-white/50 dark:bg-slate-700/50 text-sm text-slate-900 dark:text-white placeholder-slate-500 dark:placeholder-slate-400 backdrop-blur-sm transition-all duration-200"
            />
          </div>
          
          {/* Row 2: Filters and Button */}
          <div className="grid grid-cols-2 sm:flex sm:items-center gap-2">
            <select
              value={filterState.selectedSeverity}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => onFilterChange('selectedSeverity', e.target.value)}
              className="w-full sm:flex-1 px-2 py-1.5 border border-slate-200/50 dark:border-slate-600/50 rounded-lg focus:ring-2 focus:ring-amber-500/50 focus:border-transparent bg-white/50 dark:bg-slate-700/50 text-xs text-slate-900 dark:text-white backdrop-blur-sm transition-all duration-200"
            >
              <option value="">All Severities</option>
              <option value="critical">Critical</option>
              <option value="high">High</option>
              <option value="medium">Medium</option>
              <option value="low">Low</option>
            </select>

            <select
              value={filterState.selectedCategory}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => onFilterChange('selectedCategory', e.target.value)}
              className="w-full sm:flex-1 px-2 py-1.5 border border-slate-200/50 dark:border-slate-600/50 rounded-lg focus:ring-2 focus:ring-amber-500/50 focus:border-transparent bg-white/50 dark:bg-slate-700/50 text-xs text-slate-900 dark:text-white backdrop-blur-sm transition-all duration-200"
            >
              <option value="">All Categories</option>
              <option value="kubernetes">Kubernetes</option>
              <option value="infrastructure">Infrastructure</option>
              <option value="ci-cd">CI/CD</option>
              <option value="other">Other</option>
            </select>

            <select
              value={filterState.selectedIncidentType}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => onFilterChange('selectedIncidentType', e.target.value)}
              className="w-full sm:flex-1 px-2 py-1.5 border border-slate-200/50 dark:border-slate-600/50 rounded-lg focus:ring-2 focus:ring-amber-500/50 focus:border-transparent bg-white/50 dark:bg-slate-700/50 text-xs text-slate-900 dark:text-white backdrop-blur-sm transition-all duration-200"
            >
              <option value="">All Incident Types</option>
              <option value="CPU_HIGH">CPU High</option>
              <option value="MEM_HIGH">Memory High</option>
              <option value="POD_CRASH">Pod Crash</option>
              <option value="IMAGE_PULL">Image Pull Error</option>
              <option value="UNHEALTHY_POD">Unhealthy Pod</option>
              <option value="APP_ERROR">App Error</option>
              <option value="OTHER">Other</option>
            </select>

            <select
              value={filterState.selectedEnvironment}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => onFilterChange('selectedEnvironment', e.target.value)}
              className="w-full sm:flex-1 px-2 py-1.5 border border-slate-200/50 dark:border-slate-600/50 rounded-lg focus:ring-2 focus:ring-amber-500/50 focus:border-transparent bg-white/50 dark:bg-slate-700/50 text-xs text-slate-900 dark:text-white backdrop-blur-sm transition-all duration-200"
            >
              <option value="">All Environments</option>
              <option value="production">Production</option>
              <option value="staging">Staging</option>
              <option value="development">Development</option>
            </select>

            <select
              value={filterState.selectedActionStatus}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => onFilterChange('selectedActionStatus', e.target.value)}
              className="w-full sm:flex-1 px-2 py-1.5 border border-slate-200/50 dark:border-slate-600/50 rounded-lg focus:ring-2 focus:ring-amber-500/50 focus:border-transparent bg-white/50 dark:bg-slate-700/50 text-xs text-slate-900 dark:text-white backdrop-blur-sm transition-all duration-200"
            >
              <option value="">All Actions</option>
              <option value="auto">Auto-Healing</option>
              <option value="manual">Manual</option>
              <option value="pending">Pending</option>
            </select>

            <select
              value={filterState.selectedStatus}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => onFilterChange('selectedStatus', e.target.value)}
              className="w-full sm:flex-1 px-2 py-1.5 border border-slate-200/50 dark:border-slate-600/50 rounded-lg focus:ring-2 focus:ring-amber-500/50 focus:border-transparent bg-white/50 dark:bg-slate-700/50 text-xs text-slate-900 dark:text-white backdrop-blur-sm transition-all duration-200"
            >
              <option value="">All Statuses</option>
              <option value="open">Open</option>
              <option value="in-progress">In Progress</option>
              <option value="solved">Solved</option>
              <option value="closed">Closed</option>
              <option value="pending">Pending</option>
            </select>

            <Button 
              variant="outline" 
              onClick={onClearFilters} 
              size="sm" 
              className="col-span-2 sm:col-span-1 px-3 py-1.5 border-slate-200/50 dark:border-slate-600/50 text-slate-700 dark:text-slate-300 hover:bg-slate-100/50 dark:hover:bg-slate-700/50 text-xs transition-all duration-200 whitespace-nowrap"
            >
              Clear
            </Button>
          </div>
        </CardContent>
      )}
    </Card>
  );
};

export default Filters; 