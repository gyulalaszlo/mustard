fs = require 'fs'
PEG = require "pegjs"



class MustardSyntaxError extends Error
    constructor: (@file, @line, @col, @message, @base_exception)->
      @name = "Mustard Syntax Error"
      # Error.apply( @, [@message])
    toString: -> "#{@file}:#{@line} (col:#{@col}) #{@message}"

class Text
    constructor: (obj)->
        @partials = obj.text
        
    toString: -> @partials
    toHtml: -> @partials


class ElementList
    constructor: ->
      @elements = []

    push: (el)-> @elements.push el
    length: ()-> @elements.length

    toHtml: -> ( child.toHtml() for child in @elements)


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

    toHtml: ()->
        ['<', @name, @attributeTexts(), '>', @children.toHtml(), '</', @name, ">"]
        
    attributeTexts: ()->
        attributeTexts = []
        for k,v of @attributes
            attributeTexts.push ' ' , k , '="' , ([a.toHtml(), ' '] for a in v) , '"'

        for attr in @interpolated_attributes
            attributeTexts.push ' ', attr.name.toHtml(), '="' , attr.value.toHtml(), '"'

        attributeTexts



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


class FileParser

    constructor: ->
        @parser = new Parser()

    parse: (filename)->
        @parser.parse fs.readFileSync(filename)

    tokenList: ()-> @parser.tokenList()



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
root.Parser = Parser
root.FileParser = FileParser
root.ElementList = ElementList
root.Element = Element
root.Text = Text
