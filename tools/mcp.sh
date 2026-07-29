#!/bin/bash
# mcp.sh — Call MCP server tools via SSH
# Configure your server details below before use.

MCP_SERVER_HOST="${MCP_SERVER_HOST:-root@your-server-host}"
MCP_SERVER_PASS="${MCP_SERVER_PASS:-your-password}"
MCP_URL="${MCP_URL:-http://localhost:5006/mcp}"

if [ -z "$1" ]; then
    echo "MCP Client"
    echo "Usage: $0 <tool_name> '[json_args]'"
    echo ""
    echo "Available tools:"
    echo "  db_list_tables    - List database tables"
    echo "  db_read           - Read records"
    echo "  db_search         - Search records"
    echo "  db_count          - Count records"
    echo "  db_insert         - Insert record"
    echo "  db_update         - Update records"
    echo "  db_delete         - Delete records"
    echo "  db_raw_sql        - Execute SELECT query"
    echo "  fs_list           - List project files"
    echo "  fs_read           - Read file"
    echo "  fs_write          - Write file"
    echo "  sys_status        - PM2 services"
    echo "  sys_logs          - Service logs"
    echo "  sys_ports         - Listening ports"
    echo "  sys_restart       - Restart service"
    echo "  sys_uptime        - System info"
    exit 0
fi

TOOL_NAME="$1"
ARGS="${2:-{}}"

sshpass -p "$MCP_SERVER_PASS" ssh -o StrictHostKeyChecking=no "$MCP_SERVER_HOST" "
SESSION_ID=\$(curl -s -D - -X POST $MCP_URL \\
  -H 'Content-Type: application/json' \\
  -H 'Accept: application/json, text/event-stream' \\
  -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{},\"clientInfo\":{\"name\":\"cli\",\"version\":\"1.0\"}}}' 2>&1 | grep -i 'mcp-session-id' | tr -d '\r' | awk '{print \$2}')

curl -s -X POST $MCP_URL \\
  -H 'Content-Type: application/json' \\
  -H 'Accept: application/json, text/event-stream' \\
  -H \"Mcp-Session-Id: \$SESSION_ID\" \\
  -d '{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}' > /dev/null

PAYLOAD=\$(echo '$ARGS' | sed 's/\"/\\\"/g')
curl -s -X POST $MCP_URL \\
  -H 'Content-Type: application/json' \\
  -H 'Accept: application/json, text/event-stream' \\
  -H \"Mcp-Session-Id: \$SESSION_ID\" \\
  -d \"{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":2,\\\"method\\\":\\\"tools/call\\\",\\\"params\\\":{\\\"name\\\":\\\"$TOOL_NAME\\\",\\\"arguments\\\":$ARGS}}\" 2>&1 | grep '^data:' | sed 's/^data: //'
"
