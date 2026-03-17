const fs = require('fs');
const path = require('path');

class HarmonySecurityPlugin {
  constructor(config, gateway) {
    this.config = config;
    this.gateway = gateway;
    this.activeSessions = new Map();
  }

  async beforeAgentStart(context) {
    const { userPrompt, sessionId, workspaceDir } = context;

    const taskId = this.extractTaskId(userPrompt);
    if (taskId) {
      const contextContent = `## 当前分析任务\n\n**任务ID**: ${taskId}\n\n你可以使用以下 MCP 工具获取样本信息：\n- sample-store/get_sample_info\n- sample-store/get_code_tree\n- sample-store/get_static_report\n- sample-store/get_dynamic_report\n- sample-store/get_traffic_report\n- knowledge-base/query_hatl\n- report-store/save_report\n`;

      const contextPath = path.join(workspaceDir, 'TASK_CONTEXT.md');
      fs.writeFileSync(contextPath, contextContent);

      console.log(`[HarmonySecurityPlugin] Injected task context for ${taskId}`);
    }
  }

  async toolResultPersist(context) {
    const { toolName, result, sessionId } = context;

    if (toolName.startsWith('harmony_') || toolName.includes('sample') || toolName.includes('report')) {
      const sessionData = this.activeSessions.get(sessionId) || { findings: [] };
      sessionData.findings.push({ tool: toolName, result, timestamp: Date.now() });
      this.activeSessions.set(sessionId, sessionData);
    }
  }

  async agentEnd(context) {
    const { sessionId } = context;

    const sessionData = this.activeSessions.get(sessionId);
    if (sessionData && sessionData.findings.length > 0) {
      console.log(`[HarmonySecurityPlugin] Session ${sessionId} completed with ${sessionData.findings.length} findings`);
    }

    this.activeSessions.delete(sessionId);
  }

  async gatewayStart() {
    console.log('[HarmonySecurityPlugin] Plugin initialized');
    console.log('[HarmonySecurityPlugin] Config:', JSON.stringify(this.config, null, 2));
  }

  extractTaskId(prompt) {
    const match = prompt.match(/(?:任务ID|task.?id)[:\s]+([A-Z0-9-]+)/i);
    return match ? match[1] : null;
  }
}

module.exports = HarmonySecurityPlugin;
