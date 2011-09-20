{mustard:{Interpolator}} = require '../src/interpolator'

class MockToken
  constructor: (@_type, @_attributes)->
  type: -> @_type
  contents: -> @_attributes.contents

txt = (content)-> new MockToken 'text', contents: content
int = (val)-> new MockToken 'int', contents: val

class MockStreamReader
  constructor: (tokens...)->
    @tokens = []
    @addTokens tokens...
    @idx = -1
    
  read: ->
    @idx++
    if @idx >= @tokens.length
      @idx = @tokens.length
      return null
    else
      @tokens[@idx]

  atEnd: -> @idx >= @tokens.lenght

  addTokens: (tokens...)->
    for t in tokens
      t = txt(t) if typeof t == 'string'
      # console.log t
      @tokens.push t


describe 'Interpolator', ->
  reader = null
  interpolator = null


  beforeEach ->
    interpolator = new Interpolator
    # reader = new MockStreamReader '<p', '>', 'hello', 'world', '</p>'
      


  it 'should produce a concatendated string', ->
    reader = new MockStreamReader '<p', '>', 'hello ', 'world', '</p>'
    output = interpolator.linearize_stream reader
    expect(output).toEqual ['<p>hello world</p>']


  it 'should produce an output list of tokens for interpolation', ->
    reader = new MockStreamReader '<p', '>', 'hello ', int('world'), '</p>'
    output = interpolator.linearize_stream reader
    expect(output).toEqual ['<p>hello ', {type:'int', contents:'world' } ,'</p>']

