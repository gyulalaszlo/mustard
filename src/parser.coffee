fs = require 'fs'
path = require 'path'
PEG = require "pegjs"
jsoutput = require './output_js'
_ = require '../vendor/underscore'
{IndentedBuffer} = require './indented_buffer'


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



#
# Parser
# ======
#

class Parser

    constructor:  ->
        @grammar = fs.readFileSync "#{__dirname}/mustard.pegjs"
        @parser = PEG.buildParser @grammar.toString()
        @astConverter = new AstConverter

    parse: (contents)->
        @tokens = @_parseIntoTokenList contents
        ast = @astConverter.listToAst @tokens
        return ast

    tokenList: ()-> @tokens
          

    _parseIntoTokenList: (contents)->
        try
            result = @parser.parse contents.toString()
            return result
        catch e
            throw new MustardSyntaxError(fileName, e.line, e.column, e.message, e) if e.name is "SyntaxError"


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

        result = int.compile _(@_default_options).defaults opts
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



class AstConverter
    constructor: ->
    listToAst: (list_in)->
        res = new ElementList
        for el in list_in
            res.push @elementFor(el)
        res
    
    elementFor: (obj)->

        return unless obj instanceof Object
        
        # wtf this needs typeof instead of instanceof is beyond me
        if obj.type == 'text'
            return new Text(obj)

        if obj.type == 'element'
          children = new ElementList
          if obj.contents instanceof Array
            children = @listToAst(obj.contents)
          return new Element(obj, children)
        
root = exports ? this

# export checking functions
root._mustard_checks =
    isElement: (o)-> o instanceof Element
    isElementList: (o)-> o instanceof ElementList
    isText: (o)-> o instanceof Text



# root.Parser = Parser
# root.FileParser = FileParser
root.MustardCompiler = MustardCompiler
# root.ElementList = ElementList
# root.Element = Element
# root.Text = Text
