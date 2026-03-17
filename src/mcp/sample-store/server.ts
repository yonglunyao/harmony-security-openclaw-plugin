import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import {
  mockSampleInfo,
  mockCodeTree,
  mockStaticReport,
  mockDynamicReport,
  mockTrafficReport,
} from './data/mock-data.js';

export class SampleStoreServer {
  private server: Server;

  constructor() {
    this.server = new Server(
      {
        name: 'sample-store',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // List tools
    this.server.setRequestHandler(
      ListToolsRequestSchema,
      async () => {
        return {
          tools: [
            {
              name: 'get_sample_info',
              description: '根据任务ID获取样本基本信息（包名、版本、签名等）',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                },
                required: ['task_id'],
              },
            },
            {
              name: 'get_code_tree',
              description: '获取逆向JS代码的目录树结构',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                },
                required: ['task_id'],
              },
            },
            {
              name: 'get_code_file',
              description: '读取指定代码文件内容',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                  file_path: {
                    type: 'string',
                    description: '文件相对路径',
                  },
                },
                required: ['task_id', 'file_path'],
              },
            },
            {
              name: 'get_static_report',
              description: '获取静态扫描报告',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                },
                required: ['task_id'],
              },
            },
            {
              name: 'get_dynamic_report',
              description: '获取动态沙箱报告',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                },
                required: ['task_id'],
              },
            },
            {
              name: 'get_traffic_report',
              description: '获取流量分析报告',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                },
                required: ['task_id'],
              },
            },
          ],
        };
      }
    );

    // Call tools
    this.server.setRequestHandler(
      CallToolRequestSchema,
      async (request) => {
        const { name, arguments: args } = request.params;

        try {
          switch (name) {
            case 'get_sample_info':
              return await this.getSampleInfo(args?.task_id as string);
            case 'get_code_tree':
              return await this.getCodeTree(args?.task_id as string);
            case 'get_code_file':
              return await this.getCodeFile(
                args?.task_id as string,
                args?.file_path as string
              );
            case 'get_static_report':
              return await this.getStaticReport(args?.task_id as string);
            case 'get_dynamic_report':
              return await this.getDynamicReport(args?.task_id as string);
            case 'get_traffic_report':
              return await this.getTrafficReport(args?.task_id as string);
            default:
              return {
                content: [
                  {
                    type: 'text',
                    text: `Unknown tool: ${name}`,
                    isError: true,
                  },
                ],
              };
          }
        } catch (error) {
          return {
            content: [
              {
                type: 'text',
                text: `Error: ${error instanceof Error ? error.message : String(error)}`,
                isError: true,
              },
            ],
          };
        }
      }
    );
  }

  async getSampleInfo(taskId: string): Promise<any> {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }
    const info = { ...mockSampleInfo };
    info.task_id = taskId;
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(info, null, 2),
        },
      ],
    };
  }

  async getCodeTree(taskId: string): Promise<any> {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockCodeTree, null, 2),
        },
      ],
    };
  }

  async getCodeFile(taskId: string, filePath: string): Promise<any> {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }
    if (!filePath || typeof filePath !== 'string') {
      throw new Error('file_path is required and must be a string');
    }
    const mockFileContent = `// Mock file content for ${filePath}
// This is a placeholder for actual file content

export function exampleFunction() {
  console.log('Example from ${filePath}');
  return 'result';
}
`;
    return {
      content: [
        {
          type: 'text',
          text: mockFileContent,
        },
      ],
    };
  }

  async getStaticReport(taskId: string): Promise<any> {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockStaticReport, null, 2),
        },
      ],
    };
  }

  async getDynamicReport(taskId: string): Promise<any> {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockDynamicReport, null, 2),
        },
      ],
    };
  }

  async getTrafficReport(taskId: string): Promise<any> {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockTrafficReport, null, 2),
        },
      ],
    };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Sample Store MCP Server running on stdio');
  }
}
