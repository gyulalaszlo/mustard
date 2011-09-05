parser = require './parser'
util = require 'util'

argv = require('optimist')
    .alias('v', 'verbose')
    .default('verbose', false)
    .argv




parser = new parser.Parser
for arg in argv._
  res = parser.parseFile(arg)
  console.log( util.inspect(res, false, 10 )) if argv.verbose
