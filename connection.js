var connection = require('./config.js').dbUrl;
var debug = require('./config.js').dbDebug;

var knex = require('knex')({
  client: 'pg',
  connection: connection,
  debug: debug
});

module.exports = knex;
