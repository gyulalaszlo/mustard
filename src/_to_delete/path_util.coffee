{$meta} = require './meta'
path = require 'path'

class _PathUtil
    constructor: (@_path)->

    $meta(@)
      .attr('path', set:false)
      .attr('ext',
        chain: true
        getter: -> path.extname(@_path)
        setter: (ext)->
          @_path = @_path.replace new RegExp("\\.[a-zA-Z0-9\\-_]+$", 'g'), ext
      ).attr('dir',
        chain: true
        getter: -> path.dirname(@_path)
        setter: (dir)-> @_path = "#{dir}/#{path.basename @_path}"
      )

$path = (e)-> new _PathUtil(e)

root = exports ? this
root.$path = $path
