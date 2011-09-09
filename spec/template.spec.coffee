_ = require '../vendor/underscore'
{Mustard} = require '../src/parser'

describe 'templates', ->
    check_render = (input, output) ->
        tpl = Mustard input, pretty:false
        expect( tpl.render() ).toEqual(output)

    check_render_hash = (expected)->
        for input, output of expected
            check_render input, output

    
    it 'should compile single elements with static properties', ->
        expected =
            '':''
            'p':'<p></p>'
            'p "hello"': '<p>hello</p>'
            'p.hello' : '<p class="hello"></p>'
            'p#hello' : '<p id="hello"></p>'
            'p#hello.world' : '<p id="hello" class="world"></p>'
            'p.hello#world.twice' : '<p class="hello twice" id="world"></p>'
            'p.hello#world.twice "with contents"' : '<p class="hello twice" id="world">with contents</p>'

            'a@href="http://thepaw.hu" "thepaw.hu"' : '<a href="http://thepaw.hu">thepaw.hu</a>'
            'a.link@href="http://thepaw.hu" "thepaw.hu"' : '<a class="link" href="http://thepaw.hu">thepaw.hu</a>'
            'a@href="/about" @target="_blank" "About"' : '<a href="/about" target="_blank">About</a>'

        check_render_hash expected
        

    it 'should compile nested elements', ->
        expected =
            'div { p "Hello" }': '<div><p>Hello</p></div>'
            'div .smile { p "Hello" }': '<div class="smile"><p>Hello</p></div>'
            'div p "hello"': '<div></div><p>hello</p>'
            'div; p "hello"': '<div></div><p>hello</p>'

        check_render_hash expected

