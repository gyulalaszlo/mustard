_ = require './underscore'


# 
# Elements
# ========
#
#
class AstElement
    constructor: ->
    setTemplates: (templ)-> @_templates = templ
    templates: -> @_templates
    hasOnlyTextChildren: -> false

    childElements: -> []

class Text extends AstElement
    constructor: (obj)->
        @partials = obj.text
        @_isRawString = true
        for partial in @partials
            @_isRawString = true; break if partial.interpolate
         

    type: -> 'text'
    hasOnlyTextChildren: -> true

    toString: -> "[text: #{JSON.stringify _(@partials).map( (e)->JSON.stringify e ).join(' ')}]"
    
    isRawString: -> @_isRawString

    toRawString: ->
        return @partials.join('') if @_isRawString
        (for partial in @partials
            if partial.interpolate
                partial.interpolate
            else
                partial
        ).join('')

    toIdString: ->
        (for p in @partials
            if p.interpolate then p.interpolate else p
        ).join('')

    toWildCharString: ->
        (for p in @partials
            if p.interpolate then '(.*?)' else p
        ).join('')
        

    pushToTokenStream: (stream)->
        for partial in @partials
            if partial.attribute_interpolate
                  console.log "=========>>>> #{partial.attribute_interpolate}"
                  stream.pushYieldAttribute partial.attribute_interpolate
                
            else if partial.interpolate
                # console.log partial.interpolate.substring(0)
                switch partial.interpolate
                  when 'yield' then stream.pushYield()
                  else stream.pushInterpolation partial.interpolate
            else
                stream.pushString partial

            


class ElementList
    constructor: -> @elements = []
    type: -> 'elementList'
    push: (el)-> @elements.push el
    length: ()-> @elements.length
    toString: -> "[elementList #{_.map(@elements, (e)-> e.toString()).join("\n") }]"
    childElements: -> @elements

    pushToTokenStream: (stream)->
        for child in @elements
            child.pushToTokenStream(stream)


class Element extends AstElement
    constructor: (hash, @children)->
        @name = new Text(hash.declaration.name)
        @attributes= {}
        # store interpolated attribute names in an array
        @interpolated_attributes = []
        attr_cache = {}
        for attrs in hash.declaration.attributes
            if typeof attrs.name is "string"
              attr_key = attrs.name
              attr_cache[attr_key] ||= []
              attr_cache[attr_key].push new Text(attrs.value)
            else
              attr_key = new Text(attrs.name)
              @interpolated_attributes.push
                name:attr_key
                value:new Text(attrs.value)

        @attributes = attr_cache

    type: 'element'

    attributeTexts: ()->
        attributeTexts = []
        for k,v of @attributes
            attributeTexts.push ' ' , k , '="' ,
                ([a.toString(), ' '] for a in v) , '"'

        for attr in @interpolated_attributes
            attributeTexts.push ' ', attr.name.toString(), '="' , attr.value.toString(), '"'

        attributeTexts

    hasOnlyTextChildren: ()->
        for child in @children.elements
          return false unless (child instanceof Text)
        true

    toString: ()-> "[element <#{@name}> - #{@attributeTexts()} - #{@children}]"
    
    childElements: () -> @children.elements

    pushToTokenStream: (stream)->
        childStream = stream.pushSymbolStart @name.toWildCharString(), @attributes, @interpolated_attributes
        @children.pushToTokenStream childStream
        # stream.pushSymbolEnd()
         


class Scope extends AstElement
    
    constructor: (hash, @children)->
        @name = new Text(hash.name)
        @parameters = []
        # console.log params
        @parameters.push new Text(param) for param in hash.parameters
    
    type: 'scope'
    toString: -> "[scope #{JSON.stringify(@name)} - #{@children}]"
    childElements: () -> @children.elements
    
    pushToTokenStream: (stream)->
        stream.pushScopeStart @name.toIdString(), (p.toIdString() for p in @parameters)
        @children.pushToTokenStream stream
        stream.pushScopeEnd()
    



class ElementPrototype extends AstElement

    constructor: (hash, @children)->
        @_name = hash.name

    name: -> @_name
    
    type: 'proto'
    toString: -> "[proto #{@_name} - #{@children}]"
    childElements: () -> @children.elements

    pushToTokenStream: (stream)->
        # stream.pushSymbolStart @name.toWildCharString()
        # @children.pushSymbolStart stream
        # stream.pushSymbolEnd @name.toWildCharString()



class AstConverter
    constructor: ()->
        @_prototypes = {}

    listToAst: (list_in)->
        res = new ElementList
        for el in list_in
            res.push @elementFor(el)
        res

    getChildrenFor: (obj)->
        children = new ElementList
        if obj.contents instanceof Array
            children = @listToAst(obj.contents)
        children

    prototypes: -> @_prototypes
    addPrototype: (key, proto)->
        @_prototypes[key] = proto

    
    elementFor: (obj)->

        return unless obj instanceof Object
        
        retval = switch obj.type
            when 'text' then new Text(obj)
            when 'scope' then new Scope(obj, @getChildrenFor(obj))
            when 'element' then new Element(obj, @getChildrenFor(obj))
            when 'proto'
                proto = new ElementPrototype(obj, @getChildrenFor(obj))
                @addPrototype proto.name(), proto
                proto

        # retval.setTemplates @_templates
        return retval

root = exports ? this
root.AstConverter = AstConverter
root.AstElement = AstElement

AstElement.isElement =  (o)-> o instanceof Element
AstElement.isElementList = (o)-> o instanceof ElementList
AstElement.isText = (o)-> o instanceof Text
AstElement.isScope = (o)-> o instanceof Scope
AstElement.isProto = (o)-> o instanceof ElementPrototype

AstElement.each = (el, fun, onClose=false)->
    fun(el, true)
    AstElement.each(c, fun) for c in el.childElements()
    fun(el, false) if onClose
    # if 
    
AstElement.eachWithClosing = (el, fun)-> AstElement.each(el, fun, true)

# export checking functions
root._mustard_checks = AstElement


