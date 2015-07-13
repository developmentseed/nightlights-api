var local = {};
try {
  local = require('./local.js');
} catch(e) {}

/**
 * Server configuration.  Options here should be overridden in `local.js`.
 *
 * @name Configuration
 */
module.exports = {
  dbUrl: process.env.DATABASE_URL || local.dbUrl,
  dbDebug: local.dbDebug,
  disableMonitoring: local.disableMonitoring,
  port: process.env.PORT || local.port || 4000,
  cache: process.env.CACHE_CONTROL || local.cache || 86400, // A day in seconds
  logOptions: local.logOptions || {
    opsInterval: 3000,
    reporters: [{
      reporter: require('good-console'),
      events: {
        request: '*',
        error: '*',
        response: '*',
        log: '*'
      }
    }]
  }
};
