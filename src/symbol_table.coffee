{mustard:{Token, TokenStream}} = require './token_stream'


class TextToken extends Token
  constructor: (contents, isInterpolated=false)->
    super 'text', contents: contents, isInterpolated: isInterpolated, false

  contents: -> @_attributes.contents
  _dup: -> new TextToken @contents()
  toString: -> "text:#{@contents()}"


class SymbolCallToken extends Token
  constructor: (symbolName)->
    super 'symbol', name: symbolName, true

  name: -> @_attributes.name
  _dup: -> new SymbolCallToken @name()


class YieldToken extends Token
  constructor: -> super 'yield', {}, false
  _dup: -> new YieldToken
 


class Symbol extends TokenStream
  constructor: (@_name)->
    super()

  name: -> @_name

  # Get the dependencies of this symbol.
  #
  dependencies: ->
    deps = {}
    @eachToken true, (t)->
      return unless t.type() is 'symbol'
      deps[t.name()] = true

    deps

    # sort the dependencies alphabetically (for testing and constant
    # ordering )
    (k for k, _ of deps).sort()


  yield: (innerTokens)->
    out_tokens = @duplicate()
    out_tokens.replaceRecursive('yield', {}, innerTokens)
    out_tokens


    



class SymbolTable
  constructor: ->
    @_symbols = {}


  add: (symbol)->
    # allow only Symbols
    throw new Error("SymbolTable only accepts Symbol objects") unless symbol instanceof Symbol
    @_symbols[symbol.name()] = symbol


  get: (name)->
    @_symbols[name]


  # get a resolved symbol
  resolved: (name)->
    # dupe it so any resolving happens on a copy
    symbol = @get(name)
    throw new Error("Cannot find symbol for resolving: #{name}") unless symbol
    symbol.duplicate()

    dependencies = symbol.dependencies()

    # does the symbol have any dependencies?
    hasDependencies = dependencies.length > 0

    while hasDependencies
      # get the next dependency to resolve
      #
      depName = dependencies.shift()
      dependency = @get depName
      throw new Error("Can't find dependency symbol: #{depName} -- dependencies: #{dependencies} -- in: #{name}") unless dependency
      
      # add the dependency's dependencies to the current symbol's
      # dependencies
      dependencies.push dependency.dependencies()...

      # replace symbol calls
      symbol.replaceRecursive 'symbol', {name: depName}, (t)->
        dependency.yield( t.children().tokens() ).tokens()
        # dependency.tokens()

      # do we have any more dependencies?
      hasDependencies = dependencies.length > 0


    return symbol



    


root = exports ? this
root.mustard or= {}
root.mustard.Symbol = Symbol
root.mustard.SymbolTable = SymbolTable
root.mustard.TextToken = TextToken
root.mustard.YieldToken = YieldToken
root.mustard.SymbolCallToken = SymbolCallToken
