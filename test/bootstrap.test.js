'use strict';

/*global after*/

require('should');
var server = require('../');

server.register(require('inject-then'), function (err) {
  'use strict';
  if (err) throw err;
});

after(function (done) {
  done();
});
