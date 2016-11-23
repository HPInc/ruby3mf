require 'spec_helper'

describe Thumbnail3mf do

  let(:file_path) { "spec/ruby3mf-testfiles/failing_cases/3d_payload_files.3mf" }
  let(:zip_file)  { Zip::File.open(file_path) }
  let(:images)    { zip_file.glob('**/*texture') }
  let(:message)   { "thumbnail is of type: image/jpeg"}

  it "The images may be of content type image/jpeg or image/png" do
    ENV['LOGDEBUG']='true'
    Thumbnail3mf.parse(:doc, images.first, :relationships)
    expect(Log3mf.entries(:debug).first[2]).to include message
  end

end
