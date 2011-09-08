fs = require 'fs'
path = require 'path'
PEG = require "pegjs"
jsoutput = require './output_js'
_ = require '../vendor/underscore'



class MustardSyntaxError extends Error
    constructor: (@file, @line, @col, @message, @base_exception)->
        @name = "Mustard Syntax Error"
    toString: -> "#{@file}:#{@line} (col:#{@col}) #{@message}"

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
        # console.log 'hash:', hash.declaration.attributes
        for attrs in hash.declaration.attributes
            if typeof attrs.name is "string"
              attr_key = attrs.name
              # console.log 'attr_pairs:', k, v
              attr_cache[attr_key] ||= []
              attr_cache[attr_key].push new Text(attrs.value)
            else
              attr_key = new Text(attrs.name)
              # console.log 'attr_pairs:', k, v
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
        console.log @children
        for child in @children.elements
          console.log 'io Text:', (child instanceof Text)
          return false unless (child instanceof Text)
        true

    toString: ()-> "[element <#{@name}> - #{@attributeTexts()} - #{@children}]"


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
            throw e



class Mustard
    constructor: (@klassName, @target='js')->
        @_parser = new Parser
        @_target = switch target
            when 'js' then new jsoutput.JsOutput
    
    
    # add a text blob as a new template method for the given key
    addText: (text, key)->
        @_ast = @_parser.parse text
        @_target.addTemplate @_ast, key
    
    # add a file as a new template method for the given key
    addFile: (targetFile, key=path.basename(targetFile))->
        @addText fs.readFileSync(targetFile), key

    # return an evaluated klass of the template (JS only)
    # optsions:
    #   context: assign the template to the given context
    toClass: (opts={})->
        opts = _(opts).defaults
            context:root

        throw '.toClass() is only supported for the JS target' if @target isnt 'js'
        @_target.evalClass @klassName

    # return an evaluated instance of the template (JS only)
    toInstance: (opts={})->
        new ( @toClass(opts) )()


    # return the generated template class source
    toSource: (opts={})->
        @_target.createClass @klassName

    # write the source to a file
    writeSource: (filename, opts={})->
        fs.writeFile filename, @toSource()


    @compile: (text, opts={})->
        klassNameId = uniqueId("Template_#{new Date().getTime();}")
        inst = new @(klassNameId, 'js')


        

    
    
    # tokenlist of the the last template parsed
    tokenList: -> @parser.tokenList()

    # the AST of the last template parsed
    ast: -> @_ast
        


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
root.Mustard = Mustard
# root.ElementList = ElementList
# root.Element = Element
# root.Text = Text
