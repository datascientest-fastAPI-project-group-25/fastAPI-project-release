/**
 * Logging configuration for the release repository
 * Platform-independent configuration
 */

const path = require('path');
const fs = require('fs');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '..', 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Default log levels
const LOG_LEVELS = {
  ERROR: 0,
  WARN: 1,
  INFO: 2,
  DEBUG: 3,
};

// Default configuration
const config = {
  // Log level from environment or default to INFO
  level: process.env.LOG_LEVEL ? 
    LOG_LEVELS[process.env.LOG_LEVEL.toUpperCase()] || LOG_LEVELS.INFO : 
    LOG_LEVELS.INFO,
  
  // Output formats
  format: process.env.LOG_FORMAT || 'json',
  
  // Destinations
  console: process.env.LOG_CONSOLE !== 'false',
  file: process.env.LOG_FILE !== 'false',
  
  // File configuration
  fileOptions: {
    filename: path.join(logsDir, 'release.log'),
    maxSize: '10m',
    maxFiles: 5,
    tailable: true,
  },
  
  // Loki integration
  loki: {
    enabled: process.env.LOKI_ENABLED === 'true',
    host: process.env.LOKI_HOST || 'localhost',
    port: process.env.LOKI_PORT || 3100,
    labels: {
      app: 'release',
      environment: process.env.ENVIRONMENT || 'development',
    },
  },
};

module.exports = config;
