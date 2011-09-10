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

class Text extends AstElement
    constructor: (obj)-> @partials = obj.text
    hasOnlyTextChildren: -> true
    toString: -> "[text: #{JSON.stringify _(@partials).map( (e)->JSON.stringify e ).join(' ')}]"
    toRawString: -> @partials.toString()


class ElementList extends AstElement
    constructor: -> @elements = []
    push: (el)-> @elements.push el
    length: ()-> @elements.length
    toString: -> "[elementList #{_.map(@elements, (e)-> e.toString()).join("\n") }]"


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


class Scope extends AstElement
    
    constructor: (hash, @children)->
        @name = new Text(hash.name)
        @parameters = []
        # console.log params
        @parameters.push new Text(param) for param in hash.parameters

    toString: -> "[scope #{JSON.stringify(@name)} - #{@children}]"



class ElementPrototype extends AstElement

    constructor: (hash, @children)->
        @_name = hash.name

    name: -> @_name
    
    toString: -> "[proto #{@_name} - #{@children}]"




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



# export checking functions
root._mustard_checks = AstElement


