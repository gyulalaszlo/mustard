_ = require '../vendor/underscore'
{Mustard} = require '../src/parser'

check_render = (input, output, context={}, debug=false) ->
    tpl = Mustard input, pretty:false, debug:debug
    expect( tpl.render(context) ).toEqual(output)

check_render_hash = (context, expected)->
    [context, expected] = [{}, context ] unless expected
        
    for input, output of expected
        if input not in ['_debug']
            check_render input, output, context, expected._debug
        
context =
    artist_id: 'brixandbones'
    artist: "BrixAndBones"
    title: "(Say my name) I'll Play your game boy"
    id: 'track_07'
    slug: 'say_my_name'
    year: 2011
    track: 2
    element: 'section'
    formats:
        portable: 'portable.mp3'
        hq: 'hq.mp3'
    
    key: -> "bb-#{@id}"
    url: -> "/#{@artist_id}/#{@year}/#{@slug}"
    files: -> "files/#{val}" for format, val of @formats

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
            'div p "hello"': '<div><p>hello</p></div>'
            'div; p "hello"': '<div></div><p>hello</p>'

        check_render_hash expected


    it 'should create blank divs', ->
        check_render_hash
            '.hi': '<div class="hi"></div>'
            '#play "play"': '<div id="play">play</div>'
            '#play { a@href="#" "play" }': '<div id="play"><a href="#">play</a></div>'


describe 'interpolation', ->
    

    describe 'attribute interpolation', ->

        it 'should interpolate strings', ->
            check_render_hash context,
                '{{artist}}':'BrixAndBones'
                '"{{artist}}"':'BrixAndBones'
                '"by {{artist}}"': 'by BrixAndBones'
                '"{{title}} by {{artist}}"': "#{context.title} by BrixAndBones"
                'p {{artist}}': '<p>BrixAndBones</p>'
                'p.artist {{artist}}': '<p class="artist">BrixAndBones</p>'
                'a @href={{url}} #{{key}}': '<a href="'+ context.url() + '" id="bb-track_07"></a>'

                'p.combined { span.artist {{artist}} span.song {{title}} }':
                      '<p class="combined"><span class="artist">BrixAndBones' +
                      '</span><span class="song">' +
                      context.title + '</span></p>'



        it 'should interpolate using the shorthand syntax', ->
            check_render_hash context,
                ':artist':'BrixAndBones'
                'p :artist': '<p>BrixAndBones</p>'
                'p.artist :artist': '<p class="artist">BrixAndBones</p>'

                'p.combined { span.artist :artist span.song :title }':
                      '<p class="combined"><span class="artist">BrixAndBones' +
                      '</span><span class="song">' + context.title + '</span></p>'


             
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
                
    describe 'scopes', ->
        
        it 'should key open up object', ->
            check_render_hash context,
                ':formats -> :format { {{format.hq}}  }': 'hq.mp3'
                '{{formats}} -> {{f}} { :f.hq  }': 'hq.mp3'
                ':formats -> :format { {{format.hq}}  } :format.hq': 'hq.mp3'

        it 'should iterate over keys', ->
            check_render_hash context,
                ':formats -> :format, :link { a .{{format}} @href={{link}} }': '<a class="portable" href="portable.mp3"></a><a class="hq" href="hq.mp3"></a>'

        it 'should iterate over arrays', ->
            check_render_hash context,
                ':files -> :file { a @href=:file }': '<a href="files/portable.mp3"></a><a href="files/hq.mp3"></a>'
                ':files -> :file { a @href=:file } p :file': '<a href="files/portable.mp3"></a><a href="files/hq.mp3"></a><p></p>'


describe 'declarations', ->
    it 'should render declarations', ->
        check_render_hash
            'world = "world" "hello " world': 'hello world'
            'world = b "world" "hello " world': 'hello <b>world</b>'
            'nav_link =  li.nav_link { a@href="/" "home" } nav_link; nav_link; ':
                '<li class="nav_link"><a href="/">home</a></li>' +
                '<li class="nav_link"><a href="/">home</a></li>'

describe 'Debug', ->
    it '...', ->
        embed_context =
          i:0
          run: -> @i++; if @i > 3 then return false else true
        check_render_hash _.clone(embed_context),
            _debug:true
            'one = { :run -> {  "in one " two } } two = { :run -> { "in two " one } } one': '4'
            # ':formats -> :format { {{format.hq}}  }': 'hq.mp3'
                
