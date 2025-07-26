import { useState, useEffect, useRef, useCallback } from 'react';
import type { IncidentTicket } from '../types/ticket';
import { APIService } from '../services/api';

interface UseRealtimeDataOptions {
  refreshInterval?: number; // in milliseconds
  enableRealtime?: boolean;
}

interface UseRealtimeDataReturn {
  data: IncidentTicket[];
  loading: boolean;
  error: string | null;
  isInitialized: boolean;
  lastUpdated: Date | null;
  refreshData: () => Promise<void>;
  isRefreshing: boolean;
}

export const useRealtimeData = (
  options: UseRealtimeDataOptions = {}
): UseRealtimeDataReturn => {
  const {
    refreshInterval = 3000, // 3 seconds default
    enableRealtime = true
  } = options;

  const [data, setData] = useState<IncidentTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isInitialized, setIsInitialized] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  const fetchData = useCallback(async (isBackgroundRefresh = false) => {
    // Skip if this is a background refresh and we're not initialized yet
    if (isBackgroundRefresh && !isInitialized) {
      return;
    }

    // Cancel previous request if it's still pending
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // Create new abort controller for this request
    abortControllerRef.current = new AbortController();

    try {
      if (isBackgroundRefresh) {
        setIsRefreshing(true);
      } else {
        setLoading(true);
      }

      setError(null);

      const tickets = await APIService.getAllTickets();
      
      // Only update if the request wasn't cancelled
      if (!abortControllerRef.current.signal.aborted) {
        setData(tickets);
        setLastUpdated(new Date());
        
        if (!isInitialized) {
          setIsInitialized(true);
        }
      }
    } catch (err) {
      // Only handle error if the request wasn't cancelled
      if (!abortControllerRef.current.signal.aborted) {
        console.error('Error fetching tickets:', err);
        
        // Set error message only on initial load
        if (!isInitialized) {
          setError('Failed to load data from API');
        } else {
          // For background refreshes, don't show error to user
          // Just log it for debugging
          console.warn('Background refresh failed:', err);
        }
      }
    } finally {
      if (!abortControllerRef.current.signal.aborted) {
        if (isBackgroundRefresh) {
          setIsRefreshing(false);
        } else {
          setLoading(false);
        }
      }
    }
  }, [isInitialized]);

  // Initial data fetch
  useEffect(() => {
    fetchData(false);
  }, [fetchData]);

  // Setup real-time refresh
  useEffect(() => {
    if (!enableRealtime || !isInitialized) {
      return;
    }

    const startInterval = () => {
      intervalRef.current = setInterval(() => {
        fetchData(true); // Background refresh
      }, refreshInterval);
    };

    const stopInterval = () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };

    // Start interval after initial load
    if (isInitialized) {
      startInterval();
    }

    // Cleanup on unmount or when dependencies change
    return () => {
      stopInterval();
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
    };
  }, [enableRealtime, isInitialized, refreshInterval, fetchData]);

  // Manual refresh function
  const refreshData = useCallback(async () => {
    await fetchData(false);
  }, [fetchData]);

  return {
    data,
    loading,
    error,
    isInitialized,
    lastUpdated,
    refreshData,
    isRefreshing
  };
}; 