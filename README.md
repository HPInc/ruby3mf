# Ruby3mf

[![Gem Version](https://badge.fury.io/rb/ruby3mf.svg)](http://badge.fury.io/rb/ruby3mf)

The ruby3mf gem provides an API for parsing and validating 3MF files.  It includes a logging mechanism that enables developers to programmatically check a 3MF file for warnings or errors and respond in whatever way is appropriate for their application.  Ruby3mf checks everything in the 3MF core specification, from making sure that the 3MF package contains all content in the right format needed to print the file, to verifying that the geometry represents a manifold solid without holes or incorrectly oriented triangles. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby3mf'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby3mf

## Usage

```ruby
Log3mf.reset_log
Log3mf.context <filename> do |l|
    Document.read(<file>)
end
 
if Log3mf.count_entries(:error, :fatal_error) > 0
    entries = Log3mf.entries
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruby3mf. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

