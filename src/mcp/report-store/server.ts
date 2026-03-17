import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { writeFileSync, mkdirSync, readFileSync, existsSync } from 'fs';
import { join } from 'path';

export class ReportStoreServer {
  private server: Server;
  private reportPath: string;

  constructor() {
    this.server = new Server(
      {
        name: 'report-store',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.reportPath = process.env.REPORT_OUTPUT_PATH || './data/reports';
    this.setupHandlers();
  }

  private setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'save_report',
            description: '保存分析报告',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
                report_content: {
                  type: 'string',
                  description: '报告内容（Markdown格式）',
                },
              },
              required: ['task_id', 'report_content'],
            },
          },
          {
            name: 'get_report',
            description: '获取历史报告',
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
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        if (name === 'save_report') {
          return await this.saveReport(args?.task_id as string, args?.report_content as string);
        }
        if (name === 'get_report') {
          return await this.getReport(args?.task_id as string);
        }
        return {
          content: [
            {
              type: 'text',
              text: `Unknown tool: ${name}`,
              isError: true,
            },
          ],
        };
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
    });
  }

  async saveReport(taskId: string, content: string) {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }
    if (!content || typeof content !== 'string') {
      throw new Error('report_content is required and must be a string');
    }

    try {
      mkdirSync(this.reportPath, { recursive: true });

      const filename = `${taskId}_${Date.now()}.md`;
      const filepath = join(this.reportPath, filename);
      writeFileSync(filepath, content, 'utf-8');

      return {
        content: [
          {
            type: 'text',
            text: `Report saved to: ${filepath}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error saving report: ${error instanceof Error ? error.message : String(error)}`,
            isError: true,
          },
        ],
      };
    }
  }

  async getReport(taskId: string) {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required and must be a string');
    }

    // 简化实现：返回最新报告
    const reportPath = join(this.reportPath, `${taskId}.md`);
    if (existsSync(reportPath)) {
      const content = readFileSync(reportPath, 'utf-8');
      return {
        content: [
          {
            type: 'text',
            text: content,
          },
        ],
      };
    }

    return {
      content: [
        {
          type: 'text',
          text: `No report found for task: ${taskId}`,
        },
      ],
    };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Report Store MCP Server running on stdio');
  }
}
