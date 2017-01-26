require 'spec_helper'

describe Log3mf do

  let(:log_levels) { Log3mf::LOG_LEVELS }

  let(:log) { Log3mf.instance }

  let(:logstuff) {
    log.context "context for specs" do |l|
      l.error(:schema_error, e: "This is an error", page: 14)
      l.warning("This is a Warning", page: 15)
      l.info("This is just Info", page: 16)
    end
  }

  let(:result) {
    [{id: :schema_error,
      context: "context for specs",
      severity: :error,
      message: "Schema error found: This is an error",
      spec_ref: "http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf#page=14",
      caller: "log3mf_spec.rb:11"},
     {id: "This is a Warning",
      context: "context for specs",
      severity: :warning,
      message: "This is a Warning",
      spec_ref: "http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf#page=15"},
     {id: "This is just Info",
      context: "context for specs",
      severity: :info,
      message: "This is just Info",
      spec_ref: "http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf#page=16"}]
  }

  describe 'when calling error with a string' do
    it 'should raise an exception' do
      expect {
        log.fatal_error "Strings must not be used for errors."
      }.to raise_error(RuntimeError, /error called WITHOUT using error symbol from:/)
    end
  end

  describe 'when fatal_error is logged' do
    it 'should raise a Log3mf::FatalError' do
      expect {
        log.context "context for fatal_error test" do |l|
          log.fatal_error(:schema_error, e: "Fatal Error")
        end
      }.to raise_error { |e|
        expect(e).to be_a(Log3mf::FatalError)
      }
    end
  end

  describe "testing all levels of log" do
    it "should have all kinds entries on log" do
      ENV['LOGDEBUG']='true'
      log_levels.each do |level|
        log.context "context for #{level} test" do |l|
          log.send(level.to_sym, :schema_error, e: level.to_s) rescue nil
          expect(Log3mf.entries(level.to_sym).count).to be >= 1
          expect(Log3mf.count_entries(level.to_sym)).to be >= 1
        end
      end
    end

    it 'should have all when level NOT provided' do
      logstuff
      expect(Log3mf.entries.count).to eq result.count
      expect(Log3mf.entries).to eq result
    end
  end

  describe 'spec links' do
    let(:specs) { Log3mf::SPEC_LINKS }

    it 'should default to core spec' do
      log.context "context for test spec links" do |l|
        log.error(:schema_error, e: "Fatal Error", page: 11)
        json = JSON.parse(Log3mf.to_json)
        expect(json.first["spec_ref"]).to eq("http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf#page=11")
      end
    end

    it 'should reference proper specification when supplied' do
      log.context "context for test spec links" do |l|
        specs.each do |k, v|
          log.error(:schema_error, e: "Fatal Error", spec: k.to_sym, page: 1)
          json = JSON.parse(Log3mf.to_json)
          expect(json.first["spec_ref"]).to eq("#{specs[k.to_sym]}#page=1")
          Log3mf.reset_log
        end
      end
    end
  end

  describe 'external access to_json' do
    it 'should respond with logged items in JSON' do
      logstuff
      expect(Log3mf.to_json).to eq result.to_json
    end
  end

  describe 'Log messages' do
    let(:logs) {
      log.context "context for Log Messages spec" do |l|
        l.error(:schema_error, e: "This is an error")
        l.warning("This is a Warning with no %{interpolation} options")
        l.info("This is just info with %{interpolation}", interpolation: "interpolated content")
      end
    }

    it 'should have the right log messages' do
      logs
      json = JSON.parse(Log3mf.to_json)
      expect(json[0]["message"]).to eq("Schema error found: This is an error")
      expect(json[1]["message"]).to eq("This is a Warning with no  options")
      expect(json[2]["message"]).to eq("This is just info with interpolated content")
    end

  end

end
