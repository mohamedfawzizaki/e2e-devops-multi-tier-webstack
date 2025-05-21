const Redis = require('ioredis');

// Replace with your actual IP, port, and password
const redis = new Redis({
  host: '192.168.56.11',     // Redis server private IP
  // host: "redis_server",     // Redis server hostname
  port: 6379,
  password: '29112000',
  retryStrategy(times) {
    return Math.min(times * 50, 2000); // reconnect strategy
  },
});

// Test connection
redis.on('connect', () => {
  console.log('✅ Connected to Redis');
});

redis.on('error', (err) => {
  console.error('❌ Redis error:', err);
});

module.exports = redis;
