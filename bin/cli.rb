#!/usr/bin/env ruby

require_relative '../lib/ruby3mf'

filename = ARGV.first
doc = Document.read(filename)

errors = Log3mf.entries(:error, :fatal_error)
errors.each do |ent|
  h = { file: filename, context: ent[0], severity: ent[1], message: ent[2] }
  puts h
end
