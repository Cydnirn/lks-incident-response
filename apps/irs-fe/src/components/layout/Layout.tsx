import React from 'react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { AlertTriangle, Home, FileText } from 'lucide-react';
import ThemeToggle from '../ui/ThemeToggle';

const Layout: React.FC = () => {
  const location = useLocation();
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-amber-50/30 to-orange-50/30 dark:from-slate-900 dark:via-slate-800 dark:to-slate-900 transition-all duration-500">
      {/* Header Card */}
      <div className="max-w-7xl mx-auto px-2 sm:px-4 lg:px-8 pt-2 sm:pt-4">
        <div className="bg-white/90 dark:bg-slate-800/90 backdrop-blur-xl shadow-lg border border-slate-200/30 dark:border-slate-700/30 rounded-xl">
          <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center h-auto sm:h-14 px-4 sm:px-6 py-3 sm:py-0 space-y-3 sm:space-y-0">
            <div className="flex items-center">
              <div className="p-1.5 bg-gradient-to-r from-amber-500 to-orange-500 rounded-lg mr-3 shadow-lg">
                <AlertTriangle className="h-5 w-5 text-white" />
              </div>
              <h1 className="text-sm sm:text-base font-bold bg-gradient-to-r from-amber-600 to-orange-600 dark:from-amber-400 dark:to-orange-400 bg-clip-text text-transparent">
               Incident Monitor System
              </h1>
            </div>
            
            <div className="flex items-center justify-between sm:justify-end space-x-2 sm:space-x-4">
              <nav className="flex space-x-2 sm:space-x-4">
                <Link
                  to="/"
                  className={`px-2 sm:px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium flex items-center transition-all duration-200 ${
                    location.pathname === '/' 
                      ? 'text-amber-600 dark:text-amber-400 bg-amber-100/50 dark:bg-amber-900/20' 
                      : 'text-slate-600 dark:text-slate-300 hover:text-amber-600 dark:hover:text-amber-400 hover:bg-slate-100/50 dark:hover:bg-slate-700/50'
                  }`}
                >
                  <Home className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-1.5" />
                  <span className="hidden sm:inline">Dashboard</span>
                  <span className="sm:hidden">Dash</span>
                </Link>
                <Link
                  to="/incidents"
                  className={`px-2 sm:px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium flex items-center transition-all duration-200 ${
                    location.pathname === '/incidents' 
                      ? 'text-amber-600 dark:text-amber-400 bg-amber-100/50 dark:bg-amber-900/20' 
                      : 'text-slate-600 dark:text-slate-300 hover:text-amber-600 dark:hover:text-amber-400 hover:bg-slate-100/50 dark:hover:bg-slate-700/50'
                  }`}
                >
                  <FileText className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-1.5" />
                  <span className="hidden sm:inline">Incidents</span>
                  <span className="sm:hidden">Inc</span>
                </Link>
              </nav>
              
              <div className="flex items-center space-x-2">
                <ThemeToggle />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-2 sm:px-4 lg:px-8 py-4 sm:py-6">
        <Outlet />
      </main>

      {/* Footer Card */}
      <div className="max-w-7xl mx-auto px-2 sm:px-4 lg:px-8 pb-2 sm:pb-4">
        <div className="bg-white/90 dark:bg-slate-800/90 backdrop-blur-xl border border-slate-200/30 dark:border-slate-700/30 rounded-xl">
          <div className="flex justify-center items-center h-10 px-4">
            <p className="text-xs text-slate-600 dark:text-slate-400">
              © 2025 LKS Nasional. All rights reserved.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Layout; 