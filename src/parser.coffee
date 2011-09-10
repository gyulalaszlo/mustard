fs = require 'fs'
path = require 'path'
# PEG = require "pegjs"
mustard_pegjs = require '../build/mustard_pegjs'
jsoutput = require './output_js'
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
# Elements
# ========

class Text
    constructor: (obj)-> @partials = obj.text
    toString: -> @partials
    hasOnlyTextChildren: -> true
    toString: -> "[text: #{JSON.stringify _(@partials).map( (e)->JSON.stringify e ).join(' ')}]"


class ElementList
    constructor: -> @elements = []
    push: (el)-> @elements.push el
    length: ()-> @elements.length
    toString: -> "[elementList #{_.map(@elements, (e)-> e.toString()).join("\n") }]"


class Element
    constructor: (hash, @children)->
        @name = new Text(hash.declaration.name)
        @attributes= {}
        # store interpolated attribute names in an array
        @interpolated_attributes = []
        attr_cache = {}
        for attrs in hash.declaration.attributes
            if typeof attrs.name is "string"
              attr_key = attrs.name
              attr_cache[attr_key] ||= []
              attr_cache[attr_key].push new Text(attrs.value)
            else
              attr_key = new Text(attrs.name)
              @interpolated_attributes.push
                name:attr_key
                value:new Text(attrs.value)

        @attributes = attr_cache

    attributeTexts: ()->
        attributeTexts = []
        for k,v of @attributes
            attributeTexts.push ' ' , k , '="' , ([a.toString(), ' '] for a in v) , '"'

        for attr in @interpolated_attributes
            attributeTexts.push ' ', attr.name.toString(), '="' , attr.value.toString(), '"'

        attributeTexts

    hasOnlyTextChildren: ()->
        for child in @children.elements
          return false unless (child instanceof Text)
        true

    toString: ()-> "[element <#{@name}> - #{@attributeTexts()} - #{@children}]"


class Scope
    
    constructor: (hash, @children)->
        @name = new Text(hash.name)
        @parameters = []
        # console.log params
        @parameters.push new Text(param) for param in hash.parameters

    toString: -> "[scope #{JSON.stringify(@name)} - #{@children}]"
    hasOnlyTextChildren: -> false

class AstConverter
    constructor: ->
    listToAst: (list_in)->
        res = new ElementList
        for el in list_in
            res.push @elementFor(el)
        res

    getChildrenFor: (obj)->
        children = new ElementList
        if obj.contents instanceof Array
            children = @listToAst(obj.contents)
        children

    
    elementFor: (obj)->

        return unless obj instanceof Object
        
        return switch obj.type
            when 'text' then new Text(obj)
            when 'scope' then new Scope(obj, @getChildrenFor(obj))
            when 'element' then new Element(obj, @getChildrenFor(obj))
 

#
# Parser
# ======
#

class Parser

    constructor:  ->
        @_grammar = fs.readFileSync "#{__dirname}/mustard.pegjs"
        # @_parser = PEG.buildParser @_grammar.toString()
        @_astConverter = new AstConverter

    parse: (contents)->
        @_tokens = @_parseIntoTokenList contents
        ast = @_astConverter.listToAst @_tokens
        return ast

    tokenList: ()-> @_tokens
          

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
        @_templates = new Templates
        @_parser = new Parser
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

# export checking functions
root._mustard_checks =
    isElement: (o)-> o instanceof Element
    isElementList: (o)-> o instanceof ElementList
    isText: (o)-> o instanceof Text
    isScope: (o)-> o instanceof Scope

mustardFunc = (text, opts={})->
    MustardCompiler.create(text, opts)


# root.Parser = Parser
# root.FileParser = FileParser
root.MustardCompiler = MustardCompiler
root.Mustard = mustardFunc
# root.ElementList = ElementList
# root.Element = Element
# root.Text = Text
