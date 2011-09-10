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


class ContextWrapper
    constructor: (@template, @context, @buffer )->
        @scopes = {}
        # @buffer = new IndentedBuffer()

    
    get: (name)->
        obj = @context
        parts = name.split '.'
        first_part = parts[0]
        if @scopes[parts[0]]
            obj = @scopes[parts.shift()]
            return obj if parts.length == 0

        return ContextWrapper._getForObject(obj, parts)

    @_getForObject = (obj, parts)->
        name = parts.shift()
        if obj[name]
            value = obj[name]

            valueType = typeof value
            if valueType is 'function'
                value = value.call(obj)

            if parts.length > 0
                value = ContextWrapper._getForObject(value, parts)
            return value
        return null
         

    withScope: (scopeName, buffer, params, func)->
        scope = @get scopeName
        scopeType = typeof scope

        if params.length is 0
            unless scope in [ false, null, undefined, '', 0, 'false' ]
                func.call(this.template)
            return

        if params.length is 1
            
            if scope instanceof Array
                [key] = params
                for v in scope
                    @scopes[key] = v
                    func.call(this.template)
                    delete @scopes[key]
                return

            if scopeType is 'object'
                @scopes[params[0] ]= scope
                func.call(this.template)
                delete @scopes[params[0]]
                return

        if params.length is 2
            if typeof scope is 'object'
                [key, value] = params
                for k, v of scope
                    [@scopes[key], @scopes[value]] = [k, v]
                    func.call(this.template)
                    delete @scopes[key]; delete @scopes[value]
                return
 



        
        
        

root = exports ? this
root.IndentedBuffer = IndentedBuffer
root.ContextWrapper = ContextWrapper
