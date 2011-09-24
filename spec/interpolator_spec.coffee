{mustard:{Token}} = require '../src/token_stream'
{mustard:{Interpolator}} = require '../src/interpolator'
{mustard:{TokenStream}} = require '../src/token_stream'

{yield_, yieldattr_, scope, _stream, symcall_, intp_, attrscope_, symcallparam_, sym_, to_text} = require './spec_helper'

# txt = (content)-> new TextToken content
# int = (val)-> new InterpolateToken val

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
      t = txt_(t) if typeof t == 'string'
      # console.log t
      @tokens.push t


expect_to_text = (stream,expectation)->
  expect( to_text( stream )).toEqual expectation


describe 'Interpolator', ->
  reader = null
  interpolator = null


  beforeEach ->
    interpolator = new Interpolator
    # reader = new MockStreamReader '<p', '>', 'hello', 'world', '</p>'
      


  it 'should produce a concatendated string', ->
    reader = stream '<p', '>', 'hello ', 'world', '</p>'
    output = interpolator.linearize_stream reader
    expect_to_text output, '<p>hello world</p>'


  it 'should produce an output list of tokens for interpolation', ->
    interp = intp_('world')
    reader = stream '<p', '>', 'hello ', interp, '</p>'
    output = interpolator.linearize_stream reader
    expect_to_text output, '<p>hello ,INT:world,</p>'
  
  it 'should ', ->
    scopet = scope 'foo', ['bar', 'baz'], '<p', '>', intp_('baz'), '<','/p>'
    reader = stream '<b', '>', scopet, '</', 'b>'

    output = interpolator.linearize_stream reader
    expect_to_text output, '  '
