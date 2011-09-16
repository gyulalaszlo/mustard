{mustard:{Token, TokenStream}} = require '../src/token_stream'

# console.log mustard
#
tok_ = (type,attrs, hasChildren)->  new Token type, attrs, hasChildren
text = (txt)-> tok_ 'text', contents:txt


describe 'Token', ->
  
  describe '#constructor', ->
    it 'should get the type', ->
      t = new Token 'text', contents:'<p>', false
      expect( t.type() ).toEqual 'text'
      expect( t.attributes() ).toEqual contents:'<p>'
      expect( t.hasChildren() ).toEqual false

    # it 'should allow the children only if hasChildren is true', ->



describe 'TokenStream', ->
  stream = null
  
  beforeEach ->
    stream = new TokenStream()
    
  describe '#push', ->

    it 'should reject invalid tokens', ->
      expect( -> stream.push null ).toThrow()
      expect( -> stream.push 'invalid' ).toThrow()
      expect( -> stream.push {contents:"lacks type"} ).toThrow()


    
    it 'should return pushed tokens in order', ->
      token = new Token('text', contents:"<p></p>")
      token2 = new Token('text', contents:"<b></b>")
      stream.push token for i in [0..2]
      stream.push token2
      expect( stream.tokens() ).toEqual [ token, token, token, token2 ]
      
  
  describe '#replace', ->
    presets = [text("<p>"), tok_('symbol', name:'b', true), text("</p>") ]
    replace_text = text('replaced')

    beforeEach ->
      stream.push t for t in presets

    it 'should replace all tokens in the stream if no filter object is given', ->
      stream.replace 'text', null, [ replace_text ]
      expect( stream.tokens() ).toEqual [
        replace_text, presets[1], replace_text ]
      
    it 'should replace the matching tokens in the stream', ->
      stream.replace 'text', contents:"<p>", [ replace_text ]
      expect( stream.tokens() ).toEqual [
        replace_text, presets[1], presets[2]]

