{mustard:{Symbol, SymbolTable, TextToken, YieldToken, SymbolCallToken}} = require '../src/symbol_table'

_pushChildren = (s, children)->
  stream = if s.children then s.children() else s
  for c in children
    c = [c] unless c instanceof Array
    for child in c
      child = txt_(child) if typeof child is 'string'
      stream.push(child)
  return s

yield_ = -> new YieldToken
yieldattr_ = (name)-> new YieldAttrToken(name)
txt_ = (txt)-> new TextToken(txt)
symcall_ = (name, children...)-> _pushChildren new SymbolCallToken(name), children
sym_ = (name, children...)-> _pushChildren new Symbol(name), children

to_text= (s)->
  o = []
  s.eachToken true, (t)->
    o.push switch t.type()
      when 'text' then t.contents()
      when 'symbol' then "SYM:#{t.name}:#{to_text t}"
      when 'yield' then "YIELD"
      when 'yield:attr' then "YIELD:ATTR:#{t.name()}"
  
  o.join(',')


expectResolved = (symbol_table, symbol_name, result)->
  expect( to_text( symbol_table.resolved(symbol_name))).
    toEqual result


describe 'Symbol', ->
  s = null

  beforeEach ->
    s = new Symbol 'p'

  it 'should have a name', ->
    expect( s.name() ).toEqual( 'p' )

  describe 'dependency resolve', ->

    it 'should resolve its dependencies', ->
      space = new SymbolCallToken("space")
      space.children().push new TextToken(" ")
      space.children().push new SymbolCallToken("nbsp")
      space.children().push new TextToken(" ")

      s.push new TextToken("<p>")
      s.push new SymbolCallToken("hello")
      s.push space
      s.push new SymbolCallToken("world")
      s.push new TextToken("</p>")

      # alphabetized dependency list
      expect( s.dependencies() ).toEqual ['hello', 'nbsp', 'space', 'world']
  

  describe 'yielding', ->

    it 'should replace the yield token with the contents when yielding', ->
      s.push txt_ "<p>"
      s.push yield_()
      s.push txt_ "</p>"

      expect( to_text( s.yield( [txt_("hello")] ) )).toEqual '<p>,hello,</p>'



describe 'SymbolTable', ->
  st = null

  beforeEach ->
    st = new SymbolTable()


  describe 'lookup', ->

    it 'should return the given symbols', ->
      sym1 = new Symbol('p')
      sym2 = new Symbol('b')
      st.add sym1; st.add sym2
      expect( st.get 'p' ).toEqual sym1
      expect( st.get 'b' ).toEqual sym2


  describe 'dependency resolving', ->

    it 'should resolve dependencies', ->
      st.add(sym_ 'p', "<p>", "</p>")
      st.add(sym_ 'para', symcall_('p'))
      expectResolved st, 'para', '<p>,</p>'


    beforeEach ->
      st.add sym_( 'p', "<p>", symcall_('b', yield_() ) , "</p>" )
      st.add sym_( 'b', "<b>", yield_() , "</b>" )


    it 'should resolve dependencies and yields', ->
      st.add( sym_ 'bold',  symcall_('b', 'Hello world!') )
      expectResolved st, 'bold', '<b>,Hello world!,</b>'


    it 'should resolve dependencies and yields deeper', ->
      st.add sym_('boldpara',  symcall_('p', 'Hello world!' ))

      # the result should be constant (the symbol table
      # itself shouldn't change
      expectResolved st, 'boldpara', '<p>,<b>,Hello world!,</b>,</p>'
      expectResolved st, 'boldpara', '<p>,<b>,Hello world!,</b>,</p>'
      expectResolved st, 'b', '<b>,YIELD,</b>'
      expectResolved st, 'p', '<p>,<b>,YIELD,</b>,</p>'


    it 'should resolve attribute yields', ->
      st.add sym_( 'a', "<a href='", yieldattr_('href'), "'>", yield_(), "</a>" )
      st.add sym_( 'link', symcall_('a'))

      expectResolved st, 'link', "<a href=',YIELD:ATTR:href,'>,YIELD,</a>"






