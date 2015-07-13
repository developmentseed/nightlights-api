'use strict';
var config = require('./config');
if (!config.disableMonitoring) { require('newrelic'); }

require('babel/register');
var Hapi = require('hapi');

var server = new Hapi.Server({
  connections: {
    router: {
      stripTrailingSlash: true
    },
    routes: {
      cors: true,
      cache: {
        expiresIn: config.cache * 1000
      }
    }
  }
});

server.connection({ port: config.port });

// Setup logger
server.register({
  register: require('good'),
  options: config.logOptions
}, function (err) {
  if (err) throw err;
});

// Register routes
server.register({
  register: require('hapi-router'),
  options: {
    routes: 'routes/*.js'
  }
}, function (err) {
  if (err) throw err;
});

server.start(function () {
  server.log(['info'], 'Server running at:' + server.info.uri);
  server.log(['debug'], 'Config: ' + JSON.stringify(config));
});

module.exports = server;
