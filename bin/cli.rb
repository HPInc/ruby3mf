#!/usr/bin/env ruby

require_relative '../lib/ruby3mf'

doc = Document.read(ARGV.first)

errors = Log3mf.entries(:error, :fatal_error)
puts "Validating file: #{ARGV.first}"
errors.each do |ent|
  h = { context: ent[0], severity: ent[1], message: ent[2] }
  puts h
end
