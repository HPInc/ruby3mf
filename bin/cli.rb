#!/usr/bin/env ruby

require_relative '../lib/ruby3mf'

filename = ARGV.first
doc = Document.read(filename)

errors = Log3mf.entries(:error, :fatal_error)
puts errors

# set exit code for suite test usage
exit errors.size == 0
