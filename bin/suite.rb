#!/usr/bin/env ruby

require_relative '../lib/ruby3mf'

# usage
# bin/suite.rb {path to 3mf-test-suite} optional
# assumes . is ~/src/ruby3mf and that ~/src/3mf-test-suite is path to suite repo files

$stdout.sync = true

good_files = Dir["#{ARGV[0] || '../3mf-test-suite'}/Positive/*.3mf"]
bad_files = Dir["#{ARGV[0] || '../3mf-test-suite'}/Negative/*.3mf"]

false_negatives = {}
true_negatives={}
false_positives = []

def val3mf(f)
  Log3mf.reset_log
  Document.read(f)
  Log3mf.entries(:fatal_error, :error)
end

puts "\n\nPositive"
good_files.each do |file|
  print "." # "Validating file: #{file}"
  errors=val3mf(file)

  if errors.size > 0
    false_negatives[file]=errors
    puts "\n#{file}"
    errors.each do |ent|
      h = {context: ent[0], severity: ent[1], message: ent[2]}
      puts "  #{h}"
    end
  end

end

puts "\n\nNegative"
bad_files.each do |file|
  print "." #puts "Validating file #{file}"
  errors=val3mf(file)
  if errors.size > 0
    true_negatives[file] = errors
  else
    false_positives << file
    puts "\n#{file} - No Errors Found!"
  end
end
