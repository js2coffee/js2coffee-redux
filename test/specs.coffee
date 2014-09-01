require 'coffee-script/register'
require './setup'

coffee = require('coffee-script')
path = require('path')
glob = require('glob')
fs = require('fs')

groups = glob.sync("#{__dirname}/../specs/*")

toName = (dirname) ->
  s = path.basename(dirname).replace(/_/g, ' ').trim()
  s = s.replace(/\.txt$/, '')
  s.substr(0,1).toUpperCase() + s.substr(1)

describe 'specs:', ->
  for group in groups
    describe toName(group) + ":", ->

      specs = glob.sync("#{group}/*")
      for spec in specs

        name = toName(spec)
        isPending = ~group.indexOf('pending') or ~name.indexOf('pending')
        test = if isPending then xit else it
        data = fs.readFileSync(spec, 'utf-8')
        [meta, input, output] = data.split('----\n')
        if meta.length
          meta = coffee.compile(meta, bare: true)

        test name, do (spec, input, output) ->
          ->
            result = js2coffee(input)
            try
              expect(result).eql(output)
            catch e
              e.stack = ''
              throw e
