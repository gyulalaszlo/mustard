_ = require './underscore'
{ContextWrapper, IndentedBuffer} = require './indented_buffer'
{AstElement} = require './elements'
{$meta} = require './meta'

# ANSI Terminal Colors.
bold  = '\033[0;1m'
dark_grey = '\033[0;33m'
purple = '\033[0;35m'
cyan = '\033[0;36m'

red   = '\033[0;31m'
green = '\033[0;32m'
reset = '\033[0m'

# To include blue text in the prompt:

# PS1="\[\033[34m\][\$(date +%H%M)][\u@\h:\w]$ "
# The problem with this prompt is that the blue colour that starts with the 34 colour code is never switched back to the regular colour, so any text you type after the prompt is still in the colour of the prompt. This is also a dark shade of blue, so combining it with the bold code might help:

# PS1="\[\033[1;34m\][\$(date +%H%M)][\u@\h:\w]$\[\033[0m\] "
# The prompt is now in light blue, and it ends by switching the colour back to nothing (whatever foreground colour you had previously).

# Here are the rest of the colour equivalences:

# Black       0;30     Dark Gray     1;30
# Blue        0;34     Light Blue    1;34
# Green       0;32     Light Green   1;32
# Cyan        0;36     Light Cyan    1;36
# Red         0;31     Light Red     1;31
# Purple      0;35     Light Purple  1;35
# Brown       0;33     Yellow        1;33

__wrapPart = (token, color=dark_grey) -> "#{color}#{token}#{reset}"
__wrapToken = (start, token, end, col=reset)->
    "#{__wrapPart start}#{__wrapPart token, col}#{__wrapPart end}"



class DependencyResolver

    constructor: (@_symbols)->
    
    resolveRound: ->
        for name, sym of @_symbols.all()
            # console.log sym
            # if _(sym.dependencies()).size() == 1
            resolved_deps = []
            for dep, resolved of sym.dependencies()
                console.log "DEP OF #{name} -> #{dep}"
                resolved_dep = @_symbols.get dep
                sym.tokens().yieldDependency resolved_dep
                resolved_deps.push dep
            
            
            delete sym.dependencies()[dep] for dep in resolved_deps
                
                # symbols = sym.tokens().symbols( dep )
                # console.log symbols
                

    
                

    
        # @_token


class TokenStream

    constructor: (@_parent=null)->
        @_tokens = []
        @_scopes = []
        @_symbols = []
        @_dependencies = {}

    _push: (token)->
        @_tokens.push token

    tokens: -> @_tokens

    # name: -> @_name

    symbols: (name)-> _(@_tokens).filter (el)-> el.type is 'symbol' and el.name is name
    
    pushString: (str)-> 
        @_push type: "string", data: str

    pushInterpolation: (interpolate_key)->
        @_push type: "interpolation", data: interpolate_key

    pushSymbolStart: (symbol_name)->
        newStream = new TokenStream this
        @addDependency(symbol_name)
        sym = type: "symbol", name: symbol_name, stream:newStream
        @_push sym
        sym.stream


    pushYield: ()->
        @_push type: 'yield'

    pushScopeStart: (scope_name, params)->
        scope = { name:scope_name, params:params }
        @_scopes.push scope
        @_push type: "scope", name:scope_name, params:params

    pushScopeEnd: ()->
        throw new Error "cannot close root scope" if @_scopes.length == 0
        scope = @_scopes.shift()
        @_push type: "/scope", name:scope.name, params:scope.params

    addDependency: (depName)->
        @_dependencies[depName] = true
        # Let the dependency bubble up
        @_parent.addDependency(depName) if @_parent


    yieldDependency: (symbol)->
        symbol_name = symbol.name()
        # for t in @_tokens
        idx = 0
        out_tokens = _(@_tokens).toArray()
        while idx <  out_tokens.length
            t = out_tokens[idx]

            if t.type is 'symbol'
                console.log "yieldDependency for #{symbol_name}  INTO:#{t.name}"
                t.stream.yieldDependency(symbol)
                console.log "/yieldDependency"

                if t.name is symbol_name
                    tokens = symbol.tokens().yield( t.stream.tokens() )
                    # console.log t.
                    out_tokens[idx..idx] = tokens
            
            idx++
        @_tokens = out_tokens

          

    yield: (tokens)->
        idx = 0
        out_tokens = _(@_tokens).toArray()
        while idx <  out_tokens.length
            t = out_tokens[idx]
            if t.type is 'symbol'
                t.stream.yield(tokens)
            if t.type is 'yield'
                out_tokens[idx..idx] = tokens

            idx++
        return out_tokens




        # for idx in replaceIndices = []
            

    dependencies: => @_dependencies

    # tokens: @_tokens

    toColorString: ->
        ["tokens:"]
        .concat(for t in @_tokens
            switch t.type
                when 'string' then t.data
                when 'interpolation' then __wrapPart t.data, green
                when 'scope' then  __wrapPart "<scope:#{t.name} #{t.params}>", red
                when '/scope' then  __wrapPart "</scope:#{t.name} #{t.params}>", red
                when 'symbol'
                    (__wrapPart "<symbol:#{t.name}> ", cyan) +
                    t.stream.toColorString() +
                    (__wrapPart "</symbol:#{t.name}> ", cyan)
                when 'yield' then  __wrapPart "YIELD", purple
        ).join __wrapPart(',')

    $meta(@, true, __filename)
    # @$meta.attr('name').attr('dependencies')

    # @$meta.traceCalling 'addDependency'
    # @$meta.traceCalling 'pushScopeEnd'


