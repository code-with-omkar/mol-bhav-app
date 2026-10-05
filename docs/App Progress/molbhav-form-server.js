#!/usr/bin/env node
/**
 * MolBhav Progress Form Server
 * Serves HTML form, updates artifact via Claude API
 *
 * Usage: node molbhav-form-server.js
 */

const http = require('http');
const url = require('url');
const querystring = require('querystring');
const https = require('https');
const open = require('open');

const PORT = 3847;
const API_KEY = process.env.CLAUDE_API_KEY;
const ARTIFACT_URL = 'https://claude.ai/artifact/5pBWjwWkcHJ8Mj9pzgyGQ9';

if (!API_KEY) {
  console.error('❌ Error: CLAUDE_API_KEY environment variable not set');
  process.exit(1);
}

// HTML Form
const htmlForm = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MolBhav Progress Update</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 500px;
            padding: 40px;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            display: inline-block;
            width: 50px;
            height: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 15px;
        }
        h1 {
            font-size: 24px;
            color: #333;
            margin-bottom: 8px;
        }
        .subtitle {
            color: #999;
            font-size: 14px;
        }
        .form-group {
            margin-bottom: 25px;
        }
        label {
            display: block;
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
            font-size: 14px;
        }
        input[type="number"],
        input[type="text"],
        textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
            transition: border-color 0.3s;
        }
        input[type="number"]:focus,
        input[type="text"]:focus,
        textarea:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        textarea {
            resize: vertical;
            min-height: 100px;
        }
        .input-suffix {
            position: absolute;
            right: 12px;
            top: 42px;
            color: #999;
            font-weight: 600;
        }
        .form-group.with-suffix {
            position: relative;
        }
        .button-group {
            display: flex;
            gap: 12px;
            margin-top: 30px;
        }
        button {
            flex: 1;
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        .btn-submit {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }
        .btn-submit:active {
            transform: translateY(0);
        }
        .btn-cancel {
            background: #f0f0f0;
            color: #333;
        }
        .btn-cancel:hover {
            background: #e0e0e0;
        }
        .status {
            margin-top: 20px;
            padding: 12px;
            border-radius: 8px;
            text-align: center;
            display: none;
            font-weight: 600;
            font-size: 14px;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .status.loading {
            background: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">M</div>
            <h1>MolBhav Progress</h1>
            <p class="subtitle">Update project metrics</p>
        </div>

        <form id="progressForm">
            <div class="form-group with-suffix">
                <label for="apiProgress">API Progress</label>
                <input type="number" id="apiProgress" name="apiProgress" min="0" max="100" value="97" required>
                <span class="input-suffix">%</span>
            </div>

            <div class="form-group with-suffix">
                <label for="appProgress">App Progress</label>
                <input type="number" id="appProgress" name="appProgress" min="0" max="100" value="95" required>
                <span class="input-suffix">%</span>
            </div>

            <div class="form-group">
                <label for="migrationsCount">Migrations Completed</label>
                <input type="text" id="migrationsCount" name="migrationsCount" value="30/30" placeholder="e.g., 30/30" required>
            </div>

            <div class="form-group">
                <label for="latestUpdate">Latest Completed</label>
                <input type="text" id="latestUpdate" name="latestUpdate" placeholder="e.g., Password login + expiry sweep" value="Password login + expiry sweep">
            </div>

            <div class="form-group">
                <label for="blockers">Open Blockers</label>
                <textarea id="blockers" name="blockers" placeholder="List blockers, one per line&#10;e.g.&#10;data.gov.in unreachable&#10;IMD access pending&#10;D1 domain setup"></textarea>
            </div>

            <div class="button-group">
                <button type="submit" class="btn-submit">Update Artifact</button>
                <button type="button" class="btn-cancel" onclick="window.close()">Cancel</button>
            </div>

            <div id="status" class="status"></div>
        </form>
    </div>

    <script>
        document.getElementById('progressForm').addEventListener('submit', async (e) => {
            e.preventDefault();

            const status = document.getElementById('status');
            status.textContent = 'Updating artifact...';
            status.className = 'status loading';
            status.style.display = 'block';

            const data = {
                apiProgress: document.getElementById('apiProgress').value,
                appProgress: document.getElementById('appProgress').value,
                migrationsCount: document.getElementById('migrationsCount').value,
                latestUpdate: document.getElementById('latestUpdate').value,
                blockers: document.getElementById('blockers').value,
            };

            try {
                const response = await fetch('/update', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data),
                });

                const result = await response.json();

                if (response.ok) {
                    status.textContent = '✅ Artifact updated! You can close this window.';
                    status.className = 'status success';
                    document.getElementById('progressForm').style.opacity = '0.6';
                    document.getElementById('progressForm').style.pointerEvents = 'none';
                } else {
                    status.textContent = '❌ Error: ' + (result.error || 'Failed to update');
                    status.className = 'status error';
                }
            } catch (error) {
                status.textContent = '❌ Error: ' + error.message;
                status.className = 'status error';
            }
        });
    </script>
</body>
</html>
`;

// Create HTTP server
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);

  // Serve form
  if (parsedUrl.pathname === '/' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(htmlForm);
    return;
  }

  // Handle form submission
  if (parsedUrl.pathname === '/update' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        updateArtifact(data, res);
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

// Update artifact via Claude API
function updateArtifact(data, res) {
  const prompt = `
Update the MolBhav Progress artifact at ${ARTIFACT_URL} with these new metrics:

API Progress: ${data.apiProgress}%
App Progress: ${data.appProgress}%
Migrations: ${data.migrationsCount}
Latest: ${data.latestUpdate}
Blockers:
${data.blockers.split('\n').filter(b => b.trim()).map(b => '  • ' + b.trim()).join('\n')}

Update the progress bars, percentage values, and metrics cards. Keep the timeline and existing structure intact.
Timestamp should be current date/time in IST.
`;

  const payload = JSON.stringify({
    model: 'claude-opus-4-1',
    max_tokens: 1000,
    messages: [{ role: 'user', content: prompt }],
  });

  const options = {
    hostname: 'api.anthropic.com',
    path: '/v1/messages',
    method: 'POST',
    headers: {
      'x-api-key': API_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
      'content-length': Buffer.byteLength(payload),
    },
  };

  const req = https.request(options, (apiRes) => {
    let apiData = '';
    apiRes.on('data', (chunk) => {
      apiData += chunk;
    });

    apiRes.on('end', () => {
      if (apiRes.statusCode === 200) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, message: 'Artifact updated' }));
      } else {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: `API error: ${apiRes.statusCode}` }));
      }
    });
  });

  req.on('error', (error) => {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: error.message }));
  });

  req.write(payload);
  req.end();
}

// Start server
server.listen(PORT, () => {
  console.log(`\n✅ MolBhav Progress Form`);
  console.log(`📂 Opening: http://localhost:${PORT}`);
  console.log(`🔗 Artifact: ${ARTIFACT_URL}\n`);

  // Open browser
  open(`http://localhost:${PORT}`).catch(() => {
    console.log(`Can't auto-open browser. Visit: http://localhost:${PORT}`);
  });

  console.log('Press Ctrl+C to stop\n');
});
