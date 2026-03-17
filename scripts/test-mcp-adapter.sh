#!/bin/bash
# Test MCP Adapter Integration

echo "=== MCP Adapter Test ==="
echo ""
echo "1. Checking if Gateway is running..."
openclaw health 2>&1 | grep -E "Gateway|Telegram|Feishu" || echo "Gateway not running"
echo ""

echo "2. Checking if MCP Adapter plugin is loaded..."
openclaw plugins list 2>&1 | grep -A 2 "MCP Adapter" || echo "MCP Adapter not loaded"
echo ""

echo "3. Testing MCP Server executability..."
echo "   Testing knowledge-base server..."
timeout 2 node "D:/workspace/harmony-analyse-system/dist/mcp/knowledge-base/index.js" 2>&1 | head -1 || echo "Server started (timeout expected)"
echo ""

echo "4. Checking data directories..."
ls -d "D:/workspace/harmony-analyse-system/data"/{samples,knowledge,reports} 2>&1
echo ""

echo "5. Current MCP Adapter config:"
cat "C:/Users/mind/.openclaw/openclaw.json" | grep -A 15 '"mcp-adapter"' | head -16
echo ""

echo "=== Test Complete ==="
