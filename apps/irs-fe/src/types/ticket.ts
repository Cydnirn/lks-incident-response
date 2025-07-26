export interface IncidentTicket {
  id: string;
  title: string;
  description: string;
  report: string;
  suggestions?: string[];
  severity: 'critical' | 'high' | 'medium' | 'low';
  category: 'kubernetes' | 'infrastructure' | 'ci-cd' | 'other';
  insident_type: 'CPU_HIGH' | 'MEM_HIGH' | 'POD_CRASH' | 'IMAGE_PULL' | 'UNHEALTHY_POD' | 'APP_ERROR' | 'OTHER';
  environment: 'production' | 'staging' | 'development';
  actionStatus: 'auto' | 'manual' | 'pending';
  status: 'open' | 'in-progress' | 'solved' | 'closed' | 'pending';
  reporter: string;
  createdAt: string;
  resolutionTime?: string;
  emailSent: boolean;
  emailSentAt?: string;
  actionTaken?: string;
  affectedServices?: string[];
  tags?: string[];
}

export interface TicketFilters {
  actionStatus?: string;
  severity?: string;
  category?: string;
  environment?: string;
  search?: string;
} 