require 'spec_helper'
require 'nokogiri'

describe GlobalXMLValidations do

  let(:xml) { Nokogiri::XML(
    '<?xml version="1.0" encoding="UTF-8"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
          <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
        </Types>'
  )
  }


  context 'when xml space attribute is present' do
    let(:xml) { Nokogiri::XML(
      '<?xml version="1.0" encoding="UTF-8"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" xml:space="preserved" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
                  <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
                </Types>'
    )
    }

    let(:message) { "found an xml:space attribute when it is not allowed" }
    it 'should give an error' do
      GlobalXMLValidations.validate(xml)
      expect(Log3mf.count_entries(:error)).to be == 1
      expect(Log3mf.entries(:error).first[2]).to include message
    end
  end

  context 'when xml space attribute is not present' do
    it 'should be supes chill (not give an error) if the xml:space attribute is missing' do
      GlobalXMLValidations.validate(xml)
      expect(Log3mf.count_entries(:error)).to be == 0
      expect(Log3mf.entries(:error)).to be_empty
    end
  end
end