class JsOutput

    constructor: ->
      @template_functions = {}
    

    _addTemplate: (elementList, name, opts={})->
        # symbol = @_symbols.addFromTemplate( name, elementList )
        @_tokenStream = new TokenStream name
        # @_tokenStream = symbol.tokens() # new TokenStream name

        @options = _(opts).defaults
            pretty: true

        stringified_function_name = toId name
        @template_functions[name] =
          body: @convert elementList, stringified_function_name
          path: name
          name: stringified_function_name




    createClass: (@className, @_templates, options)->
        # populate symbol table
        @_symbols = new ProtoSymbolTable()
        for key,template of @_templates.allPrototypes()
            @_symbols.addProxy key, template

        for key, symbol of @_symbols.all()
            @_symbols.addFromTemplate( key, symbol.template() )
            # console.log @_symbols.all(), symbol
            @_addTemplate symbol.template(), key, options
            

        for key,template of @_templates.all()
            @_symbols.addFromTemplate( '$' + key, template )
            @_addTemplate(template, key, options)

        console.log 'BEFORE', @_symbols.toString()
        @_symbols.resolve()
        console.log 'AFTER', @_symbols.toString()
        return JsOutput.classTemplate(this)


    convert: (elementList, wrapper_function_name=null)->
        @buffer = new IndentedBuffer(2)
        @_recreateBuffer()
        # @buf = new InterpolatedStringBuilder
        @convertElementList( elementList, wrapper_function_name )
        body = @buffer.join()
        body

    convertElementList: (elementList, wrapIntoFunction=false)->
        if wrapIntoFunction
            @buffer.push "function() {"
            @buffer.indent()
            # @buffer.push 'var __context; if (output == null) { __context = new __contextWrapper(context); }'
            @buffer.push 'var __context = this.__context, output = this.__context.buffer;'
            # @buffer.push 'else { __context = context; }'
            # @buffer.push 'if (output == null) { output = new __bufferType(); }'
            
        for element in elementList.elements
            @convertElement(element)

        if wrapIntoFunction
            @flushInterpolateBuffer()
            joinChar = if @options.pretty then '\\n' else ''
            # @buffer.push 'return output.join("'+joinChar+'");'

            @buffer.outdent '}'
            # @buffer.outdent()

    _recreateBuffer: -> @buf = new InterpolatedStringBuilder @_tokenStream

    flushInterpolateBuffer: (method='output.push')->
        return if @buf.length() is 0
        # @_tokenStream.pushInterpolation( @buf.toInterpolated())
        @buffer.push "#{method}(#{@buf.toInterpolated()});"
        @_recreateBuffer()




    convertScope: (el)->
        @flushInterpolateBuffer()
        # @_tokenStream.pushScopeStart(el.name.toRawString(), el.parameters)
        @buffer.push "__context.withScope("
        abuf = new InterpolatedStringBuilder()
        @convertToRawText el.name, abuf
        abuf.pushInterpolation ' output /* buffer */'

        scopeName = el.name.toRawString()
        scopeParams = []
        if _(el.parameters).size() > 0
            for p in el.parameters
                scopeParams.push p.toRawString()
                # console.log p.toRawString(), scopeParams
        # else
        #     scopeParams
        
        # @_tokenStream.pushScopeStart( scopeName, scopeParams )

        if _(el.parameters).size() > 0
            paramsBuf = new InterpolatedStringBuilder()
            for param in el.parameters
                paramsBuf.pushInterpolation @convertToRawText(param)
            abuf.pushInterpolation "[#{paramsBuf.toList(', ')}] /* params */,"
            # @_tokenStream.pushScopeStart(el.name.toRawString())

        else
            abuf.pushInterpolation '[] /* params */,'
            # @_tokenStream.pushScopeStart(el.name.toRawString())
        @buffer.indent abuf.toList()
        # @buffer.push "], // params"
        @convertElementList(el.children, true)
        @buffer.outdent "); // end of scope: #{el.name}"
        # @_tokenStream.pushScopeEnd()




    convertElement: (el)->
        needsPretty = !el.hasOnlyTextChildren() and @options.pretty

        @convertScope el if AstElement.isScope el
        @convertText el, @buf if AstElement.isText el


        if AstElement.isElement el
            elName = el.name.toRawString()
            # @_tokenStream.addDependency( elName )

            if @_symbols.exists elName
                # a = 1
                @flushInterpolateBuffer()
                # @_tokenStream.pushSymbol elName
                @buffer.push "this.render('#{elName}', __context, output);"
                # @buffer.push "this.render('#{JSON.stringify elName}');"
            else
                # @_tokenStream.pushSymbol elName
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
        var __context, __output, __isOutermost = false;

        if (this.__context) { } else {
          __isOutermost = true;
          __output = new __bufferType();
          this.__context = new __contextWrapper(this, context, __output );
        }
        __context = this.__context;

        switch (template_name) {
        <% _.each(template_functions, function(template, key) { %>
            case '<%= template.path %>': 
                this.<%= template.name %>();
                break;
        <% }); %>
            default:
                throw new Error("No such template with name: '" + template_name
                    + "'. Available Templates: ['<%= _(template_functions).keys().join("', '") %>']");
        }
        
        if (__isOutermost) {
            delete this.__context;
            return __output.join("<%= options.pretty ? '\\n' : '' %>");
        }
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



