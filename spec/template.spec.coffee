_ = require '../vendor/underscore'
{Mustard} = require '../src/parser'

describe 'templates', ->
    
    it 'should compile simple templates', ->
        expected =
          '':''
          'p':'<p></p>'
          'p "hello"': '<p>hello</p>'
        
        for input, output of expected
            tpl = Mustard.create(input)
            expect( tpl.render() ).toEqual(output)
