fs            = require 'fs'
path          = require 'path'
_ = require 'underscore'
require 'icing'
# {$meta} = require './src/meta'
{$path} = require './src/path_util'





source_files = [
  'meta', 'text_area_selection', 'mdedit'
]

dependencies = [
  # 'build/underscore.string.js', 'build/showdown.js' 
]
# dependecies_total_list = dependencies.concat source_files

dist_file = 'mdedit'


concat_files = (output, files...)->
  flist = _(files).flatten()
  code = []
  for file in flist
    code.push fs.readFileSync(file)
  fs.writeFile "#{output}", code.join(";\n\n")


fileTask = (maps={}, dependencies=[], func=()-> )->
    _(maps).each (output, input)->
        inmtime = if path.existsSync input then fs.statSync(input).mtime else 0
        outmtime = if path.existsSync output then fs.statSync(output).mtime else 0
        
        # Check mtime and proceed if input is newer (this prevents
        # creation of unnecessary tasks
        return unless inmtime >= outmtime
        deps =[input].concat( _(dependencies).map((e)-> "task(#{e}"))
        console.log deps
        task output, "FileTask:#{input} -> #{output}", deps, ->
                outputs: output
                recipe: ->
                    func.call(this, input:input, output:output, deps:dependencies)
                    @finished()

          # .concat( _(dependencies).map((e)-> "output(#{e}")),
          #     outputs: _(maps).values()
          #     recipe: _(maps).each _(func).bind(this)

fileTask = (taskname, source, output, transform)->
    task 'build:parser', 'Build the PEG parser', ['src/mustard.pegjs'], ->
        outputs: -> _(this.filePrereqs).map (f)-> outputName(f)
        recipe: _(this.filePrereqs).map (f)-> @exec "pegjs #{file} #{outputName(file)}"



pegjsTask = ()->
    opath = (f)->$path(f).ext('_pegjs.js').dir('build').path()
    return {
        outputs: -> opath(f) for f in @filePrereqs
        recipe: ->
            for f in @filePrereqs
              @exec "pegjs #{f} #{opath f}"
              @finished()
    }


cleanTask = ->
    outputs: @exec "coffee -o #{}"

coffeeCompileTask = ->
    outputs: @exec "coffee -o #{}"



#
# fileTask 'src/indented_buffer.coffee':'buffer.js', [], (task)->
#     # console.log task
#     console.log "HI", task
#     # @exec "coffee -o #{task.output} #{task.input}"
#     console.log "coffee -o #{task.output} #{task.input}"

task 'build:parser', 'Build the PEG parser', ['src/mustard.pegjs'], pegjsTask()
task 'build', "Build the output", ['task(build:parser)'], -> @finished()

task 'spec', 'Run the specs', ['task(build)'], ->
    @exec "jasmine-node spec --coffee"
    @finished()
  
