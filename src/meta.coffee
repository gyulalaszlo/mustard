_ = require './underscore'

class Meta

    constructor: (@klass)->


    method: (name, func)->
        @klass.prototype[name] = switch typeof func
            when 'string' then eval func
            when 'function' then func
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
              _retval this.<%= ivar %> = <%= val %>; <% } %>
            <% } %>
          }
          <% if (chain) { %>_retval = this; <% } %>
          return _retval;
        })
    """

$meta = (target)->
  new Meta(target)

# $meta.of = (target_instance)-> 

root = exports ? this
root.$meta = $meta
