{mustard:{Token, TokenStream}} = require '../src/token_stream'

# console.log mustard
#
tok_ = (type,attrs, hasChildren)->  new Token type, attrs, hasChildren
text = (txt)-> tok_ 'text', contents:txt

symbol = (name, children, childChannels={}) ->
  token = tok_ 'symbol', name:name, true
  for c in children
    token.children().push c

  for name, chan of childChannels
    for c in chan
      token.children(name).push c
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

    
    it 'should push a tokenstream to the stream', ->
      token = new Token('text', contents:"<p></p>")
      token2 = new Token('text', contents:"<b></b>")
      stream.push(token) for i in [0..2]
      stream.push token2

      stream2 = new TokenStream()
      stream2.pushStream stream

      expect( stream.tokens() ).toEqual [ token, token, token, token2 ]
 

  describe 'stream operations', ->
    gen_presets = -> [
      text("<p>"),
      symbol('b',[ text('<b>'), text('hello'), text('</b>')], attr:[text('other_channel')] ),
      text("</p>") ]

    presets = []
    replace_text = text('replaced')

    beforeEach ->
      presets = gen_presets()
      stream.push(t ) for t in presets

  
    describe '#replace', ->


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

      it 'should replace the matching tokens in all child streams', ->
        stream.replaceRecursive 'text', contents:"other_channel", [ replace_text ]
        expect( presets[1].children('attr').tokens()[0] ).toEqual replace_text


      
      describe 'with a yield function', ->

        it 'should call the block with the tokens for each occurance', ->
          idx = 0
          stream.replace 'text', null, (token)->
            expect( token ).toEqual presets[idx] unless idx is 1
            idx++
            replace_text

          expect( stream.tokens() ).toEqual [
            replace_text, presets[1], replace_text ]



    describe '#each', ->

      it 'should iterate over the list of the stream', ->
        idx = 0
        found_p = false
        stream.eachToken (t)->
          expect( t instanceof Token).toEqual true
          found_p = true if t is presets[1]
          idx++

        expect(idx).toEqual 3
        expect(found_p).toEqual true

      it 'should iterate over the list of the stream recursively', ->
        idx = 0
        found_hello = false
        stream.eachToken true, (t)->
          expect( t instanceof Token).toEqual true
          found_hello = true if t.attributes().contents is 'hello'
          idx++

        expect(idx).toEqual 6
        expect(found_hello).toEqual true



    describe '#duplicate', ->
        
      it 'should duplicate the contents of the stream', ->
        duped = stream.duplicate()
        expect( duped.tokens() ).not.toEqual duped.tokens
        
        test = []; tokens = []
        stream.eachToken true, (t)->
          o = {}
          o[k] = t[k]() for k in ['type', 'attributes']
          tokens.push t
          test.push o
        
        idx = 0
        duped.eachToken true, (t)->
          exp = test[idx]
          for k in ['type', 'attributes']
            expect( t[k]() ).toEqual( exp[k] )

          expect( tokens[idx] ).not.toBe( t )
          idx++

        expect(idx).toEqual( test.length )

          

