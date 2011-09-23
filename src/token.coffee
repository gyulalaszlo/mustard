# {mustard:{TokenStream}} = require './token_stream'

class Token
  @children = '$$children'
  @childStreamType = null

  constructor: (@_type, @_attributes, @_hasChildren=false)->
    # if the token has children, set up the children hash here.
    # We use a hash because attributes can also be considered children.
    if @_hasChildren
      @_children = {}
      # @_children[ Token.children ] = new TokenStream

  attributes: -> @_attributes
  hasChildren: -> @_hasChildren
  type: -> @_type

  toString: -> "#{@_type}=>#{JSON.stringify @_attributes}"

  
  # Return the hash containing all the children
  allChildren: -> @_children

  # get the child token stream (or null if hasChildren is false)
  children: (child_key=Token.children)->
    unless Token.childStreamType
      throw new Error("Token.childStreamType is set to null - set it to a child stream class")
    @_children[child_key] ||= new Token.childStreamType

  matchesFilter: (filterObject)->
    # check the fields
    for k,v of filterObject
      return false unless @_attributes[k] is v
    true

    
  # create a shallow clone with duplicated tokens
  clone: ->
    o = @_dup()

    # duplicate the children (for later manipulation)
    if @_hasChildren
      o._children = {}
      for k, v of @_children
        o._children[k] = v.duplicate()

    o

  _dup: -> new Token(@_type, @_attributes, @_hasChildren)



root = exports ? this
root.mustard or= {}
root.mustard.Token= Token
