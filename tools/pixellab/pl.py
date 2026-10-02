"""Cliente mínimo do MCP HTTP do PixelLab (lê a configuração da conta do Marco em ~/.claude.json)."""
import json, os, sys, urllib.request
CFG = json.load(open(os.path.expanduser('~/.claude.json'), encoding='utf-8'))['mcpServers']['pixellab']
URL = CFG['url']
SESS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pl_session.txt')

def post(payload, sid=None):
    h = dict(CFG['headers']); h['Content-Type'] = 'application/json'; h['Accept'] = 'application/json, text/event-stream'
    if sid: h['Mcp-Session-Id'] = sid
    req = urllib.request.Request(URL, data=json.dumps(payload).encode(), headers=h, method='POST')
    with urllib.request.urlopen(req, timeout=300) as r:
        sid2 = r.headers.get('Mcp-Session-Id') or sid
        body = r.read().decode('utf-8', 'replace')
    msgs = []
    if body.lstrip().startswith('{'):
        msgs.append(json.loads(body))
    else:
        for line in body.splitlines():
            if line.startswith('data:'):
                try: msgs.append(json.loads(line[5:].strip()))
                except Exception: pass
    return sid2, msgs

def session():
    if os.path.exists(SESS):
        return open(SESS).read().strip()
    sid, _ = post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "deep-iron", "version": "1"}}})
    post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)
    open(SESS, 'w').write(sid or '')
    return sid

def call(name, args):
    sid = session()
    try:
        _, m = post({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": name, "arguments": args}}, sid)
    except urllib.error.HTTPError as e:
        if e.code in (400, 404) and os.path.exists(SESS):
            os.remove(SESS); sid = session()
            _, m = post({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": name, "arguments": args}}, sid)
        else:
            raise
    return m

if __name__ == '__main__':
    if sys.argv[1] == 'list':
        _, m = post({"jsonrpc": "2.0", "id": 3, "method": "tools/list"}, session())
        for t in m[-1]['result']['tools']:
            print(t['name'], '-', t.get('description', '')[:110].replace('\n', ' '))
    elif sys.argv[1] == 'schema':
        _, m = post({"jsonrpc": "2.0", "id": 3, "method": "tools/list"}, session())
        for t in m[-1]['result']['tools']:
            if t['name'] == sys.argv[2]:
                print(json.dumps(t['inputSchema'], indent=1)[:6000]); print(t.get('description',''))
    else:
        args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
        for msg in call(sys.argv[1], args):
            r = msg.get('result', msg.get('error'))
            if isinstance(r, dict) and 'content' in r:
                for c in r['content']:
                    print(c.get('text', c.get('type')))
            else:
                print(json.dumps(r)[:3000])
