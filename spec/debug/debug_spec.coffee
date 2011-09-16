_ = require '../../vendor/underscore'
{Mustard} = require '../../src/parser'

check_render = (input, output, context={}, debug=false) ->
    try
      tpl = Mustard input, pretty:false, debug:debug
      expect( tpl.render(context) ).toEqual(output)
    catch e
      if e.stack == undefined
        console.log e
        console.log e.message
        expect( 'Jasmine' ).toEqual( 'exception failed' )
      else
        throw e

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
            
        # common_source = (str)-> """
        #     ul = { "<ul>" :yield  "</ul>" }
        #     li = { "<li>" :yield  "</li>" li "" }
        #     nav = { :yield  ul { :products -> :p { {{@class}} li :p.name } }}
            
        #     para = { "<p class='{{ @class }}'>" :yield "</p>" }
        #     bold = { "<b>" :yield "</b>" }
        #     bold_para = { {{@class}} para { bold {{yield}} } }
        # """ + "\n" + str

        common_source = (str)-> """
        p = { "<p class=\"{{ yield }}\">" :yield"</p>" }
        nav = { p.p{{@class}} "para" :yield }
        """ + "\n" + str

        with_common_source = (attrs)->
            obj = {}
            for k,v of attrs
                obj[ common_source(k) ] = v
            check_render_hash obj

        with_common_source
            # _debug:true
            # 'bold_para.bold "bold paragraph" ':
            #     """<p><b>bold paragraph</b></p>"""

            ' nav.hi "Hi!"': ''
                
               
