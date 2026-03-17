import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

export class KnowledgeBaseServer {
  private server: Server;
  private hatlData: any;

  constructor() {
    this.server = new Server(
      {
        name: 'knowledge-base',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.loadHATLData();
    this.setupHandlers();
  }

  private loadHATLData() {
    // Mock HATL 数据
    this.hatlData = {
      techniques: [
        {
          id: 'T001',
          name: '短信发送',
          tactic: '信息窃取',
          description: '未经用户同意发送短信',
          indicators: ['@ohos.telephony.sms.sendSms', 'sms.sendSms'],
          severity: 'high',
        },
        {
          id: 'T002',
          name: '联系人窃取',
          tactic: '信息窃取',
          description: '读取用户联系人信息',
          indicators: ['@ohos.contacts.getContact', 'contact.queryContact'],
          severity: 'high',
        },
        {
          id: 'T003',
          name: '位置追踪',
          tactic: 'surveillance',
          description: '持续获取用户位置信息',
          indicators: ['@ohos.geoLocationManager.getLocation', 'geolocation.getLocation'],
          severity: 'medium',
        },
      ],
    };
  }

  private setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'query_hatl',
            description: '查询HATL攻击技术知识库',
            inputSchema: {
              type: 'object',
              properties: {
                query: {
                  type: 'string',
                  description: '搜索关键词',
                },
                category: {
                  type: 'string',
                  description: '技术分类（可选）',
                },
              },
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        if (name === 'query_hatl') {
          return await this.queryHATL(args?.query as string, args?.category as string);
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

  async queryHATL(query: string, category?: string) {
    if (!query || typeof query !== 'string') {
      throw new Error('query is required and must be a string');
    }

    const results = this.hatlData.techniques.filter(
      (t: any) =>
        t.name.includes(query) ||
        t.description.includes(query) ||
        t.indicators.some((i: string) => i.includes(query))
    );

    if (category) {
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(
              results.filter((t: any) => t.tactic === category),
              null,
              2
            ),
          },
        ],
      };
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(results, null, 2),
        },
      ],
    };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Knowledge Base MCP Server running on stdio');
  }
}
