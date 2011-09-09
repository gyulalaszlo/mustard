parser = require './parser'
util = require 'util'

argv = require('optimist')
    .usage('Compiles mustard templates into classes')
    .demand(1)
    .boolean('t').options 't'
        alias: 'token-stream'
        default: false
        describe: 'Show the tokenized input'

    .boolean('a').options 'a'
        alias: 'ast'
        default: false
        describe: 'Show the built AST'

    .string('C').options 'C'
        alias: 'class-name'
        default: 'Template'
        describe: 'Set the generated class name'

    .boolean('s').options 's'
        alias: 'show-source'
        default: false
        describe: 'Print the source of the template'
    
    .string('o').options 'o'
        alias: 'output-file'
        default: false
        describe: 'Output the compiled template class to <file>'
    
    .boolean('u').options 'u'
        alias: 'ugly'
        default: false
        describe: 'Remove indentations from output template (for speedup)'

   .argv





inspect = (obj)-> JSON.stringify obj, null, 2
mustard = new parser.MustardCompiler argv.C, 'js'

for arg in argv._
  try
    console.log "===> parsing: #{arg}"
    mustard.addFile arg
    # ast = parser.parse(arg)
    console.log "--> Tokens:\n", inspect( mustard.tokenList() ) if argv.t
    console.log "--> AST:\n", mustard.ast().toString() if argv.ast

    # jso.addTemplate ast, arg
  catch e
    console.error "Error during parse:\n ", e.toString()
    console.log("--> Token parse tree (if available)\n", inspect(mustard.tokenList()) ) if argv.t
    throw e
    return 1




try
  console.log "\n===> Compiling #{mustard.templateNames().join ','}"
  compileOptions =
    pretty: !argv.ugly
  result = mustard.compile compileOptions

  # show the source
  if argv.s
      console.log "\n--> Source:\n", result.source()
  # save the source
  if argv.o
      console.log "\n--> Saving source to:#{argv.o}\n"
      result.write(argv.o)

  console.log result._id
  
  tpl = result.toInstance()


  for arg in argv._
     # console.log parser.MustardCompiler._templateKeyForFile(arg)
     console.log tpl.render( parser.MustardCompiler._templateKeyForFile(arg),
       artist: "Miles Davis"
       song: "Miles runs the voodoo down"
       wrap_tag: "section"

       autoplay_info: "start=0"
       buy_link: "http://buy.me"
     )

catch e
    console.log "Error during compilation and eval:\n ", e.stack
    console.log("--> Token parse tree (if available)\n", inspect(parser.tokenList()) ) if argv.t
    # throw e
    return 1

