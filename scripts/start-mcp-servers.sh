#!/bin/bash

echo "Starting Harmony Security Analysis MCP Servers..."

# 创建 .pids 目录
mkdir -p .pids

# 启动 sample-store
echo "Starting sample-store MCP Server..."
node dist/mcp/sample-store/index.js &
SAMPLE_STORE_PID=$!
echo $SAMPLE_STORE_PID > .pids/sample-store.pid

# 启动 knowledge-base
echo "Starting knowledge-base MCP Server..."
node dist/mcp/knowledge-base/index.js &
KNOWLEDGE_BASE_PID=$!
echo $KNOWLEDGE_BASE_PID > .pids/knowledge-base.pid

# 启动 report-store
echo "Starting report-store MCP Server..."
node dist/mcp/report-store/index.js &
REPORT_STORE_PID=$!
echo $REPORT_STORE_PID > .pids/report-store.pid

echo "All MCP Servers started!"
echo "PIDs: sample-store=$SAMPLE_STORE_PID, knowledge-base=$KNOWLEDGE_BASE_PID, report-store=$REPORT_STORE_PID"
echo "Press Ctrl+C to stop all servers"

# 等待信号
wait
