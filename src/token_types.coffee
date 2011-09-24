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



class ScopeToken extends Token
  constructor: (name, parameters=[])->
    super 'scope', name: name, parameters:parameters, true

  name: -> @_attributes.name
  parameters: -> @_attributes.parameters

  _dup: -> new ScopeToken @name(), @parameters()





class AttrScopeToken extends Token
  constructor: (name, parameters=[])->
    super 'scope:attr', name: name, parameters:parameters, true

  name: -> @_attributes.name
  parameters: -> @_attributes.parameters

  _dup: -> new AttrScopeToken @name(), @parameters()




  resolve: (attributes)->
    # get the object open by the scope 
    obj = if @name() is '@' then attributes else attributes[@name()]

    # no such attribute? return an empty token stream
    return [] unless obj

    params = @_attributes.parameters

    # If no parameters given, just return the child tokens.
    if params.length == 0
      return @children().duplicate()

    # Two params? iterate!
    if params.length == 2

      # create a new tokenstream for the output
      out = new TokenStream

      # iterate over the attributes given
      for attr_name, attribute of obj

        # skip this attribute $$content attribute that's used for
        continue if attr_name is Token.children
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
    
      







root = exports ? this
root.mustard or= {}
root.mustard.TextToken = TextToken
root.mustard.ScopeToken = ScopeToken
root.mustard.YieldToken = YieldToken
root.mustard.YieldAttrToken = YieldAttrToken
root.mustard.InterpolateToken = InterpolateToken
root.mustard.AttrScopeToken = AttrScopeToken
root.mustard.SymbolCallToken = SymbolCallToken
