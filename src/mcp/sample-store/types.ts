// src/mcp/sample-store/types.ts

export interface SampleInfo {
  task_id: string;
  package_name: string;
  version: string;
  signature: {
    issuer: string;
    subject: string;
    valid_from: string;
    valid_to: string;
  };
  file_size: number;
  created_at: string;
}

export interface CodeTreeNode {
  name: string;
  path: string;
  type: 'file' | 'directory';
  children?: CodeTreeNode[];
}

export interface StaticReport {
  permissions: string[];
  apis: string[];
  components: string[];
  risks: RiskItem[];
}

export interface DynamicReport {
  behaviors: BehaviorItem[];
  file_operations: FileOperation[];
  network_requests: NetworkRequest[];
}

export interface TrafficReport {
  domains: string[];
  endpoints: string[];
  protocols: string[];
  suspicious_activity: string[];
}

export interface RiskItem {
  id: string;
  level: 'high' | 'medium' | 'low';
  category: string;
  description: string;
  evidence?: string;
}

export interface BehaviorItem {
  timestamp: string;
  action: string;
  details: string;
}

export interface FileOperation {
  timestamp: string;
  path: string;
  operation: 'read' | 'write' | 'delete';
}

export interface NetworkRequest {
  timestamp: string;
  url: string;
  method: string;
  headers?: Record<string, string>;
}
