require 'singleton'

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
# Log3mf.pp


class Log3mf
  include Singleton

  LOG_LEVELS = [:fatal_error, :error, :warning, :info, :debug]

  # Allows us to throw FatalErrors if we ever get errors of severity :fatal_error
  class FatalError < RuntimeError
  end

  def initialize()
    @log_list = []
    @context_stack = []
    @ledger = []
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
    #puts "started context #{@context_stack.join("/")}"

    retval = block.call(Log3mf.instance)

    @context_stack.pop
    retval
  end

  def self.context(context_description, &block)
    Log3mf.instance.context(context_description, &block)
  end

  def method_missing(name, *args, &block)
    if LOG_LEVELS.include? name.to_sym
      #puts "***** #{name} called from #{caller[0]}"
      log(name.to_sym, *args)
    else
      super
    end
  end

  def log(severity, message, options={})
    @log_list << ["#{@context_stack.join("/")}", severity, message, options] unless severity==:debug && ENV['LOGDEBUG'].nil?
    #puts "[#{@context_stack.join("/")}] #{severity.to_s.upcase} #{message}"
    raise FatalError if severity == :fatal_error
  end

  def count_entries(*levels)
    entries(*levels).count
  end

  def self.count_entries(*l)
    Log3mf.instance.count_entries(*l)
  end

  def entries(*levels)
    @log_list.select { |i| levels.include? i[1] }
  end

  def self.entries(*l)
    Log3mf.instance.entries(*l)
  end

  def spec_link(spec, page)
    spec = :core unless spec
    doc_urls={
      core: 'http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf',
      material: 'http://3mf.io/wp-content/uploads/2015/04/3MFmaterialsSpec_1.0.1.pdf',
      production: 'http://3mf.io/wp-content/uploads/2016/07/3MFproductionSpec.pdf',
      slice: 'http://3mf.io/wp-content/uploads/2016/07/3MFsliceSpec.pdf'
    }
    "#{doc_urls[spec]}#page=#{page}"
  end

  def to_json
    @log_list.collect { |ent|
      h = { context: ent[0], severity: ent[1], message: ent[2] }
      h[:spec_ref] = spec_link(ent[3][:spec], ent[3][:page]) if (ent[3] && ent[3][:page])
      h
    }.to_json
  end

  def self.to_json
    Log3mf.instance.to_json
  end

  # Pretty print our errors!
  def to_pp
    s = []
    s << "<i>Listing #{@log_list.size} log lines:</i>"
    longest_context = @log_list.collect { |logline| logline[0].size }.max
    longest_severity = @log_list.collect { |logline| logline[1].size }.max

    @log_list.each do |logline|
      msg = logline[2]
      if logline[3] && logline[3][:page]
        msg = "<a href=\"#{spec_link(logline[3][:spec], logline[3][:page])}\" target=\"_blank\">#{msg}</a>"
      end
      s << "[#{logline[0].ljust(longest_context)}] #{logline[1].to_s.upcase.ljust(longest_severity)} #{msg}"
    end
    s << "<br/>"
    s.map! { |row| row.include?("ERROR") ? "<b>#{row}</b>" : row }
    s.join("<br/>")
  end

  def self.to_pp
    Log3mf.instance.to_pp
  end
end

