'use strict';
/*global before, describe, it*/

var server = require('../../');

describe('Boundaries endpoints', function () {
  var response = {};

  describe('/boundaries/states/{key}', function () {
    hitEndpoint('/boundaries/states/gujarat', response);

    it('should contain the state and its districts', function (done) {
      response.parsed.should.have.property('gujarat');
      Object.keys(response.parsed).forEach(function (key) {
        key.should.match(/^gujarat/);
      });
      done();
    });

    it('should include a GeoJSON `geometry` and metadata as `properties`',
    function (done) {
      for (let key in response.parsed) {
        if (key === 'gujarat') { continue; }
        let district = response.parsed[key];
        district.should.have.properties('geometry', 'properties');
        district.properties.should.have.properties(
          'state_key',
          'key',
          'name',
          'tot_pop'
        );
      }
      done();
    });
  });

  describe('/boundaries/states', function () {
    hitEndpoint('/boundaries/states', response);

    it('should include a GeoJSON `geometry` and metadata as `properties`',
    function (done) {
      let states = Object.keys(response.parsed);
      states.should.containDeep([
        'andhra-pradesh',
        'arunachal-pradesh',
        'jammu-&-kashmir',
        'karnataka',
        'kerala',
        'madhya-pradesh',
        'maharashtra',
        'manipur',
        'meghalaya',
        'mizoram',
        'nagaland',
        'orissa',
        'assam',
        'punjab',
        'rajasthan',
        'sikkim',
        'tripura',
        'uttar-pradesh',
        'uttarakhand',
        'west-bengal',
        'bihar',
        'chhattisgarh',
        'delhi',
        'goa',
        'gujarat',
        'haryana',
        'himachal-pradesh'
      ]);
      states.forEach(function (key) {
        response.parsed[key].should.have.properties('geometry', 'properties');
        response.parsed[key].properties.should.have.properties(
          'key',
          'name',
          'tot_pop'
        );
      });
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

