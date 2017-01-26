require 'singleton'
require 'yaml'

# Example usage:

# Log3mf.context "box.3mf" do |l|
#   --do some stuff here

#   l.context "[Content-Types].xml" do |l|
#     -- try to parse file. if fail...
#     l.log(:fatal_error, "couldn't parse XML") <<<--- THIS WILL GENERATE FATAL ERROR EXCEPTION
#   end

#   l.context "examing Relations" do |l|
#     l.log(:error, "a non-fatal error")
#     l.log(:warning, "a warning")
#     l.log(:info, "it is warm today")
#   end
# end
#
# Log3mf.to_json


class Log3mf
  include Singleton
  include Interpolation

  LOG_LEVELS = [:fatal_error, :error, :warning, :info, :debug]

  SPEC_LINKS = {
    core: 'http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf',
    material: 'http://3mf.io/wp-content/uploads/2015/04/3MFmaterialsSpec_1.0.1.pdf',
    production: 'http://3mf.io/wp-content/uploads/2016/07/3MFproductionSpec.pdf',
    slice: 'http://3mf.io/wp-content/uploads/2016/07/3MFsliceSpec.pdf',
    #opc: 'http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-376,%20Fourth%20Edition,%20Part%202%20-%20Open%20Packaging%20Conventions.zip'
    opc: 'http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf'
  }.freeze

  # Allows us to throw FatalErrors if we ever get errors of severity :fatal_error
  class FatalError < RuntimeError
  end

  def initialize
    @log_list = []
    @context_stack = []
    @ledger = []
    errormap_path = File.join(File.dirname(__FILE__), "errors.yml")
    @errormap = YAML.load_file(errormap_path)
  end

  def reset_log
    @log_list = []
    @context_stack = []
  end

  def self.reset_log
    Log3mf.instance.reset_log
  end

  def context (context_description, &block)
    @context_stack.push(context_description)
    retval = block.call(Log3mf.instance)
    @context_stack.pop
    retval
  end

  def self.context(context_description, &block)
    Log3mf.instance.context(context_description, &block)
  end

  def method_missing(name, *args, &block)
    if LOG_LEVELS.include? name.to_sym
      if [:fatal_error, :error, :debug].include? name.to_sym
        linenumber = caller_locations[0].to_s.split('/')[-1].split(':')[-2].to_s
        filename = caller_locations[0].to_s.split('/')[-1].split(':')[0].to_s
        options = {linenumber: linenumber, filename: filename}
        # Mike: do not call error or fatal_error without an entry in errors.yml
        raise "{fatal_}error called WITHOUT using error symbol from: #{filename}:#{linenumber}" if ( !(args[0].is_a? Symbol) && (name.to_sym != :debug) )

        puts "***** Log3mf.#{name} called from #{filename}:#{linenumber} *****" if $DEBUG

        options = options.merge(args[1]) if args[1]
        log(name.to_sym, args[0], options)
      else
        log(name.to_sym, *args)
      end
    else
      super
    end
  end

  def log(severity, message, options = {})
    error = @errormap.fetch(message.to_s) { {"msg" => message.to_s, "page" => nil} }
    options[:page] = error["page"] unless options[:page]
    options[:spec] = error["spec"] unless options[:spec]
    entry = {id: message,
             context: "#{@context_stack.join("/")}",
             severity: severity,
             message: interpolate(error["msg"], options)}
    entry[:spec_ref] = spec_link(options[:spec], options[:page]) if (options && options[:page])
    entry[:caller] = "#{options[:filename]}:#{options[:linenumber]}" if (options && options[:filename] && options[:linenumber])
    @log_list << entry
    raise FatalError if severity == :fatal_error
  end

  def count_entries(*levels)
    entries(*levels).count
  end

  def self.count_entries(*l)
    Log3mf.instance.count_entries(*l)
  end

  def entries(*levels)
    return @log_list if levels.size == 0
    @log_list.select { |i| levels.include? i[:severity] }
  end

  def self.entries(*l)
    Log3mf.instance.entries(*l)
  end

  def spec_link(spec, page)
    spec = :core unless spec
    "#{SPEC_LINKS[spec]}#page=#{page}"
  end

  def to_json
    @log_list.to_json
  end

  def self.to_json
    Log3mf.instance.to_json
  end
end
