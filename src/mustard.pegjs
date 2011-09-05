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
    = ident:ident _ attrs:attributeDeclaration* { return {name: ident, attributes:attrs}; }


attributeDeclaration "attributes declaration"
    = '#' ident:ident _                   { return {id: ident}; }
    / '.' ident:ident _                 { return {class: ident}; }
    / '@' ident:ident _ '=' _ value:stringLiteral _  { var o={}; o[ident]=value; return o;  }


elementContents "element contents"
    = contentString:textElement { return [contentString]; }
    / '{' children:statementList '}' _ { 
        return children; 
    }
    / ';' { return {}}


textElement "text"
    = it:stringLiteral { return it; }

//    = contentString:string { 
//        return contentString; 
//    }
//    / interpolated:interpolatedField { return interpolated; }
     

stringLiteral
 = '"' '"' _ { return ""; }
 / '"' st:stringInternal+ '"' _ { return st }


stringInternal
 = '{{' id:ident '}}' { return {interpolate: id} }
    / chr:[^"{]+ { return chr.join('') }
    / chr:'{' { return chr }




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
