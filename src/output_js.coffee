parser = require './parser'
_ = require './underscore'

class JsOutput

    constructor: ->
      @template_functions = {}
    

    addTemplate: (elementList, wrapper_function_name, opts={})->
        @options = _(opts).defaults
            pretty: true

        stringified_function_name = toId wrapper_function_name
        @template_functions[wrapper_function_name] =
          body: @convert elementList, stringified_function_name
          path: wrapper_function_name
          name: stringified_function_name

    toId: (str)-> toId(str)
    _: _

    createClass: (@className)->

        _classTemplate = _.template """
<%= className %> = (function() {

    function <%= className %>(){
        // Constructor. empty for now...
    }

    <%= className %>.prototype.bufferType = (IndentedBuffer || []);

    <%= className %>.prototype.render = function(template_name, context) {
        <% _.each(template_functions, function(val, key) { %>
        if (template_name === '<%= key %>') return this.<%= val.name %>(context);<% }); %>
    }

    <% _.each(template_functions, function(val, key) { %>
    <%= className %>.prototype.<%= val.name %> = <%= val.body%>;
    <% }); %>


    return <%= className %>;
})();

        """
        return _classTemplate(this)


    evalClass: (className)->
      eval( @createClass(className) )

    convert: (elementList, wrapper_function_name=null)->

        @buffer = new IndentedBuffer
        @buf = new InterpolatedStringBuilder
        @convertElementList( elementList, wrapper_function_name )
        body = @buffer.join()
        body

    convertElementList: (elementList, wrapperFunctionName=null)->
        # @buffer.push '(function(){ ' unless wrapperFunctionName
        if wrapperFunctionName
            @buffer.push "function(context) {"
            @buffer.indent()
            # @buffer.push 'var output = new this.bufferType(); output.indent = output.outdent = function() { return this; }'
            @buffer.push 'var output = new this.bufferType();'
        
        for element in elementList.elements
            @convertElement(element)

        if wrapperFunctionName
            @flushInterpolateBuffer()
            @buffer.push 'return output.join("\\n");'
            @buffer.push '}'

            @buffer.outdent()

    flushInterpolateBuffer: (method='output.push')->
        @buffer.push "#{method}(#{@buf.toInterpolated()});"
        @buf = new InterpolatedStringBuilder

    convertElement: (el)->
        hasOnlyTextChildren = el.hasOnlyTextChildren()

        # console.log hasOnlyTextChildren
          # @flushInterpolateBuffer( 'output.indent')
          # @buffer.indent()

    
        if parser._mustard_checks.isText el #instanceof parser.Text
            @convertText el, @buf

        # if el instanceof parser.Element
        if parser._mustard_checks.isElement el
            buf = new InterpolatedStringBuilder
            buf.pushString "<"
            @convertText el.name, buf

            attribute_buffers = {}
            for attr in el.interpolated_attributes
                name = @convertText attr.name
                if name.hasInterpolation
                  buf.pushString ' '
                  @convertText attr.name, buf
                  buf.pushString '=\\"'
                  @convertText attr.value, buf
                  buf.pushString '\\"'
                else
                  name_str = name.toInterpolated(false)
                  abuf = attribute_buffers[name] ||= new InterpolatedStringBuilder
                  @convertText attr.value, abuf

            for key, attr_buf of attribute_buffers
                  buf.pushString " #{key}=\\\""
                  buf.pushBuffer attr_buf, ' '
                  buf.pushString '\\"'


            buf.pushString ">"
            @buf.pushBuffer buf
            
            if el.children
                # if hasOnlyTextChildren
                unless hasOnlyTextChildren
                    @flushInterpolateBuffer()
                    @buffer.indent 'output.indent()'
                @convertElementList(el.children)
                unless hasOnlyTextChildren
                    @flushInterpolateBuffer()
                    @buffer.outdent 'output.outdent()'

            buf = new InterpolatedStringBuilder
            buf.pushString "</"
            @convertText el.name, buf
            buf.pushString ">"
            @buf.pushBuffer buf

            if hasOnlyTextChildren and @options.pretty
                @flushInterpolateBuffer()
                # @buffer.outdent 'output.outdent()'

          
 
            
        
    convertText: (text, o=new InterpolatedStringBuilder)->

        for partial in text.partials
            # text partial
            if typeof partial is "string"
                o.pushString partial

            # interpolation partial
            if partial.interpolate
                o.pushInterpolation "context.#{partial.interpolate}"
        
        o


toId = (str)-> str.replace(/[^a-zA-Z\-_]+/g, '_')

class IndentedBuffer
    constructor: (@_indent=0, buffer=[])->
      @_buffer = []
      @push str for str in buffer
        

    indent:  (strs...)-> @_indent += 1; @push strs...
    outdent: (strs...)-> @_indent -= 1; @_indent = 0 if @_indent < 0;  @push strs...

    # incIndent: (strs...)-> @_indent += 1; @push strs...
    # decIndent: (strs...)-> @_indent -= 1; @_indent = 0 if @_indent < 0;  @push strs...
    indentString: (strs...)->
        if @_indent > 0
            return ("    " for i in [0..@_indent-1]).join('') + strs.join('')
        else
            return strs.join('')

    push: (strs...)-> @_buffer.push @indentString(strs...) if strs.length > 0
    unshift: (strs...)-> @_buffer.unshift @indentString( strs...)
    join: (str="\n")-> @_buffer.join(str)

    pushMultiLine: (str)->
      lines = str.split /[\n\r]+/g
      @push line for line in lines



class InterpolatedStringBuilder
    constructor: ()->
      @buffer = []
      @isString = []
      @hasInterpolation = false

    pushInterpolation: (stuff...)->
      for s in stuff
        @hasInterpolation = true
        @buffer.push s
        @isString.push false

    pushString: (strings...)->
      for s in strings
          @buffer.push s
          @isString.push true

    pushBuffer: (buf, separator_string=null)->
      for str, i in buf.buffer
          if buf.isString[i]
              @pushString str
          else
              @pushInterpolation str
          @pushString separator_string if separator_string isnt null and i != buf.buffer.length - 1


    toInterpolated: (quoteString=true)->
      return "" if @buffer.length == 0

      unless @hasInterpolation
        return '\"' + @buffer.join('') + '\"' if quoteString
        return @buffer.join('')

      return @buffer[0] if @buffer.length == 1
      o = []
      lastStringBuf = []
      for e, i in @buffer
        unless @isString[i]
          o.push '"' + lastStringBuf.join('') + '"' if lastStringBuf.length > 0
          lastStringBuf = []
          o.push e
        else
          lastStringBuf.push e
      o.push '"' + lastStringBuf.join('') + '"'  if lastStringBuf.length > 0

      return "[ #{o.join(',')} ].join('')"

    toString: -> @toInterpolated(false)

root = exports ? this
root.JsOutput = JsOutput
