# DevOps Incident Response Recap Dashboard

A modern read-only web application specifically designed for monitoring and tracking DevOps incident response workflows, built with React, TypeScript, Tailwind CSS, and shadcn/ui components.

## Tech Stack

- **Frontend**: React 18 + TypeScript
- **Build Tool**: Vite
- **Routing**: React Router v7
- **Styling**: Tailwind CSS
- **UI Components**: shadcn/ui
- **Icons**: Lucide React
- **Backend**: AWS DynamoDB
- **State Management**: React Hooks

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   cd apps/ticket
   ```

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Set up environment variables**
   
   Create a `.env` file in the root directory:
   ```env
   VITE_API_BASE_URL=http://your_be_service
   ```

   **Attention:** The environment will not function outside of the build phase, except in development mode.

4. **Start the development server**
   ```bash
   npm run dev
   ```

5. **Open your browser**
   
   Navigate to `http://localhost:5173`

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript type checking

### Docker Deployment
```sh
docker build \
  --platform=linux/amd64 \
  --no-cache \
  -t lks/irsfe \
  -f docker/Dockerfile \
  .
```
**Note:** Run in root folder of IRS or apps/irs

### Incident Response Workflow

1. **Incident Detection**: Incident response system detects and creates incident report
2. **AI Analysis**: System generates suggestions for handling the incident
3. **Action Type Assignment**: System determines if auto-healing is possible or manual intervention needed
4. **Email Notification**: DevOps engineer receives approval request email
5. **Approval Process**: DevOps engineer approves auto-healing or requests manual intervention
6. **Resolution**: Auto-healing executes or manual intervention is performed
7. **Status Update**: Incident status updated in DynamoDB

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.
