{mustard:{TokenStream}} = require '../src/token_stream'
{mustard:{TextToken, ScopeToken, YieldAttrToken, YieldToken, InterpolateToken, AttrScopeToken, SymbolCallToken}} = require '../src/token_types'
{mustard:{Symbol}} = require '../src/symbol'


_ = exports ? this

_.stream = (children...)->
  _._pushChildren new TokenStream, children

_._pushChildren = (s, children)->
  stream = if s.children then s.children() else s
  for c in children
    c = [c] unless c instanceof Array
    for child in c
      child = txt_(child) if typeof child is 'string'
      stream.push(child)
  return s

_.yield_ = -> new YieldToken
_.yieldattr_ = (name)-> new YieldAttrToken(name)
_.txt_ = (txt)-> new TextToken(txt)
_.symcall_ = (name, children...)-> _._pushChildren new SymbolCallToken(name), children

_.intp_ = (name)-> new InterpolateToken( name )


_.scope = (source, params, children...)-> 
  _._pushChildren  new ScopeToken( source, params), children

_.attrscope_ = (name, params, children...)->
  _pushChildren new AttrScopeToken( name, params ), children

_.symcallparam_ = (name, attributes, children...)->
  sct =  new SymbolCallToken(name)
  _._pushChildren sct, children
  for k, v of attributes
    _._pushChildren sct.children(k), v
  sct

_.sym_ = (name, children...)-> _._pushChildren new Symbol(name), children

_.to_text= (s, debug= false)->
  o = []
  s.eachToken false, (t)->
    o.push switch t.type()
      when 'text' then t.contents()
      when 'symbol'
        "<SYM:#{t.name()}>"+
          ("#{ if k is '$$children' then '' else k.toString() + '=>'}#{_.to_text(ch)}" for k,ch of t.allChildren()).join('') +
        "</SYM:#{t.name()}>"
      when 'yield' then "YIELD"
      when 'yield:attr' then "YIELD:ATTR:#{t.name()}"
      when 'int' then "INT:#{t.name()}"
      when 'scope'
        "<SCOPE:#{t.name()}:#{t.parameters()}>"+
          ("#{ if k is '$$children' then '' else k.toString() + '=>'}#{_.to_text(ch)}" for k,ch of t.allChildren()).join('') +
        "</SCOPE:#{t.name()}>"
      else "UNKNOWN:#{t}"

    console.log o if debug
  
  o.join(',')



root = exports ? this

