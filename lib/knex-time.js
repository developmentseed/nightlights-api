var Boom = require('boom');
var knex = require('../connection');

/**
 * Filter a knex query using the parsed time
 *
 * Logic is:
 * WHERE ( YEAR = startyear AND MONTH >= startmonth )
 * OR ( YEAR BETWEEN startyear+1 AND endyear -1 )
 * OR ( YEAR = endyear AND MONTH <= endmonth )
 */

module.exports = function knexTime (span) {
  let start = span.interval.start;
  let end = span.interval.end;

  if (span.unit === 'months') {
    return knex.where(function () {
      if (start.year < end.year) {
        this.whereRaw('(year = ? and month >= ?) OR ' +
          '(year between ? and ?) OR ' +
          '(year = ? and month <= ?)',
          [start.year, start.month,
          start.year + 1, end.year - 1,
          end.year, end.month]);
      } else if (start.year === end.year) {
        this.whereRaw('(year = ? and month >= ? and month <= ?)',
          [start.year, start.month, end.month]);
      } else {
        throw Boom.badRequest('Start date must come before end date');
      }
    });
  } else if (span.unit === 'years') {
    return knex.where(function () {
      this.whereRaw('(year >= ? and year <= ?)',
          [start.year, end.year]);
    });
  } else {
    throw Boom.badRequest();
  }
};
