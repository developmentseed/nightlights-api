let Boom = require('boom');
let knex = require('../connection');

function rollup (results) {
  return results
  .reduce((memo, row) => {
    memo[row.key] = {
      type: 'Feature',
      geometry: JSON.parse(row.geometry),
      properties: {}
    };
    delete row.geometry;
    for (let k in row) {
      memo[row.key].properties[k] = row[k];
    }
    return memo;
  }, {});
}
function districtBoundaryQuery () {
  return knex('districts_boundaries')
    .leftJoin('districts',
      'districts.district_key',
      'districts_boundaries.district_key')
    .select(knex.raw('districts_boundaries.district_key as key, district_name as name, ' +
      'districts_boundaries.state_key as state_key, tot_pop, f_pop, tot_lit,' +
      'ST_AsGeoJSON(geom_simplified) as geometry'));
}

function stateBoundaryQuery () {
  return knex('states_boundaries')
    .leftJoin('districts', 'districts.state_key', 'states_boundaries.state_key')
    .distinct(knex.raw('states_boundaries.state_key as key, state_name as name,' +
      ' tot_pop, f_pop, f_pop, tot_lit,' +
      'ST_AsGeoJSON(geom_simplified) as geometry'))
    .select();
}

module.exports = [
/**
 * @apiDefine BoundaryKeyParam
 * @apiParam {String} key Identifier for boundary
 */

/**
 * @apiDefine GeoJsonResponse
 * @apiSuccess {Object} result Object of GeoJSON Features grouped by boundary key
 * @apiSuccess {Object} result.key Identifier for boundary area
 * @apiSuccess {Object} result.key.geometry GeoJson geometry
 * @apiSuccess {Object} result.key.properties Feature properties
 * @apiSuccess {String} result.key.properties.name Name of Feature
 * @apiSuccess {String} result.key.properties.state_key Identifier of enclosing state
 * @apiSuccess {Number} result.key.properties.tot_pop Population in district
 */
{
  method: 'GET',
  path: '/boundaries/districts/{key}',
  handler: function boundaries (req, res) {
    districtBoundaryQuery()
      .where('districts.district_key', req.params.key)
      .then((results) => res(rollup(results)))
      .catch((err) => {
        req.log(err);
        res(Boom.badImplementation());
      });
  }
},
{
  method: 'GET',
  path: '/boundaries/states/{key}',
  handler: function boundaries (req, res) {
    var districts = knex.select('district_key')
      .from('districts')
      .where('state_key', req.params.key);

    districtBoundaryQuery()
    .whereIn('districts_boundaries.district_key', districts)
    .then((districts) =>
      stateBoundaryQuery()
      .where('states_boundaries.state_key', req.params.key)
      .then((state) => districts.concat(state))
    )
    .then((results) => res(rollup(results)))
    .catch((err) => {
      req.log(err);
      res(Boom.badImplementation());
    });
  }
},
{
  method: 'GET',
  path: '/boundaries/states',
  handler: function boundaries (req, res) {
    stateBoundaryQuery()
      .then((results) => res(rollup(results)))
      .catch((err) => {
        req.log(err);
        res(Boom.badImplementation());
      });
  }
}
];
