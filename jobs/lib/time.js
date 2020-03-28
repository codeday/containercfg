const parse = require('./parse-duration');

module.exports.sToNs = (s) => s * 1000000;
module.exports.strToNs = (str) => typeof(str) === 'number' ? str : module.exports.sToNs(parse(str));
