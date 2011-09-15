_ = require '../../vendor/underscore'
{Mustard} = require '../../src/parser'

check_render = (input, output, context={}, debug=false) ->
    tpl = Mustard input, pretty:false, debug:debug
    expect( tpl.render(context) ).toEqual(output)

check_render_hash = (context, expected)->
    [context, expected] = [{}, context ] unless expected
        
    for input, output of expected
        if input not in ['_debug']
            check_render input, output, context, expected._debug

describe 'Debug', ->
    it '...', ->
        embed_context =
          i:0
          run: -> @i++; if @i > 3 then return false else true
          products: [{ name: "LP" }, { name: "CD" }, { name: "mp3" }]
            
        common_source = (str)-> """
            ul = { "<ul>" :yield  "</ul>" }
            li = { "<li>" :yield  "</li>" li { "blank" } }
            nav = { :yield  ul { :products -> :p { {{@class}} li :p.name } }}
            
            para = { "<p>" :yield "</p>" }
            bold = { "<b>" :yield "</b>" }
            bold_para = para { bold {{yield}} }
        """ + "\n" + str

        with_common_source = (attrs)->
            obj = {}
            for k,v of attrs
                obj[ common_source(k) ] = v
            check_render_hash obj

        with_common_source
            # _debug:true
            # 'bold_para "bold paragraph" ':
                # """<p><b>bold paragraph</b></p>"""

            ' nav "Hi!"': ''
                
               
