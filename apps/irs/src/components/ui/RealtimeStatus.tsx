import React from 'react';
// import { Badge } from './badge';
import { RefreshCw } from 'lucide-react';

interface RealtimeStatusProps {
  lastUpdated: Date | null;
  isRefreshing: boolean;
  error: string | null;
  isInitialized: boolean;
  onRefresh?: () => void;
}

export const RealtimeStatus: React.FC<RealtimeStatusProps> = ({
  lastUpdated,
  isRefreshing,
  error,
  isInitialized,
  onRefresh
}) => {
  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false
    });
  };

  // const getStatusColor = () => {
  //   if (error) return 'destructive';
  //   if (!isInitialized) return 'secondary';
  //   return 'default';
  // };

  // const getStatusIcon = () => {
  //   if (error) return <WifiOff className="w-3 h-3" />;
  //   if (!isInitialized) return <AlertCircle className="w-3 h-3" />;
  //   if (isRefreshing) return <RefreshCw className="w-3 h-3 animate-spin" />;
  //   return <Wifi className="w-3 h-3" />;
  // };

  // const getStatusText = () => {
  //   if (error) return 'Connection Error';
  //   if (!isInitialized) return 'Initializing...';
  //   if (isRefreshing) return 'Refreshing...';
  //   return 'Realtime';
  // };

  return (
    <div className="flex items-center space-x-2 text-xs">
      {/* <Badge variant={getStatusColor()} className="flex items-center space-x-1 px-2 py-1">
        {getStatusIcon()}
        <span>{getStatusText()}</span>
      </Badge> */}
      
      {lastUpdated && isInitialized && !error && (
        <span className="text-slate-500 dark:text-slate-400">
          Last updated: {formatTime(lastUpdated)}
        </span>
      )}
      
      {error && (
        <span className="text-red-500 dark:text-red-400 max-w-xs truncate">
          {error}
        </span>
      )}
      
      {onRefresh && isInitialized && (
        <button
          onClick={onRefresh}
          disabled={isRefreshing}
          className="p-1 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          title="Refresh data"
        >
          <RefreshCw className={`w-3 h-3 ${isRefreshing ? 'animate-spin' : ''}`} />
        </button>
      )}
    </div>
  );
}; 