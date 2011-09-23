class Interpolator


  linearize_stream: (reader)->
    @resetBuffers()
    while token = reader.read()
      switch token.type()
        when 'text' then @pushString token.contents()
        when 'int'  then @pushInterpolate token.name()
        else throw new Error("Unknown token type in interpolator: #{token.type()}")

    @flushBuffer()
    @output


  resetBuffers: -> @output = []; @buffer = []
  flushBuffer: -> @output.push @buffer.join(''); @buffer=[]

  pushString: (txt)-> @buffer.push txt
  pushInterpolate: (contents)->
    @flushBuffer(); @output.push type:'int', contents:contents







root = exports ? this
root.mustard or= {}
root.mustard.Interpolator = Interpolator
