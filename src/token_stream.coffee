{$meta} = require './meta'


class TokenGenerator
  @text

class Token
  @_children = '$$children'

  constructor: (@_type, @_attributes, @_hasChildren=false)->
    # if the token has children, set up the children hash here.
    # We use a hash because attributes can also be considered children.
    if @_hasChildren
      @_children = {}
      @_children[ Token.children ] = new TokenStream

  attributes: -> @_attributes
  hasChildren: -> @_hasChildren
  type: -> @_type

  toString: -> "#{@_type}, #{JSON.stringify @_attributes}"

  # get the child token stream (or null if hasChildren is false)
  children: (child_key=Token.children)-> @_children[child_key]

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
  #
  # - filterObject: the object to filter the tokens by
  #
  # - replacementTokens: 
  #   Either an array of replacement tokens,
  #   Or a function(token) { ... return [<replacement list>...] or false }
  #
  replace: (tokenType, filterObject={}, replacement_tokens=[], is_recursive=false)->
    replacement_function = switch typeof replacement_tokens
      when 'function' then replacement_tokens
      # Array is an object. 
      when 'object' then (tokens)-> replacement_tokens
      else throw new Error "TokenStream#replace replacement_tokens must be a list or function."

    # find all occurences of a tokentype
    _idx = 0
    while _idx < @_tokens.length
      i = _idx; _idx++
      t = @_tokens[i]
      
      # Depth-first search, so replace the children first
      if is_recursive and t.hasChildren()
        t.children().replace tokenType, filterObject, replacement_tokens, is_recursive

      continue unless t._type is tokenType
    
      # filter by object
      if filterObject and t.matchesFilter( filterObject )
        # replace the token with the matching replacement tokens
        replacementList = replacement_function( t )

        # throw an error if these aren't tokens
        validateTokenList replacementList
        @_tokens[i..i] = replacementList
  

  toString: -> ( tok.toString() for tok in @_tokens ).join(',')
  


validateTokenList = (tokenarr)->
  for token in tokenarr
    throw new Error("Invalid token given: #{token}") unless token instanceof Token



root = exports ? this
root.mustard or= {}
root.mustard.TokenGenerator = TokenGenerator
root.mustard.Token= Token
root.mustard.TokenStream = TokenStream


