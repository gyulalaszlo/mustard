parser = require './parser'
util = require 'util'

argv = require('optimist')
    .usage('compile mustard templates')
    .demand(1)
    .options 't'
        alias: 'token-stream'
        default: false
        describe: 'Show the tokenized input'
    

   .argv


inspect = (obj)->
  util.inspect(obj, false, 10 )


parser = new parser.Parser
for arg in argv._
  try
    console.log "--> parsing: #{arg}"
    res = parser.parseFile(arg)
    console.log inspect(res) if argv.t
  catch e
    console.error "Error during parse:\n ",e.toString()
    console.log("--> Token parse tree (if available)\n", inspect(parser.tokens) ) if argv.t
    throw e
 
