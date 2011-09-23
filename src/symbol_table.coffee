{mustard:{Token}} = require './token'
{mustard:{TokenStream}} = require './token_stream'


class Symbol extends TokenStream
  @debug = false

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


  yield: (innerTokens, attributesTokens={})->
    out_tokens = @duplicate()
    out_tokens.replaceRecursive 'yield', {}, innerTokens

    out_tokens.replaceRecursive 'scope:attr', {}, (t)->
      tokens = t.resolve attributesTokens
      tokens

    for name, children of attributesTokens
      out_tokens.replaceRecursive 'yield:attr', {name: name}, (t)->
        children

    out_tokens



  yieldWith: (symbolCall)->
    callerContents = symbolCall.children().tokens()
    callerAttributes = symbolCall.allChildren()
    @yield( callerContents, callerAttributes )


    



class SymbolTable

  constructor: ->
    @_symbols = {}

  
  # add a symbol to the symbol table
  add: (symbol)->
    # allow only Symbols
    throw new Error("SymbolTable only accepts Symbol objects") unless symbol instanceof Symbol
    @_symbols[symbol.name()] = symbol

  
  # get a symbol by name
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
      depName = dependencies.shift()
      dependency = @get depName
      throw new Error("Can't find dependency symbol: #{depName} -- dependencies: #{dependencies} -- in: #{name}") unless dependency
      
      # add the dependency's dependencies to the current symbol's
      # dependencies
      dependencies.push dependency.dependencies()...

      # replace symbol calls
      symbol.replaceRecursive 'symbol', {name: depName}, (t)->
        dependency.yieldWith( t )
      
      # do we have any more dependencies?
      hasDependencies = dependencies.length > 0


    return symbol



    


root = exports ? this
root.mustard or= {}
root.mustard.Symbol = Symbol
root.mustard.SymbolTable = SymbolTable
