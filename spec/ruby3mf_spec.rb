require 'spec_helper'

describe Ruby3mf do
  before do
    Log3mf.reset_log
  end

  it 'has a version number' do
    expect(Ruby3mf::VERSION).not_to be nil
  end

  it 'parses a valid file without errors' do
    Log3mf.context "box.3mf" do |l|
      Document.read('spec/examples/box.3mf')
    end

    expect(Log3mf.count_entries(:error, :fatal_error)).to eq(0)
  end

  it 'parses a invalid file reporting 1 error' do
    Log3mf.context "3d_model_invalid_xml.3mf" do |l|
      Document.read('spec/examples/3d_model_invalid_xml.3mf')
    end

    expect(Log3mf.count_entries(:error, :fatal_error)).to eq(1)
    log = JSON.parse(Log3mf.to_json)
    fatal_error = log.select { |entry| entry["severity"]=="fatal_error" }.first
    expect(fatal_error["message"]).to include("Model file invalid XML")
  end



  describe "Document" do
    it 'should return a Document' do
      doc=Document.read('spec/examples/box.3mf')
      expect(doc).to be_a(Document)
    end

    context "document.model" do

      let(:source_file) { 'spec/examples/box.3mf' }

      before do
        @doc3mf=Document.read(source_file)
      end

      it 'should be a collection of model Hashes' do
        expect(@doc3mf.models).to be_an(Array)
        expect(@doc3mf.models.size).to be(1)
        @doc3mf.models.each do |model|
          expect(model).to be_a(Hash)
        end
      end

      it 'should write a copy of the zipfile' do
        output_file = Tempfile.new('foo')
        output_file.close
        @doc3mf.write(output_file.path)

        Zip::File.open(source_file) do |source_zip|
          source_entries={}
          source_zip.entries.each do | src_entry |
            source_entries[src_entry.name]=src_entry
          end
          Zip::File.open(output_file.path) do |dest_zip|
            dest_zip.entries.each do | dest_entry |
              if dest_entry.directory?
                expect(source_entries[dest_entry.name].directory?).to be_truthy
              else
                expect(source_entries.key?(dest_entry.name)).to be_truthy
                expect(source_entries[dest_entry.name].get_input_stream.read).to eq(dest_entry.get_input_stream.read)
              end
              source_entries.delete(dest_entry.name)
            end
          end
          expect(source_entries.size).to be(0)
        end

        output_file.unlink
      end

      context 'dealing with textures' do
        let(:source_file) { "spec/ruby3mf-testfiles/passing_cases/cube_horizQR.3mf" }


        it 'should write the changed texture' do
          png_bytes = File.open("spec/examples/qr_code_google.png", 'rb') { |f| f.read }
          t = @doc3mf.textures.first[:object]
          t.update(png_bytes)
          name = t.name
          output_file = Tempfile.new('changed_png')
          output_file.close
          @doc3mf.write(output_file.path)

          Zip::File.open(output_file.path) do |dest_zip|
            png_entry = dest_zip.glob(name).first
            expect(png_entry.name).to eq(name)
            expect(png_entry.get_input_stream.read).to eq(png_bytes)
          end
          output_file.unlink
        end

        it 'should return the original bytes when texture has not been modified' do
          orig_png_bytes = File.open("spec/examples/orig_cube_qr.png", 'rb') { |f| f.read }
          t = @doc3mf.textures.first[:object]
          expect(t.contents).to eq(orig_png_bytes)
        end

        it 'should return the correct bytes when the output file has not yet been written' do
          png_bytes = File.open("spec/examples/qr_code_google.png", 'rb') { |f| f.read }
          t = @doc3mf.textures.first[:object]
          t.update(png_bytes)
          expect(t.contents).to eq(png_bytes)
        end

        it 'should return the correct bytes after the output file has been written' do
          png_bytes = File.open("spec/examples/qr_code_google.png", 'rb') { |f| f.read }
          t = @doc3mf.textures.first[:object]
          t.update(png_bytes)
          output_file = Tempfile.new('changed_png')
          output_file.close
          @doc3mf.write(output_file.path)
          expect(t.contents).to eq(png_bytes)
          output_file.unlink
        end
      end

    end
  end

end
