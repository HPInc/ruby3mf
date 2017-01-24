class ContentTypes

  def initialize(found={}, over={})
    @found_types=found
    @found_overrides=over
  end

  def size
    @found_types.size + @found_overrides.size
  end

  def empty?
    size == 0
  end

  def get_type(target)
    target = (target.start_with?('/') ? target : '/' + target).downcase
    if @found_overrides[target]
      content_type = @found_overrides[target]
    else
      extension = File.extname(target).strip.downcase[1..-1]
      content_type = @found_types[extension]
    end
    content_type
  end

  def get_types()
    return @found_types.values + @found_overrides.values
  end

  private

  def self.parse(zip_entry)
    found_types = {}
    found_overrides = {}
    Log3mf.context "parse" do |l|
      begin
        doc = XmlVal.validate_parse(zip_entry)

        l.warning '[Content_Types].xml must contain exactly one root node' unless doc.children.size == 1
        l.warning '[Content_Types].xml must contain root name Types' unless doc.children.first.name == "Types"

        required_content_types = ['application/vnd.openxmlformats-package.relationships+xml']

        types_node = doc.children.first
        types_node.children.each do |node|
          l.context node.name do |l|
            if node.name == 'Default'
              extension = node['Extension'].downcase
              l.info "Setting type hash #{extension}=#{node['ContentType']}"
              l.error :duplicate_content_extension_types if !found_types[extension].nil?
              found_types[extension] = node['ContentType']
            elsif node.name == 'Override'
              part_name = node['PartName'].downcase
              l.error :empty_override_part_name if part_name.empty?

              l.error :duplicate_content_override_types if !found_overrides[part_name].nil?
              found_overrides[part_name] = node['ContentType']
            else
              l.warning "[Content_Types].xml:#{node.line} contains unexpected element #{node.name}", page: 10
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
    return new(found_types, found_overrides)
  end
end
