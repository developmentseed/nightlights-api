'use strict';
/*global before, describe, it*/

var uniq = require('uniq');
var server = require('../../');

describe('Time series endpoints', function () {
  var response = {};

  describe('/months/.../villages/...', function () {
    var villages = [925000303305100, 925000303305100];

    hitEndpoint('/months/2000.01-2001.01/villages/' + villages.join(','), response);
    checkTimeSeries(response);
    checkDataFields(response);

    it('only returns the requested villages', function (done) {
      let returnedVillages = response.parsed.map(function (datum) {
        return +datum.villagecode;
      });
      returnedVillages.should.containDeep(villages);
      villages.should.containDeep(uniq(returnedVillages));
      done();
    });
  });

  describe('/months/.../states/...', function () {
    hitEndpoint('/months/2000.01-2001.01/states/uttar-pradesh', response);

    checkTimeSeries(response);
    checkDataFields(response);

    it('only returns the requested state', function (done) {
      let returnedStates = uniq(response.parsed.map(function (datum) {
        return datum.key;
      }));
      returnedStates.should.containDeep(['uttar-pradesh']);
      returnedStates.should.have.lengthOf(1);

      done();
    });
  });

  describe('/months/.../districts/{district-key}', function () {
    hitEndpoint('/months/2000.01-2001.01/districts/uttar-pradesh-agra', response);

    checkTimeSeries(response);
    checkDataFields(response,
      ['quintile1', 'quintile2', 'quintile3', 'quintile4']);

    it('only returns the requested district', function (done) {
      let returnedStates = uniq(response.parsed.map(function (datum) {
        return datum.key;
      }));
      returnedStates.should.containDeep(['uttar-pradesh-agra']);
      returnedStates.should.have.lengthOf(1);

      done();
    });
  });
});

/* helpers */
function hitEndpoint (url, response) {
  before(function () {
    return server.injectThen({ method: 'GET', url: url })
    .then(function (resp) {
      response.raw = resp;
      response.parsed = JSON.parse(resp.payload);
    });
  });
}

function checkDataFields (response, fields) {
  fields = ['vis_median', 'count'].concat(fields || []);
  it('includes ' + fields.join(',') + ' in results', function (done) {
    response.parsed.forEach(function (datum) {
      datum.should.have.properties(fields);
    });
    done();
  });
}

function checkTimeSeries (response) {
  it('only returns requested time series', function (done) {
    response.parsed.forEach(function (datum) {
      [2000, 2001].should.containEql(datum.year);
      if (datum.year === 2001) {
        datum.month.should.equal(1);
      }
    });

    // check that jan and dec of 2000 came through
    response.parsed
    .filter(function (d) { return d.year === 2000; })
    .map(function (d) { return d.month; })
    .should.containDeep([1, 12]);
    done();
  });
}
