#!/usr/bin/env ruby

require_relative '../lib/ruby3mf'

files = Dir["spec/ruby3mf-testfiles/#{ARGV[0] || "failing_cases"}/*.#{ARGV[1] || '3mf'}"]

files.each do |file|
  begin
    Log3mf.reset_log
    doc = Document.read(file)
    errors = Log3mf.entries(:error, :fatal_error)

    puts "=" * 100
    puts "Validating file: #{file}"

    puts errors

  rescue
  end
end
