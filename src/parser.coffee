fs = require 'fs'
PEG = require "pegjs"

class MustardSyntaxError
    constructor: (@file, @line, @col, @message, @base_exception)->
    toString: -> "#{@file}:#{@line} (col:#{@col}) #{@message}"

class Text
    constructor: (@text)->
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
        console.log "Parsing: #{fileName}"
        list = @parseIntoList fileName
        ast = @astConverter.listToAst list
        console.log ast.toHtml()
        return ast
        # contents = fs.readFileSync @fileName
        # try
        #     result = @parser.parse contents.toString()
        #     console.log @astConverter.listToAst result
        #     return result
        # catch e
        #     # throw new MustardSyntaxError()
        #     console.error e
        #     throw e
        # # console.log(data, data.toString())
          

    parseIntoList: (fileName)->
        contents = fs.readFileSync fileName
        try
            result = @parser.parse contents.toString()
            return result
        catch e
            console.error e
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
