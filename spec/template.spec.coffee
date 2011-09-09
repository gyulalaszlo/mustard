_ = require '../vendor/underscore'
{Mustard} = require '../src/parser'

check_render = (input, output, context={}) ->
    tpl = Mustard input, pretty:false
    expect( tpl.render(context) ).toEqual(output)

check_render_hash = (context, expected)->
    [context, expected] = [{}, context ] unless expected
        
    for input, output of expected
        check_render input, output, context
        
describe 'templates', ->

    
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


    it 'should create blank divs', ->
        check_render_hash
            '.hi': '<div class="hi"></div>'
            '#play "play"': '<div id="play">play</div>'
            '#play { a@href="#" "play" }': '<div id="play"><a href="#">play</a></div>'


describe 'interpolation', ->
    
    context =
        artist: "BrixAndBones"
        title: "(Say my name) I'll Play your game boy"
        id: 'track_07'
        slug: 'say_my_name'
        year: 2011
        track: 2
        element: 'section'

    it 'should interpolate strings', ->
        check_render_hash context,
            '{{artist}}':'BrixAndBones'
            '"{{artist}}"':'BrixAndBones'
            '"by {{artist}}"': 'by BrixAndBones'
            '"{{title}} by {{artist}}"': "#{context.title} by BrixAndBones"
            'p {{artist}}': '<p>BrixAndBones</p>'
            'p.artist {{artist}}': '<p class="artist">BrixAndBones</p>'

            'p.combined { span.artist {{artist}} span.song {{title}} }':
                  '<p class="combined"><span class="artist">BrixAndBones</span><span class="song">' +
                  context.title + '</span></p>'



    it 'should interpolate using the shorthand syntax', ->
        check_render_hash context,
            ':artist':'BrixAndBones'
            'p :artist': '<p>BrixAndBones</p>'
            'p.artist :artist': '<p class="artist">BrixAndBones</p>'

            'p.combined { span.artist :artist span.song :title }':
                  '<p class="combined"><span class="artist">BrixAndBones</span><span class="song">' +
                  context.title + '</span></p>'


         
    it 'should interpolate attribtues', ->
        check_render_hash context,
            'p.{{slug}}': '<p class="say_my_name"></p>'
            'p#{{slug}}': '<p id="say_my_name"></p>'
            'p.year_{{year}} {{year}}': '<p class="year_2011">2011</p>'
            '.year_{{year}} .sortable {{year}}': '<div class="year_2011 sortable">2011</div>'

    it 'should interpolate element names', ->
        check_render_hash context,
            '%{{element}}': '<section></section>'
            '%{{element}}.{{id}}': '<section class="track_07"></section>'
            '%{{element}}.{{id}} :slug': '<section class="track_07">say_my_name</section>'
            
