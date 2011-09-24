{mustard:{TextToken, InterpolateToken, ScopeToken}} = require './token_types'
{mustard:{TokenStream}} = require './token_stream'

class Interpolator


  linearize_stream: (stream)->
    output = new TokenStream()
    buf = new InterpolatorBuffer()

    # @resetBuffers()
    for token in stream.tokens()
      token_type = token.type()
  
      if token_type is 'text' then buf.push token.contents()
      else buf.flushTo output

      # console.log token.type()
      
      
      switch token.type()
        when 'text' then
        when 'int'  then output.push token
        when 'scope'
          t = token.clone()
          # get a clone and linearize the child stream recursively
          children = token.allChildren()
          linearized_child_streams = {}

          console.log t, children
          for name, child_stream of children
            t._children[name] = @linearize_stream child_stream

          

          output.push t
        else throw new Error("Unknown token type in interpolator: #{token.type()}")

    buf.flushTo output
    output



class InterpolatorBuffer
  constructor: -> @clear()
  push: (str)-> @buffer.push str
  toTextToken: -> new TextToken @buffer.join('')
  clear: -> @buffer = []

  flushTo: (stream)-> 
    return unless @buffer.length > 0
    stream.push(@toTextToken())
    @clear()




root = exports ? this
root.mustard or= {}
root.mustard.Interpolator = Interpolator
