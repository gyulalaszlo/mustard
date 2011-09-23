{mustard:{Symbol}} = require './symbol'

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
root.mustard.SymbolTable = SymbolTable
