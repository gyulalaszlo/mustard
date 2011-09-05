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
    / '@' ident:ident _ '=' _ value:string _  { var o={}; o[ident]=value; return o;  }


elementContents "element contents"
    = contentString:textElement { return [contentString]; }
    / '{' children:statementList '}' _ { 
        return children; 
    }
    / ';' { return {}}


textElement "text"
    = contentString:string { 
        return contentString; 
    }



/* ===== Lexical Elements ===== */

ident "identifier"
  = chars:identChar+ { return chars.join("");  } 

string "string"
  = '"' '"' _             { return "";    }
  / '"' chars:chars '"' _ { return chars; }

chars
  = chars:char+ { return chars.join(""); }

char
  // In the original JSON grammar: "any-Unicode-character-except-"-or-\-or-control-character"
  = [^"\\\0-\x1F\x7f]
  / '\\"'  { return '"';  }
  / "\\\\" { return "\\"; }
  / "\\/"  { return "/";  }
  / "\\b"  { return "\b"; }
  / "\\f"  { return "\f"; }
  / "\\n"  { return "\n"; }
  / "\\r"  { return "\r"; }
  / "\\t"  { return "\t"; }
  / "\\u" h1:hexDigit h2:hexDigit h3:hexDigit h4:hexDigit {
      return String.fromCharCode(parseInt("0x" + h1 + h2 + h3 + h4));
    }

identChar
  = [a-zA-Z\-_]



/*
 * The following rules are not present in the original JSON gramar, but they are
 * assumed to exist implicitly.
 *
 * FIXME: Define them according to ECMA-262, 5th ed.
 */

digit
  = [0-9]

digit19
  = [1-9]

hexDigit
  = [0-9a-fA-F]

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
