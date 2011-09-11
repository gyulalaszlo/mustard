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
            

        check_render_hash _.clone(embed_context),
            # _debug:true
            """
            ul = { "<ul>" :yield  "</ul>" }
            li = { "<li>" :yield  "</li>" }
            nav = { :yield ul { :products -> :p { li :p.name } }}
            
            para = { "<p>" :yield "</p>" }
            bold = { "<b>" :yield "</b>" }
            bold_para = para { bold {{yield}} }

            bold_para "bold paragraph"
            nav "Hi"
            """:"""<p><b>bold paragraph</b></p>"""
            # 'para = { "<p>"  {{yield}} "</p>"} para "hello" ':'<p>hello</p>'
            # 'one = { :run -> {  "in one " two } } two = { :run -> { "in two " one } } one': '4'
            # ':formats -> :format { {{format.hq}}  }': 'hq.mp3'
                
