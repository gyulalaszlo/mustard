{mustard:{Symbol, SymbolTable, TextToken, YieldAttrToken, YieldToken, InterpolateToken, AttrScopeToken, SymbolCallToken}} = require '../src/symbol_table'
{mustard:{TokenStream}} = require '../src/token_stream'

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

intp_ = (name)-> new InterpolateToken( name )

attrscope_ = (name, params, children...)->
  _pushChildren new AttrScopeToken( name, params ), children

symcallparam_ = (name, attributes, children...)->
  sct =  new SymbolCallToken(name)
  _pushChildren sct, children
  for k, v of attributes
    _pushChildren sct.children(k), v
  sct

sym_ = (name, children...)-> _pushChildren new Symbol(name), children

to_text= (s, debug= false)->
  o = []
  s.eachToken false, (t)->
    o.push switch t.type()
      when 'text' then t.contents()
      when 'symbol'
        "<SYM:#{t.name()}>"+
          ("#{ if k is '$$children' then '' else k.toString() + '=>'}#{to_text(ch)}" for k,ch of t.allChildren()).join('') +
        "</SYM:#{t.name()}>"
      when 'yield' then "YIELD"
      when 'yield:attr' then "YIELD:ATTR:#{t.name()}"
      else "UNKNOWN:#{t}"

    console.log o if debug
  
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
      _pushChildren s, ['<p>',  yield_(), '</p>']
      res =  to_text( s.yield( [txt_("hello")] ) )
      expect( res ).toEqual '<p>,hello,</p>'


    it 'should replace the attribute yields', ->
      attr_sym = _pushChildren new TokenStream, ['hello', 'world']
      _pushChildren s, ['<p>', yieldattr_('attr'), yield_(), '</p>']

      res = s.yield( [txt_("!")], attr: attr_sym)
      expect( to_text(res) ).toEqual '<p>,hello,world,!,</p>'
      


    it 'should replace the nested attribute yields', ->
      attr_sym = _pushChildren new TokenStream, ['hello', 'world']
      _pushChildren s, ['<p>',
        symcall_( 'b', yieldattr_('attr'),'(', yield_(),')'),
        '</p>'
      ]
      res = s.yield( [txt_("!")], attr: attr_sym)
      expect( to_text(res) ).toEqual '<p>,<SYM:b>hello,world,(,!,)</SYM:b>,</p>'



    it 'should replace the attribute yields in all children', ->
      attr_sym = _pushChildren new TokenStream, ['hello', 'world']

      _pushChildren s, ['<p>',
        symcallparam_( 'b', class:[ yieldattr_('attr'), '(', yield_(), ')' ])
        '</p>'
      ]
      res = s.yield( [txt_("!")], attr: attr_sym)
      expect( to_text(res) ).toEqual '<p>,<SYM:b>class=>hello,world,(,!,)</SYM:b>,</p>'
   



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
      st.add sym_( 'link', symcallparam_('a', href:['/']))

      expectResolved st, 'a', "<a href=',YIELD:ATTR:href,'>,YIELD,</a>"
      expectResolved st, 'link', "<a href=',/,'>,</a>"


    it 'should resolve nested attributes', ->
      st.add sym_( 'a', "<a class='", yieldattr_('class'), "' href='", yieldattr_('href'), "'>", yield_(), "</a>" )
      st.add sym_( 'p', "<p class='", yieldattr_('class'), "'>", yield_(), "</p>" )
      st.add(
        sym_( 'linkp',
          symcallparam_('p', class:['para'],
            symcallparam_('a', class:['link'], href:['/'], "hello" )
          )
        )
      )

      expectResolved st, 'linkp', "<p class=',para,'>,<a class=',link,' href=',/,'>,hello,</a>,</p>"
      expectResolved st, 'a', "<a class=',YIELD:ATTR:class,' href=',YIELD:ATTR:href,'>,YIELD,</a>"
      expectResolved st, 'p', "<p class=',YIELD:ATTR:class,'>,YIELD,</p>"
      
    
    describe 'attribute scope resolving', ->

      beforeEach ->
        st.add(
          sym_('a', "<a",
            attrscope_('@', ['name', 'value'], ' ', intp_('name'), "='", intp_('value'), "'" ),
            '>', yield_(), '</a>'
          )
        )
 

      it 'should resolve attribute scopes', ->
        st.add( sym_('link',
          symcallparam_('a',
            class:['link'], href:['/'], target:['_blank'],
            "hello" )
          )
        )
        expectResolved st, 'link',
          "<a, ,class,=',link,', ,href,=',/,', ,target,=',_blank,',>,hello,</a>"
    

      it 'should resolve nested attribute yields', ->
        st.add(
          sym_('div', "<div",
            attrscope_('class', [], " class='", yieldattr_('class'), "'" ),
            '>',
            symcallparam_( 'a',
              class:[ yieldattr_('a_class') ],
              href:['/'], target:['_blank'],
              yield_()
            )
            yield_(), '</div>'
          )
        )

        st.add( sym_('divlink',
          symcallparam_('div',
            class:['a_div'], a_class:['linkage'],
            'hello' )
        ))
        
        expectResolved st, 'divlink',
          "<div, class=',a_div,',>,<a, ,class,=',linkage,', "+
          ",href,=',/,', ,target,=',_blank,',>,hello,</a>,hello,</div>"

        
        # expectResolved st, 'div',
        #   "<div,"


