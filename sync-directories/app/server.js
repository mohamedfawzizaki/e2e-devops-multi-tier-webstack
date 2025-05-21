const http = require('http');
const os = require('os');
const process = require('process');
const { initDb, getUserOrInsert } = require('./db');
const redis = require('./redis');

// Configuration - could also be moved to environment variables
const CONFIG = {
  host: process.env.NODE_HOST || '192.168.56.14',  // Default but overridable by env
  port: process.env.NODE_PORT || 3000,             // Default but overridable by env
  clusterMode: process.env.CLUSTER_MODE || false,  // For future clustering
  gracefulShutdownTimeout: 5000                     // 5 seconds for graceful shutdown
};

// Create HTTP server
const server = http.createServer(async (req, res) => {
  // Basic request logging
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);

  // Set response headers
  res.setHeader('Content-Type', 'text/plain');
  res.setHeader('X-Node-Instance', os.hostname());

  // Health check endpoint
  if (req.url === '/health') {
    res.statusCode = 200;
    res.end('OK');
    return;
  }

  // Root endpoint
  if (req.url === '/') {
    res.statusCode = 200;
    res.end(`Hello from Node.js App Tier 1 (${os.hostname()})\n`);
    return;
  }

  if (req.url === '/redis' && req.method === 'GET') {
    try {
      await redis.set('greeting', 'Hello from Redis!');
      const value = await redis.get('greeting');
      res.setHeader('Content-Type', 'application/json');
      res.statusCode = 200;
      res.end(JSON.stringify({ message: value }));
    } catch (err) {
      res.statusCode = 500;
      res.end(JSON.stringify({ error: 'Redis Error: ' + err.message }));
    }
    return;
  }

  // New /user endpoint - GET only
  if (req.url === '/db' && req.method === 'GET') {
    res.setHeader('Content-Type', 'application/json');
    try {
      const user = await getUserOrInsert();
      res.statusCode = 200;
      res.end(JSON.stringify(user));
    } catch (err) {
      res.statusCode = 500;
      res.end(JSON.stringify({ error: err.message }));
    }
    return;
  }

  // Handle 404 for other routes
  res.statusCode = 404;
  res.end('Route Not Found\n');
});

// Server event handlers
server.on('error', (err) => {
  console.error('Server error:', err);
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${CONFIG.port} is already in use`);
    process.exit(1);
  }
});

server.on('listening', () => {
  const address = server.address();
  console.log(`
  Server running at http://${address.address}:${address.port}
  Hostname: ${os.hostname()}
  Platform: ${os.platform()} ${os.arch()}
  Node.js: ${process.version}
  PID: ${process.pid}
  `);
});

// Initialize DB first, then start server
initDb()
  .then(() => {
    server.listen(CONFIG.port, CONFIG.host);
  })
  .catch(err => {
    console.error('Failed to initialize DB:', err);
    process.exit(1);
  });

// Graceful shutdown handling
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

function gracefulShutdown() {
  console.log('\nReceived shutdown signal, attempting graceful shutdown...');

  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });

  // Force shutdown if taking too long
  setTimeout(() => {
    console.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, CONFIG.gracefulShutdownTimeout);
}
