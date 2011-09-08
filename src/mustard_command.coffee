parser = require './parser'
util = require 'util'
jsoutput = require './output_js'

argv = require('optimist')
    .usage('compile mustard templates')
    .demand(1)
    .options 't'
        alias: 'token-stream'
        default: false
        describe: 'Show the tokenized input'

    .options 'a'
        alias: 'ast'
        default: false
        describe: 'Show the built AST'

    .options 'c'
        alias: 'class-name'
        default: 'Template'
        describe: 'Set the generated class name'

   .argv


inspect = (obj)->
  util.inspect(obj, false, 10 )


parser = new parser.FileParser
jso = new jsoutput.JsOutput

for arg in argv._
  try
    console.log "--> parsing: #{arg}"
    ast = parser.parse(arg)
    console.log "Tokens:\n", inspect(parser.tokenList()) if argv.t
    console.log "AST:\n", inspect( ast ) if argv.ast

    jso.addTemplate ast, arg
  catch e
    console.error "Error during parse:\n ", e.toString()
    console.log("--> Token parse tree (if available)\n", inspect(parser.tokenList()) ) if argv.t
    throw e
    return 1

console.log jso.createClass(argv.c)
jso.evalClass( argv.c )

tpl = eval("new #{argv.c}()")

for arg in argv._
   console.log tpl.render( arg,
     artist: "Miles Davis"
     song: "Miles runs the voodoo down"
     wrap_tag: "section"

     autoplay_info: "start=0"
     buy_link: "http://buy.me"
   )
