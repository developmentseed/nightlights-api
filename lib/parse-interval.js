let Boom = require('boom');

/**
 * Parse and validate the /{time_units}/{interval} part of the API requests.
 */
module.exports = function parseTimeParameters (params) {
  var units = params.time_units;
  var interval;
  if (units === 'months') {
    // interval parameter is in the form yyyy.mm-yyyy.mm
    interval = (params.interval || '')
    .split('-')
    .map((monthString) => {
      var [year, month] = monthString.split('.').map(Number);

      if (!year || year < 1993 || year > (new Date()).getFullYear()) {
        throw Boom.badRequest('Invalid year: ' + year + 'in interval' +
          params.interval);
      }

      if (!month || month < 0 || month > 12) {
        throw Boom.badRequest('Invalid month: ' + month + ' in interval ' +
          params.interval);
      }

      return {year, month};
    });
  } else {
    throw Boom.badRequest('Invalid time unit' + units);
  }

  return {
    unit: units,
    interval: {
      start: interval[0],
      end: interval[1]
    }
  };
};
