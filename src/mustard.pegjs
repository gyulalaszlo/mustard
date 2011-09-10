start
    = list:statementList { return list; }


statementList "statement list"
    = _ statements:statement* { 
        return statements; 
    }


statement "element statement"
    = 
        proto:elementPrototype _ { return proto }
    / decl:elementDeclaration _ contents:elementContents? _ 
        { 
            return { type:'element', declaration:decl, contents:contents};
        }
    / scope:scopeDeclaration _ { return scope }
    / text:textElement _ { return text }



elementDeclaration "element declaration"
    = ident:tagIdentLiteral _ attrs:attributeDeclaration* { return {name: ident, attributes:attrs}; }
    / attrs:attributeDeclaration+ { return {name:{type:"text", text:["div"]}, attributes:attrs} }

attributeDeclaration "attributes declaration"
    = '#' ident:identLiteral _           { return {name:{type:'text', text:['id']}, value:ident}; }
    / '.' ident:identLiteral _           { return { name:{type:'text', text:['class']}, value:ident}; }
    / '@' ident:identLiteral _ '=' _ value:stringLiteral _  { return {name:ident, value:value};  }


elementContents "element contents"
    = contentString:textElement { return [contentString]; }
    / '{' children:statementList '}' _ { 
        return children; 
    }
    / ';' { return {}}


textElement "text"
    = it:stringLiteral { return it; }

elementPrototype
    = it:tagIdentLiteral _ '=' _ ct:elementContents 
        { return {type:'decl', name:it, children:ct} }

scopeDeclaration "scope declarations"
   = it:singleInterpolateLiteral  '->' _ params:scopeParamList _
    '{' children:statementList '}' 
        { return { type:"scope", name: it, contents:children, parameters:params}}

scopeParamList "scope parameters list"
   = it:singleInterpolateLiteral ot:(','_ ot:singleInterpolateLiteral {
return ot})* {
return [it].concat(ot); } 
    / { return [] }

stringLiteral "string"
 = '"' '"' _ { return {type:"text", text:[""]}; }
 / '"' st:stringInternal+ '"' _ { return {type:"text", text:st} }
 / it:singleInterpolateLiteral _ { return it }

tagIdentLiteral "tag ident literal (prefixed with '%' if interpolated)"
  = '%' identLiteral:identLiteral { return identLiteral; }
    / it:ident { return {type:"text", text:[ it ]} }

identLiteral "identifier (normal or interpolated)"
  = id:identInternal+ { return {type:"text", text:id} }


singleInterpolateLiteral "single standing interpolation literal"
  = it:interpolateInternal _ { return {type:"text", text:[it]}}
 / it:interpolateWholeLiteralInternal _ { return {type:"text", text:[it]}}


identInternal
  = it:identChar+ { return it.join(''); }
  / interpolateInternal


stringInternal
 =  interpolateInternal
    / chr:[^"{]+ { return chr.join('') }
    / chr:'{' { return chr }

interpolateInternal
 /* = '{{' _ id:ident ('.' indent)+ _ '}}' { return {interpolate: id} }*/
 = '{{' _ id:identChain _ '}}' { return {interpolate: id} }
 

interpolateWholeLiteralInternal
 = ':' id:identChain { return {interpolate: id} }

identChain
 = id:ident internal:('.' iid:ident { return iid } )* {
return [id].concat(internal).join('.')}



/* ===== Lexical Elements ===== */

ident "identifier"
  = chars:identChar+ { return chars.join("");  } 

identChar
  = [a-zA-Z\-_]


/* ===== Whitespace ===== */

_ "whitespace"
  = (whitespace / SingleLineComment)*     

// Whitespace is undefined in the original JSON grammar, so I assume a simple
// conventional definition consistent with ECMA-262, 5th ed.
whitespace
  = [ \t\n\r]

SourceCharacter
    = .

LineTerminator  "end of line"
  = [\n\r\u2028\u2029]

SingleLineComment
  = "//" (!LineTerminator SourceCharacter)*
