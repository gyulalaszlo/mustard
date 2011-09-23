{mustard:{TokenStream}} = require './token_stream'

class Symbol extends TokenStream
  @debug = false

  constructor: (@_name)->
    super()

  name: -> @_name

  # Get the dependencies of this symbol.
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


root = exports ? this
root.mustard or= {}
root.mustard.Symbol = Symbol
