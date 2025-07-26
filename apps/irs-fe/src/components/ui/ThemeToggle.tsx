import React from 'react';
import { Moon, Sun } from 'lucide-react';
import { useTheme } from '../../contexts/ThemeContext';

const ThemeToggle: React.FC = () => {
  const { isDarkMode, toggleDarkMode } = useTheme();

  return (
    <button
      onClick={toggleDarkMode}
      className="relative inline-flex h-7 w-14 items-center rounded-full bg-slate-200 dark:bg-slate-700 p-1 transition-all duration-300 ease-in-out hover:scale-105 focus:outline-none focus:ring-2 focus:ring-amber-500/50"
      aria-label="Toggle dark mode"
    >
      <div
        className={`flex h-5 w-5 items-center justify-center rounded-full bg-white dark:bg-slate-900 shadow-md transition-all duration-300 ease-in-out ${
          isDarkMode ? 'translate-x-7' : 'translate-x-0'
        }`}
      >
        {isDarkMode ? (
          <Moon className="h-2.5 w-2.5 text-slate-600 dark:text-slate-300 transition-colors duration-300" />
        ) : (
          <Sun className="h-2.5 w-2.5 text-amber-600 transition-colors duration-300" />
        )}
      </div>
    </button>
  );
};

export default ThemeToggle; 