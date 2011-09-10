fs = require 'fs'
path = require 'path'
# PEG = require "pegjs"
mustard_pegjs = require '../build/mustard_pegjs'
jsoutput = require './output_js'
{AstConverter, _mustard_checks} = require './elements'
_ = require '../vendor/underscore'
{IndentedBuffer, ContextWrapper} = require './indented_buffer'


# Exceptions
# ==========
#

class MustardSyntaxError extends Error
    constructor: (@file, @line, @col, @message, @base_exception)->
        @name = "Mustard Syntax Error"
    toString: -> "#{@file}:#{@line} (col:#{@col}) #{@message}"



#
# Parser
# ======
#

class Parser

    constructor:  ()->
        @_grammar = fs.readFileSync "#{__dirname}/mustard.pegjs"
        # @_parser = PEG.buildParser @_grammar.toString()
        @_templates = new Templates
        @_astConverter = new AstConverter()

    parse: (contents)->
        @_tokens = @_parseIntoTokenList contents
        ast = @_astConverter.listToAst @_tokens
        for key, proto of @_astConverter.prototypes()
            # console.log key, proto.toString()
            @_templates.addProto key, proto
            
        return ast

    tokenList: ()-> @_tokens
    templates: ()-> @_templates
          

    _parseIntoTokenList: (contents)->
        try
            result = mustard_pegjs.parse contents.toString()
            # result = @_parser.parse contents.toString()
            return result
        catch e
            throw new Error("Cannot parse: #{e.line} #{e.column} -- #{e.message} - #{contents.toString()}") if e.name is "SyntaxError"


class Templates
    
    constructor: ->
        @templates = {}

    addTemplate: (key, elementList)-> @templates[key] = elementList
    addProto: (key, proto)->  @templates[key] = proto.children

    all: -> @templates

    names: ()-> _(@templates).keys()

#
# Main class
# ==========
#


class MustardCompiler
    @_default_options =
        pretty: true
        
    constructor: (@klassName, @target='js')->
        @_parser = new Parser
        @_templates = @_parser.templates()
        @_options = {}
        @_target = switch @target
            when 'js' then new jsoutput.JsOutput
    
    
    
    # add a text blob as a new template method for the given key
    addText: (text, key)->
        @_ast = @_parser.parse text
        @_templates.addTemplate key, @_ast
    
    # add a file as a new template method for the given key
    addFile: (targetFile, key=MustardCompiler._templateKeyForFile(targetFile))->
        @addText fs.readFileSync(targetFile), key

    # compile the templates into a class using the current target
    compile: (options)->
        source = @_target.createClass @klassName, @_templates ,options
        return new CompilationResult(@target, source)

    # get a list of templates added
    templateNames: -> @_templates.names()

    # compile a template on the fly to a class.
    @create: (text, opts={})->
        klassNameId = _.uniqueId("Template_#{new Date().getTime().toString(32);}_")
        key = 'default'
        inst = new @(klassNameId, 'js')
        inst.addText text, key

        # context = {}

        result = inst.compile _(opts).defaults MustardCompiler._default_options
        # console.log result.toString()
        result.toInstance()

        

    
    
    # tokenlist of the the last template parsed
    tokenList: -> @parser.tokenList()

    # the AST of the last template parsed
    ast: -> @_ast

    @_templateKeyForFile = (f)->
        path.dirname(f) + '/' + path.basename(f, '.mustard')


class CompilationResult

    constructor: (@_target, @_source)->

    target: -> @_target
    source: -> @_source

    toString: -> @source()

    write: (filename)-> fs.writeFile filename, @source()

    toKlass: (context={})->
        throw new Error('.toClass() is only supported for the JS target') if @_target isnt 'js'
        eval @source()

    toInstance: (context={})-> 
        klass = @toKlass(context)
        return new klass()



       
root = exports ? this

mustardFunc = (text, opts={})->
    MustardCompiler.create(text, opts)


root.MustardCompiler = MustardCompiler
root.Mustard = mustardFunc
