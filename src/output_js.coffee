parser = require './parser'
_ = require './underscore'

class JsOutput

    constructor: ->
      @template_functions = {}
    

    addTemplate: (elementList, wrapper_function_name)->
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
            @buffer.incIndent()
            @buffer.push 'var output = []; output.indent = output.outdent = function() { return this; }'
        
        if elementList.elements.length > 1
            # @buffer.push "output.push({})"
            # @buffer.incIndent()
            @buffer.incIndent "output.indent();"
            @flushInterpolateBuffer()

        for element in elementList.elements
          @convertElement(element)
        
        if elementList.elements.length > 1
            @buffer.decIndent "output.outdent();"
            @flushInterpolateBuffer()


        if wrapperFunctionName
            @flushInterpolateBuffer()
            @buffer.push 'return output.join("\\n");'
            @buffer.push '}'

            @buffer.decIndent()
        # @buffer.push ')()' unless wrapperFunctionName
        #

    flushInterpolateBuffer: ->
        @buffer.push "output.push(#{@buf.toInterpolated()})"
        @buf = new InterpolatedStringBuilder

    convertElement: (el)->
    
        if el instanceof parser.Text
            # o.push @convertText(el)
            # @buffer.push "output.push(#{@convertText(el).toInterpolated()});"
            @convertText el, @buf

        if el instanceof parser.Element
            buf = new InterpolatedStringBuilder
            buf.pushString "<"
            @convertText el.name, buf

            # console.log el.interpolated_attributes
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


            # if el.attributes
            #   for k,v of el.attributes
            #     buf.pushString ' '
            #     # console.log k,v
            #     @convertText k, buf
            #     buf.pushString '=\\"'
            #     for single_val, i in v
            #         @convertText(single_val, buf)
            #         # dont add space to the last attribute
            #         buf.pushString ' ' unless i == v.length - 1

            #     buf.pushString '\\"'
                    

            buf.pushString ">"
            @buf.pushBuffer buf
            
            # @buffer.push "output.push(#{buf.toInterpolated()});"
            # @buffer.push "output.push([#{buf.join(',')}].join(''));"
            
            if el.children
              @convertElementList(el.children)

            buf = new InterpolatedStringBuilder
            buf.pushString "</"
            @convertText el.name, buf
            buf.pushString ">"
            # @buffer.push "output.push(#{buf.toInterpolated()});"
            # @buffer.push "output.push([#{buf.join(',')}].join(''));"
            @buf.pushBuffer buf

            
        
    convertText: (text, o=new InterpolatedStringBuilder)->

        for partial in text.partials
            # text partial
            if typeof partial is "string"
                o.pushString partial

            # interpolation partial
            if partial.interpolate
                o.pushInterpolation "context.#{partial.interpolate}"
        
        o
        # return o.toInterpolated()

        # if o.length == 1
        #     return "#{o[0]}"
        # "[ #{o.join ', '} ].join('')"


toId = (str)-> str.replace(/[^a-zA-Z\-_]+/g, '_')

class IndentedBuffer
    constructor: (@indent=0, buffer=[])->
      @buffer = []
      @push str for str in buffer
        


    incIndent: (strs...)-> @indent += 1; @push strs...
    decIndent: (strs...)-> @indent -= 1; @indent = 0 if @indent < 0;  @push strs...
    indentString: (strs...)->
        if @indent > 0
            return ("    " for i in [0..@indent-1]).join('') + strs.join('')
        else
            return strs.join('')

    push: (strs...)-> @buffer.push @indentString(strs...) if strs.length > 0
    unshift: (strs...)-> @buffer.unshift @indentString( strs...)
    join: (str="\n")-> @buffer.join(str)

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
