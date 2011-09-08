start
    = list:statementList { return list; }


statementList "statement list"
    = _ statements:statement* { 
        return statements; 
    }


statement "element statement"
    = decl:elementDeclaration _ contents:elementContents? _ 
        { 
            return { type:'element', declaration:decl, contents:contents};
        }
    / text:textElement { return text }


elementDeclaration "element declaration"
    = ident:identLiteral _ attrs:attributeDeclaration* { return {name: ident, attributes:attrs}; }
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

     

stringLiteral "string"
 = '"' '"' _ { return {type:"text", text:[""]}; }
 / '"' st:stringInternal+ '"' _ { return {type:"text", text:st} }
 / it:interpolateInternal _ { return {type:"text", text:[it]}}

identLiteral "identifier (normal or interpolated)"
 = id:identInternal+ { return {type:"text", text:id} }

identInternal
  = it:identChar+ { return it.join(''); }
  / interpolateInternal


stringInternal
 =  interpolateInternal
    / chr:[^"{]+ { return chr.join('') }
    / chr:'{' { return chr }

interpolateInternal
 = '{{' _ id:ident _ '}}' { return {interpolate: id} }




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
