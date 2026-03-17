#!/bin/bash

echo "Stopping MCP Servers..."

if [ -f .pids/sample-store.pid ]; then
  kill $(cat .pids/sample-store.pid) 2>/dev/null
  rm .pids/sample-store.pid
fi

if [ -f .pids/knowledge-base.pid ]; then
  kill $(cat .pids/knowledge-base.pid) 2>/dev/null
  rm .pids/knowledge-base.pid
fi

if [ -f .pids/report-store.pid ]; then
  kill $(cat .pids/report-store.pid) 2>/dev/null
  rm .pids/report-store.pid
fi

echo "All MCP Servers stopped"
