_ = require './underscore'
{ContextWrapper, IndentedBuffer} = require './indented_buffer'
{AstElement} = require './elements'

class JsOutput

    constructor: ->
      @template_functions = {}
    

    _addTemplate: (elementList, wrapper_function_name, opts={})->
        @options = _(opts).defaults
            pretty: true

        stringified_function_name = toId wrapper_function_name
        @template_functions[wrapper_function_name] =
          body: @convert elementList, stringified_function_name
          path: wrapper_function_name
          name: stringified_function_name



    createClass: (@className, @_templates, options)->
        # populate symbol table
        @_symbols = {}
        for key,template of @_templates.all()
            @_symbols[key] = true

        for key,template of @_templates.all()
            @_addTemplate(template, key, options)

        return JsOutput.classTemplate(this)


    convert: (elementList, wrapper_function_name=null)->
        @buffer = new IndentedBuffer(2)
        @buf = new InterpolatedStringBuilder
        @convertElementList( elementList, wrapper_function_name )
        body = @buffer.join()
        body

    convertElementList: (elementList, wrapIntoFunction=false)->
        if wrapIntoFunction
            @buffer.push "function(context, output) {"
            @buffer.indent()
            @buffer.push 'var __context; if (output == null) { __context = new __contextWrapper(context); }'
            @buffer.push 'else { __context = context; }'
            @buffer.push 'if (output == null) { output = new __bufferType(); }'
            
        for element in elementList.elements
            @convertElement(element)

        if wrapIntoFunction
            @flushInterpolateBuffer()
            joinChar = if @options.pretty then '\\n' else ''
            @buffer.push 'return output.join("'+joinChar+'");'

            @buffer.outdent '}'
            # @buffer.outdent()

    flushInterpolateBuffer: (method='output.push')->
        return if @buf.length() is 0
        @buffer.push "#{method}(#{@buf.toInterpolated()});"
        @buf = new InterpolatedStringBuilder


    convertScope: (el)->
        @flushInterpolateBuffer()
        @buffer.push "__context.withScope("
        abuf = new InterpolatedStringBuilder()
        @convertToRawText el.name, abuf
        abuf.pushInterpolation ' output /* buffer */'

        if _(el.parameters).size() > 0
            paramsBuf = new InterpolatedStringBuilder()
            for param in el.parameters
                paramsBuf.pushInterpolation @convertToRawText(param)
            abuf.pushInterpolation "[#{paramsBuf.toList(', ')}] /* params */,"
        else
            abuf.pushInterpolation '[] /* params */,'
        @buffer.indent abuf.toList()
        # @buffer.push "], // params"
        @convertElementList(el.children, true)
        @buffer.outdent "); // end of scope: #{el.name}"


    convertElement: (el)->
        needsPretty = !el.hasOnlyTextChildren() and @options.pretty

        @convertScope el if AstElement.isScope el
        @convertText el, @buf if AstElement.isText el
        
        if AstElement.isElement el
            elName = el.name.toRawString()
            if @_symbols[elName]
                # a = 1
                @flushInterpolateBuffer()
                @buffer.push "this.render('#{elName}', context, output);"
                # @buffer.push "this.render('#{JSON.stringify elName}');"
            else
                @_convertElementOpeningTag el, needsPretty
                @_convertElementChildren el, needsPretty
                @_convertElementClosingTag el

        # if AstElement.isProto el
        #     @convertElementList

    
    _convertElementOpeningTag: (el, needsPretty)->
        buf = new InterpolatedStringBuilder
        buf.pushString "<"
        @convertText el.name, buf

        attribute_buffers = {}
        attrs = el.interpolated_attributes
        for attr, idx in attrs
            name = @convertText attr.name
            if name.hasInterpolation
              buf.pushString ' '
              @convertText attr.name, buf
              buf.pushString '=\\"'
              @convertText attr.value, buf
              buf.pushString '\\"'
            else
              name_str = name.toInterpolated(false)
              valueBuffer = new InterpolatedStringBuilder
              @convertText attr.value, valueBuffer

              attribute_buffers[name] ||= []
              attribute_buffers[name].push valueBuffer

        for key, attr_buf of attribute_buffers
              buf.pushString " #{key}=\\\""
              for a_buf, idx in attr_buf
                  buf.pushBuffer a_buf, ''
                  buf.pushString ' ' unless idx == attr_buf.length - 1
              buf.pushString '\\"'


        buf.pushString ">"
        @buf.pushBuffer buf
        

    _convertElementChildren: (el, needsPretty)->
        if el.children
            # if hasOnlyTextChildren
            if needsPretty
                @flushInterpolateBuffer()
                @buffer.indent 'output.indent();'
            @convertElementList(el.children)
            if needsPretty
                @flushInterpolateBuffer()
                @buffer.outdent 'output.outdent();'

    _convertElementClosingTag: (el)->
        
       # buf = new InterpolatedStringBuilder
        @buf.pushString "</"
        @convertText el.name, @buf
        @buf.pushString ">"
        # @buf.pushBuffer buf

        if @options.pretty
            @flushInterpolateBuffer()
        
         
        
    convertText: (text, o=new InterpolatedStringBuilder)->

        for partial in text.partials
            # text partial
            if typeof partial is "string"
                o.pushString partial

            # interpolation partial
            if partial.interpolate
                o.pushInterpolation "__context.get('#{partial.interpolate}')"
        
        return o

    convertToRawText: (text, o=new InterpolatedStringBuilder)->

        for partial in text.partials
            # text partial
            if typeof partial is "string"
                o.pushString partial

            # interpolation partial
            if partial.interpolate
                o.pushString partial.interpolate
        
        return o.toList()

    toString: -> "JSOutput"
      
    _: _


    @classTemplate: _.template """

<%= className %> = (function() {
    
    function <%= className %>(){
        // Constructor. empty for now...
    }
    var __bufferType = IndentedBuffer;
    var __contextWrapper = ContextWrapper;


    <%= className %>.prototype.render = function(template_name, context, output) {
        if (context == null) { 
            context = template_name;
            template_name = 'default';
        }
        <% _.each(template_functions, function(template, key) { %>
        if (template_name === '<%= template.path %>') 
            return this.<%= template.name %>(context, output);<% }); %>
    }



    <% _.each(template_functions, function(val, key) { %>

    /*
        Template: <%= val.path %>
    */
    <%= className %>.prototype.<%= val.name %> = 
<%= val.body %>;
    <% }); %>


    return <%= className %>;
})();

        """
 

toId = (str)-> str.replace(/[^a-zA-Z\-_]+/g, '_')



class InterpolatedStringBuilder
    constructor: ()->
      @buffer = []
      @isString = []
      @hasInterpolation = false

    length: -> @buffer.length

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


    toList: (quoteString=true)->

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
      return o

    toInterpolated: (quoteString=true, surroundWithJoin=true)->
        ret = @toList(quoteString)
        if typeof ret is 'string'
            return ret
        "[ #{ret.join(',')} ].join('')"

    toString: -> @toInterpolated(false)

root = exports ? this
root.JsOutput = JsOutput
# root.IndentedBuffer = IndentedBuffer
# root.ContextWrapper = ContextWrapper
