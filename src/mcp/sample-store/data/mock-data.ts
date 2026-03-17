// src/mcp/sample-store/data/mock-data.ts

import type { SampleInfo, CodeTreeNode, StaticReport, DynamicReport, TrafficReport } from '../types.js';

export const mockSampleInfo: SampleInfo = {
  task_id: 'TASK-001',
  package_name: 'com.example.malicious.app',
  version: '1.0.0',
  signature: {
    issuer: 'CN=Example CA',
    subject: 'CN=Example Developer',
    valid_from: '2024-01-01T00:00:00Z',
    valid_to: '2025-01-01T00:00:00Z',
  },
  file_size: 5242880,
  created_at: '2024-03-15T10:30:00Z',
};

export const mockCodeTree: CodeTreeNode = {
  name: 'src',
  path: 'src',
  type: 'directory',
  children: [
    {
      name: 'ets',
      path: 'src/ets',
      type: 'directory',
      children: [
        {
          name: 'entryability',
          path: 'src/ets/entryability',
          type: 'directory',
          children: [
            { name: 'EntryAbility.ets', path: 'src/ets/entryability/EntryAbility.ets', type: 'file' },
          ],
        },
        {
          name: 'pages',
          path: 'src/ets/pages',
          type: 'directory',
          children: [
            { name: 'Index.ets', path: 'src/ets/pages/Index.ets', type: 'file' },
          ],
        },
        {
          name: 'utils',
          path: 'src/ets/utils',
          type: 'directory',
          children: [
            { name: 'CryptoUtil.ets', path: 'src/ets/utils/CryptoUtil.ets', type: 'file' },
            { name: 'NetworkUtil.ets', path: 'src/ets/utils/NetworkUtil.ets', type: 'file' },
          ],
        },
      ],
    },
  ],
};

export const mockStaticReport: StaticReport = {
  permissions: [
    'ohos.permission.INTERNET',
    'ohos.permission.READ_CONTACTS',
    'ohos.permission.WRITE_CONTACTS',
    'ohos.permission.READ_SMS',
    'ohos.permission.WRITE_SMS',
  ],
  apis: [
    '@ohos.telephony.sms',
    '@ohos.contacts',
    '@ohos.net.http',
  ],
  components: [
    'EntryAbility',
    'MainPage',
  ],
  risks: [
    {
      id: 'R001',
      level: 'high',
      category: '权限滥用',
      description: '申请了敏感的短信和联系人权限',
      evidence: 'module.json5 中声明了 ohos.permission.READ_SMS',
    },
  ],
};

export const mockDynamicReport: DynamicReport = {
  behaviors: [
    { timestamp: '2024-03-15T10:31:00Z', action: 'send_sms', details: '发送短信到 13800138000' },
    { timestamp: '2024-03-15T10:31:05Z', action: 'read_contacts', details: '读取联系人列表' },
  ],
  file_operations: [
    { timestamp: '2024-03-15T10:30:30Z', path: '/data/storage/el2/database', operation: 'read' },
  ],
  network_requests: [
    { timestamp: '2024-03-15T10:32:00Z', url: 'https://suspicious-domain.com/api/collect', method: 'POST' },
  ],
};

export const mockTrafficReport: TrafficReport = {
  domains: ['suspicious-domain.com', 'tracker.example.com'],
  endpoints: ['/api/collect', '/api/report'],
  protocols: ['https', 'http'],
  suspicious_activity: [
    '向未知域名发送数据',
    '使用非标准端口通信',
  ],
};
