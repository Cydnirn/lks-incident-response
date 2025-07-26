import React from 'react';
import { Inbox, Database, AlertTriangle } from 'lucide-react';
import { Button } from './button';

interface EmptyStateProps {
  title: string;
  description: string;
  icon?: 'inbox' | 'database' | 'alert';
  action?: {
    label: string;
    onClick: () => void;
  };
  variant?: 'default' | 'error' | 'warning';
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  title,
  description,
  icon = 'inbox',
  action,
  variant = 'default'
}) => {
  const getIcon = () => {
    switch (icon) {
      case 'database':
        return <Database className="w-12 h-12 text-slate-400" />;
      case 'alert':
        return <AlertTriangle className="w-12 h-12 text-amber-500" />;
      default:
        return <Inbox className="w-12 h-12 text-slate-400" />;
    }
  };

  const getVariantStyles = () => {
    switch (variant) {
      case 'error':
        return 'text-red-600 dark:text-red-400';
      case 'warning':
        return 'text-amber-600 dark:text-amber-400';
      default:
        return 'text-slate-600 dark:text-slate-400';
    }
  };

  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div className="mb-4">
        {getIcon()}
      </div>
      
      <h3 className={`text-lg font-semibold mb-2 ${getVariantStyles()}`}>
        {title}
      </h3>
      
      <p className="text-slate-500 dark:text-slate-400 max-w-md mb-6">
        {description}
      </p>
      
      {action && (
        <Button
          onClick={action.onClick}
          variant={variant === 'error' ? 'destructive' : 'default'}
          size="sm"
        >
          {action.label}
        </Button>
      )}
    </div>
  );
}; 