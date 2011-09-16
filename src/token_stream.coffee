{$meta} = require './meta'


class TokenGenerator
  @text

class Token
  constructor: (@_type, @_attributes, @_hasChildren=false)->

  attributes: -> @_attributes
  hasChildren: -> @_hasChildren
  type: -> @_type

  toString: -> "#{@_type}, #{JSON.stringify @_attributes}"


  matchesFilter: (filterObject)->
    # check the fields
    for k,v of filterObject
      return false unless @_attributes[k] is v

    true


class TokenStream
  constructor: ->
    @_tokens = []


  push: (token)->
    throw new Error("Invalid token given: #{token}") unless token instanceof Token
    @_tokens.push token

  tokens: -> @_tokens


  # replace all occurences of a token
  #
  # - tokenType: the type of the token
  # - filterObject: the object to filter the tokens by
  # - replacementTokens: an array of replacement tokens
  #
  replace: (tokenType, filterObject={}, replacement_tokens=[])->
    # find all occurences of a tokentype
    _idx = 0
    while _idx < @_tokens.length
      i = _idx; _idx++
      t = @_tokens[i]

      continue unless t._type is tokenType
    
      # filter by object
      if filterObject and t.matchesFilter( filterObject )
        # replace the token with the matching replacement tokens
        @_tokens[i..i] = replacement_tokens

  


root = exports ? this
root.mustard or= {}
root.mustard.TokenGenerator = TokenGenerator
root.mustard.Token= Token
root.mustard.TokenStream = TokenStream


