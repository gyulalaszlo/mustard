{mustard:{Token}} = require './token'
{mustard:{TokenStream}} = require './token_stream'




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
 

class YieldAttrToken extends Token
  constructor: (attrName)->
    super 'yield:attr', name:attrName, false

  name: -> @_attributes.name
  _dup: -> new YieldAttrToken @name()
 



class InterpolateToken extends Token
  constructor: (symbolName)->
    super 'int', name: symbolName, true

  name: -> @_attributes.name
  _dup: -> new InterpolateToken @name()



class AttrScopeToken extends Token
  constructor: (name, parameters=[])->
    super 'scope:attr', name: name, parameters:parameters, true

  name: -> @_attributes.name
  parameters: -> @_attributes.parameters

  _dup: -> new AttrScopeToken @name(), @parameters()




  resolve: (attributes)->
    # get the object open by the scope 
    obj = if @name() is '@' then attributes else attributes[@name()]
    
    console.log "----> Resolving: #{obj} -- #{ JSON.stringify obj, null, 2}" if Symbol.debug

    # no such attribute? return an empty token stream
    return [] unless obj

    params = @parameters()

    # If no parameters given, just return the child tokens.
    if params.length == 0
      return @children().duplicate()

    # Two params? iterate!
    if params.length == 2

      # create a new tokenstream for the output
      out = new TokenStream

      # iterate over the attributes given
      for attr_name, attribute of obj
        # skip the $$content attribute that's used for
        # 
        continue if attr_name is Token.children

        # console.log "A: #{attr_name} '#{@name()}' resolve:", attribute,
          # Object.getPrototypeOf(attribute)

        @children().eachToken true, (t)->

          # replace interpolation instances
          if t.type() is 'int'

            # add the key 
            if t.name() is params[0]
              out.push new TextToken( attr_name )
              return

            # add the children stream
            if t.name() is params[1]
              out.pushStream attribute
              return


          # if not interpolated, add this
          out.push t.clone()

      return out
    
      









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
      console.log "Found scope:attr token:#{t}" if Symbol.debug
      tokens = t.resolve attributesTokens
      console.log "Resolved to: #{tokens}" if Symbol.debug
      tokens

    for name, children of attributesTokens
      out_tokens.replaceRecursive 'yield:attr', {name: name}, (t)->
        # console.log "Found yield:attr: name:#{name} token:#{t}" if Symbol.debug
        children

    out_tokens



  yieldWith: (symbolCall)->
    # out_tokens = @duplicate()
    callerContents = symbolCall.children().tokens()
    callerAttributes = symbolCall.allChildren()
    @yield( callerContents, callerAttributes )


    



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
        dependency.yieldWith( t )
        # dependency.yield( t.children().tokens(), t.childrenHash() ).tokens()
        # dependency.tokens()
        #
      
      # do we have any more dependencies?
      hasDependencies = dependencies.length > 0


    return symbol



    


root = exports ? this
root.mustard or= {}
root.mustard.Symbol = Symbol
root.mustard.SymbolTable = SymbolTable
root.mustard.TextToken = TextToken
root.mustard.YieldToken = YieldToken
root.mustard.YieldAttrToken = YieldAttrToken
root.mustard.InterpolateToken = InterpolateToken
root.mustard.AttrScopeToken = AttrScopeToken
root.mustard.SymbolCallToken = SymbolCallToken
