# try
_ = require './underscore'
# catch e
    # presume, that underscore is loaded

class Meta
    constructor: (@klass, @_path)->

    path: -> @_path

    method: (name, func)->
        @klass.prototype[name] = switch typeof func
            when 'string' then eval func
            when 'function' then func
        this

    wrapMethod: (name, func, chainThis=true)->
        old_func = @klass.prototype[name]
        backup_name = _.uniqueId "__wrapped_#{name}"
        @klass.prototype[backup_name] = old_func
        @method name, func
        return if chainThis then this else backup_name
        # name: backup_name

    traceCalling: (name, opts={})->
        opts = _(opts).defaults
            name: true
            to_string:false
        # wrap_method 
        # old_func = @klass.prototype[name]
        # backup_name = _.uniqueId "__wrapped_#{name}"
        [path, klass] = [this._path, @klass]
        backup_name = @wrapMethod( name, (args...)->
            caller = arguments.callee.caller
            console.log "\n\n-- #{ klass.name }.#{ name } -- #{ path } -----\n"
            console.log "calling #{name} with #{args} -- from \n", caller.toString()[0..200]
            console.log "\n\n---------\n"
            return @[backup_name](args...)
        , false)
        this
          

    attrAccessors: (attrs={})->
        for name, intanceVarName of attrs
          @attrAccessor name, intanceVarName
        this

    attr:(name, opts={})->
        opts = _(opts).defaults
            ivar: "_#{name}"
            setter: null
            getter: null
            val: "__tmp_#{name}"
            attribute: name
            get: true
            set: true
            chain: false

        @method "__getter__#{name}", opts.getter if opts.getter
        @method "__setter__#{name}", opts.setter if opts.setter

        @method name, Meta.attr_accessor_template(opts)
        return this

    @attr_accessor_template = _.template """
        (function (<%= val %>) {
          var _retval;
          if (<%= val %> == null) {
            <% if (get) { %>
              <% if (getter != null) { %> _retval = this.__getter__<%= attribute %>() <% } else { %>
              _retval = this.<%= ivar %>; <% } %>
            <% } %>
          } else {
            <% if (set) { %>
              <% if (setter != null) { %> _retval = this.__setter__<%= attribute %>(<%= val %>) <% } else { %>
              _retval = this.<%= ivar %> = <%= val %>; <% } %>
            <% } %>
          }
          <% if (chain) { %>_retval = this; <% } %>
          return _retval;
        })
    """

__avaible_metas = {}
$meta = (target, addToKlass=false, filepath=null)->
    return target.$meta if target.$meta
    return __avaible_metas[target] if __avaible_metas[target]

    meta = new Meta(target, filepath)
    target.$meta = meta if addToKlass
    __avaible_metas[target] = meta
    meta

$meta.caller = (args)-> console.log args.callee.caller.toString()
# $meta.of = (target_instance)-> 

root = exports ? this
root.$meta = $meta
