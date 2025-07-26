# Dashboard Components

This directory contains the modularized dashboard components following React best practices for component organization and maintainability. The dashboard now focuses on analytics and graphs, while incident management has been moved to a separate page.

## Structure

```
dashboard/
├── components/           # Reusable dashboard components
│   ├── DashboardHeader.tsx
│   ├── KeyMetrics.tsx
│   ├── StatisticsOverview.tsx
│   ├── Filters.tsx
│   ├── IncidentsList.tsx
│   ├── IncidentDetailDialog.tsx
│   └── index.ts         # Component exports
├── hooks/               # Custom hooks for dashboard logic
│   └── useDashboard.ts
├── types.ts            # Dashboard-specific type definitions
└── README.md           # This file
```

## Components

### DashboardHeader
Displays the dashboard title, description, and summary badges showing total incidents and critical count.

### KeyMetrics
Shows the four key metric cards:
- Total Incidents
- Pending Actions
- Kubernetes Issues
- Open Incidents

### StatisticsOverview
Displays three statistical breakdown cards:
- Severity Breakdown (Critical, High, Medium, Low)
- Action Status (Auto-Healing, Manual, Pending)
- Environment (Production, Staging, Development)

### DashboardGraphs
Displays four interactive charts:
- Severity Distribution (pie chart style)
- Category Distribution (bar chart style)
- Incident Types breakdown
- Last 7 Days Trend (time series chart)

### AdvancedDashboardGraphs
Advanced chart component with:
- Year selection dropdown (2024, 2025)
- Four tabs for different categories:
  - Incident Type
  - Severity
  - Environment
  - Action Status
- 12-month area charts showing trends
- Interactive legends and tooltips
- Summary statistics
- Responsive design with Recharts

### Filters
Provides comprehensive filtering capabilities:
- Search functionality
- Severity filter
- Category filter
- Incident Type filter
- Environment filter
- Action Status filter
- Status filter
- Clear filters functionality

### IncidentsList
Renders the list of incidents with:
- Incident cards with metadata
- Hover effects and interactions
- Action taken sections
- Affected services display
- Empty state handling

### IncidentDetailDialog
Modal dialog for detailed incident view with:
- Full incident information
- AI suggestions
- Action taken details
- Affected services
- Tags and metadata

## Hooks

### useDashboard
Custom hook that manages all dashboard state and logic:
- Ticket data management from DynamoDB
- Loading states
- Error handling with fallback to mock data

### useIncidents
Custom hook for the incidents page that manages:
- Ticket data management from DynamoDB
- Filtering logic
- Dialog state management
- Loading states

## Types

Defines TypeScript interfaces for:
- Dashboard statistics
- Filter state
- Component props
- Data structures

## Benefits of This Structure

1. **Single Responsibility Principle**: Each component has one clear purpose
2. **Reusability**: Components can be easily reused in other parts of the application
3. **Maintainability**: Changes to one component don't affect others
4. **Testability**: Each component can be tested in isolation
5. **Readability**: Code is easier to understand and navigate
6. **Scalability**: Easy to add new features or modify existing ones

## Usage

The main Dashboard component (`./Dashboard.tsx`) imports and composes these components:

```tsx
import {
  DashboardHeader,
  KeyMetrics,
  StatisticsOverview,
  DashboardGraphs
} from './components';
import { useDashboard } from './hooks/useDashboard';
```

The Incidents page (`../Incidents.tsx`) uses:

```tsx
import {
  Filters,
  IncidentsList,
  IncidentDetailDialog
} from './dashboard/components';
import { useIncidents } from './dashboard/hooks/useIncidents';
```

This follows the [React component splitting best practices](https://thiraphat-ps-dev.medium.com/splitting-components-in-react-a-path-to-cleaner-and-more-maintainable-code-f0828eca627c) for creating cleaner, more maintainable code. 