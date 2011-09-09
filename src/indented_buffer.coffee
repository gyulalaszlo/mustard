class IndentedBuffer
    constructor: (@_indent=0, buffer=[])->
      @_buffer = []
      @push str for str in buffer
        

    indent:  (str)-> @_indent += 1; @push str if str
    outdent: (str)->
        @_indent -= 1; @_indent = 0 if @_indent < 0
        @push str if str

    indentString: (str)->
        if @_indent > 0
            a = []; a[@_indent]=''; return a.join('    ') +  str
        else
            return str

    push: (strs...)->
        @_buffer.push @indentString(strs...)

    join: (str="\n")-> @_buffer.join(str)

    pushMultiLine: (str)->
      lines = str.split /[\n\r]+/g
      @push @indentString(line) for line in lines

root = exports ? this
root.IndentedBuffer = IndentedBuffer