class OutputTokenizer
    constructor: (@_stream)->

    _text: (txt_el)->
        for partial in txt_el.partials
            if partial.interpolate
                @_stream.pushInterpolation partial
            else
                @_stream.pushString partial


    tokenize_tpl: (tpl)->
        AstElement.eachWithClosing tpl, (el, opening)=>
            switch el.type()

              when 'text'
                @_text( el)
                break

              when 'element'
                break



class ProtoSymbolTable
    constructor: ->
        @_symbols = {}
        @_exists = {}

    get: (key) -> @_symbols[key]
    
    exists: (key)-> @_symbols[key] != undefined
    addProxy: (key, template)-> @_symbols[key] = new ProtoSymbolProxy(key, template)

    all: -> @_symbols
    
    addFromTemplate: (name, tpl)->
        symbol = new ProtoSymbol( name, tpl )
        @_symbols[name] = symbol
        symbol

    resolve: ->
        resolver = new DependencyResolver this
        resolver.resolveRound()
        # console.log "resolve", resolver


    toString: -> ['<--'].concat((v.toString() for k,v of @_symbols).concat('-->')).join " --\n"
            
        


class ProtoSymbolProxy
    constructor: (@_name, @_template)->

    isProxy: -> true
    name: -> @_name
    template: -> @_template

class ProtoSymbol
    constructor:(@_name, elements)->
        @_tokens = new TokenStream
        elements.pushToTokenStream @_tokens
        

    isProxy: -> false
    name: -> @_name
    dependencies: -> @_tokens.dependencies()
    tokens: -> @_tokens

    toString: ->
        # console.log @
        "SYMBOL: #{@_name} -> [ #{JSON.stringify(@_tokens.dependencies())} ]\n #{ @_tokens.toColorString()}"



class InterpolatedStringBuilder
    constructor: (@_tokenStream=new TokenStream)->
      @buffer = []
      @isString = []
      @hasInterpolation = false

    length: -> @buffer.length

    pushInterpolation: (stuff...)->
      for s in stuff
        @hasInterpolation = true
        @buffer.push s
        @isString.push false
        @_tokenStream.pushInterpolation s

    pushString: (strings...)->
      for s in strings
          @buffer.push s
          @isString.push true
          @_tokenStream.pushString s

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
