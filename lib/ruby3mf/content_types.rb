class ContentTypes

  def self.parse(zip_entry)
    found_types={}

    Log3mf.context "parse" do |l|
      begin

        doc = Nokogiri::XML(zip_entry.get_input_stream) do |config|
          config.strict.nonet.noblanks
        end

        l.warning '[Content_Types].xml must contain exactly one root node' unless doc.children.size == 1
        l.warning '[Content_Types].xml must contain root name Types' unless doc.children.first.name == "Types"

        required_content_types = ['application/vnd.openxmlformats-package.relationships+xml', 'application/vnd.ms-package.3dmanufacturing-3dmodel+xml']
        #optional_content_types = ['application/vnd.ms-printing.printticket+xml']
        #all_types = required_content_types + optional_content_types

        types_node = doc.children.first
        types_node.children.each do |node|
          l.context node.name do |l|
            unless node.name == 'Default'
              l.warning "[Content_Types].xml:#{node.line} contains unexpected element #{node.name}", page: 10
            else
              # l.error "[Content_Types].xml:#{node.line} contains Default node without defined Extension attribute" unless node['Extension'].is_a? String
              # l.error "[Content_Types].xml:#{node.line} contains Default node with unexpected ContentType \"#{node['ContentType']}\"", page: 10 unless all_types.include? node['ContentType']
              l.info "Setting type hash #{node['Extension']}=#{node['ContentType']}"
              found_types[node['Extension']] = node['ContentType']
            end
          end
        end
        required_content_types.each do |req_type|
          l.error "[Content_Types].xml is missing required ContentType \"#{req_type}\"", page: 10 unless found_types.values.include? req_type
        end
      rescue Nokogiri::XML::SyntaxError => e
        l.error "[Content_Types].xml file is not valid XML. #{e}", page: 15
      end
    end

    found_types
  end
end
