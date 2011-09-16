{mustard:{Token, TokenStream}} = require '../src/token_stream'

# console.log mustard
#
tok_ = (type,attrs, hasChildren)->  new Token type, attrs, hasChildren
text = (txt)-> tok_ 'text', contents:txt

symbol = (name, children) ->
  token = tok_ 'symbol', name:name, true
  for c in children
    token.children().push c
  token


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
      stream.push(token) for i in [0..2]
      stream.push token2
      expect( stream.tokens() ).toEqual [ token, token, token, token2 ]
      
  
  describe '#replace', ->

    gen_presets = -> [
      text("<p>"),
      symbol('b',[ text('<b>'), text('hello'), text('</b>')] ),
      text("</p>") ]

    presets = []
    replace_text = text('replaced')

    beforeEach ->
      presets = gen_presets()
      stream.push(t ) for t in presets


    it 'should replace all tokens in the stream if no filter object is given', ->
      stream.replace 'text', null, [ replace_text ]
      expect( stream.tokens() ).toEqual [
        replace_text, presets[1], replace_text ]
      
    it 'should replace the matching tokens in the stream', ->
      stream.replace 'text', contents:"<p>", [ replace_text ]
      expect( stream.tokens() ).toEqual [
        replace_text, presets[1], presets[2]]


    it 'should replace the matching children tokens in the stream', ->
      stream.replace 'text', contents:"<b>", [ replace_text ], true
      expect( presets[1].children().tokens()[0] ).toEqual replace_text

    
    describe 'with a yield function', ->

      it 'should call the block with the tokens for each occurance', ->
        idx = 0
        stream.replace 'text', null, (token)->
          expect( token ).toEqual presets[idx] unless idx is 1
          idx++
          replace_text

        expect( stream.tokens() ).toEqual [
          replace_text, presets[1], replace_text ]
