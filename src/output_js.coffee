parser = require './parser'
_ = require './underscore'
{IndentedBuffer} = require './indented_buffer'

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



    createClass: (@className, @_templates, options)->
        for key,template of @_templates.all()
            @addTemplate(template, key, options)

        return JsOutput.classTemplate(this)


    convert: (elementList, wrapper_function_name=null)->

        @buffer = new IndentedBuffer(2)
        @buf = new InterpolatedStringBuilder
        @convertElementList( elementList, wrapper_function_name )
        body = @buffer.join()
        body

    convertElementList: (elementList, wrapperFunctionName=null)->
        if wrapperFunctionName
            @buffer.push "function(context) {"
            @buffer.indent()
            @buffer.push 'var output = new this.bufferType();'
        
        for element in elementList.elements
            @convertElement(element)

        if wrapperFunctionName
            @flushInterpolateBuffer()
            joinChar = if @options.pretty then '\\n' else ''
            @buffer.push 'return output.join("'+joinChar+'");'

            @buffer.outdent '}'
            # @buffer.outdent()

    flushInterpolateBuffer: (method='output.push')->
        return if @buf.length() is 0
        @buffer.push "#{method}(#{@buf.toInterpolated()});"
        @buf = new InterpolatedStringBuilder

    convertElement: (el)->
        needsPretty = !el.hasOnlyTextChildren() and @options.pretty


    
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
                if needsPretty
                    @flushInterpolateBuffer()
                    @buffer.indent 'output.indent();'
                @convertElementList(el.children)
                if needsPretty
                    @flushInterpolateBuffer()
                    @buffer.outdent 'output.outdent();'

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
                o.pushInterpolation "context.#{partial.interpolate}"
        
        return o

    _: _


    @classTemplate: _.template """

<%= className %> = (function() {
    
    function <%= className %>(){
        // Constructor. empty for now...
    }

    <%= className %>.prototype.bufferType = IndentedBuffer;

    <% if (_(template_functions).size() > 1) { %>

    <%= className %>.prototype.render = function(template_name, context) {
        <% _.each(template_functions, function(template, key) { %>
        if (template_name === '<%= template.path %>') return this.<%= template.name %>(context);<% }); %>
    }

    <% } else { %>

    <%= className %>.prototype.render = function( template_name, context ) {
        <% var template = _(template_functions).values()[0]; %>
        if (context == null) { 
            context = template_name;
            template_name = '<%= template.name %>';
        }
        if (template_name === '<%= template.path %>') return this.<%= template.name %>(context);
    }

    <% } %>

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
root.IndentedBuffer = IndentedBuffer
