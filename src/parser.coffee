fs = require 'fs'
PEG = require "pegjs"

class MustardSyntaxError extends Error
    constructor: (@file, @line, @col, @message, @base_exception)->
      @name = "Mustard Syntax Error"
      # Error.apply( @, [@message])
    toString: -> "#{@file}:#{@line} (col:#{@col}) #{@message}"

InterpolationRegexp = /\{\{(.*?)\}\}/g

class Text
    constructor: (@text)->
        @partials = []
        
        for m in @text.match InterpolationRegexp
          parts = InterpolationRegexp.exec m
          @partials.push parts[1]
    toString: -> @text
    toHtml: -> @text


class ElementList
    constructor: ->
      @elements = []

    push: (el)-> @elements.push el

    toHtml: -> ( child.toHtml() for child in @elements).join("\n")


class Element
    constructor: (hash, @children)->
        @name = hash.declaration.name
        @attributes= {}
        attr_cache = {}
        # console.log 'hash:', hash.declaration.attributes
        for attrs in hash.declaration.attributes
            for k,v of attrs
                # console.log 'attr_pairs:', k, v
                attr_cache[k] ||= []
                attr_cache[k].push v

        for k,v of attr_cache
          @attributes[k] = v.join(' ')

    toHtml: ()->
      "<#{@name}#{(' ' + k + '="' + v + '"' for k,v of @attributes).join('')}>#{@children.toHtml()}</#{@name}>"
        


class Parser

    constructor:  ->
      @grammar = fs.readFileSync "#{__dirname}/mustard.pegjs"
      @parser = PEG.buildParser @grammar.toString()
      @astConverter = new AstConverter
      # console.log @parser.toSource()

    parseFile: (fileName)->
        @tokens = @parseIntoTokenList fileName
        ast = @astConverter.listToAst @tokens
        console.log ast.toHtml()
        return ast
          

    parseIntoTokenList: (fileName)->
        contents = fs.readFileSync fileName
        try
            result = @parser.parse contents.toString()
            return result
        catch e
            if e.name is "SyntaxError"
                # throw e
                throw new MustardSyntaxError(fileName, e.line, e.column, e.message, e)
            throw e



class AstConverter
    constructor: ->
    listToAst: (list_in)->
        res = new ElementList
        for el in list_in
            res.push @elementFor(el)
        res
    
    elementFor: (obj)->
        
        # wtf this needs typeof instead of instanceof is beyond me
        if typeof obj is 'string'
            return new Text(obj)

        if obj instanceof Object and (obj.type == 'element')
          children = new ElementList
          if obj.contents instanceof Array
            children = @listToAst(obj.contents)
          return new Element(obj, children)
        


root = exports ? this
root.Parser = Parser
