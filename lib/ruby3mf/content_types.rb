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

        extensions = doc.css(*['Default']).map{|node| node.attributes['Extension']&.value}.flatten
        l.error :duplicate_content_extension_types unless extensions.uniq.length == extensions.length

        override_extensions = doc.css(*['Override']).map{|node| node.attributes['PartName']&.value}.flatten
        l.error :duplicate_content_override_types unless override_extensions.uniq.length == override_extensions.length

        found_types     = Hash[*doc.css(*['Default']).map{|node| [node.attributes['Extension']&.value&.downcase,node.attributes['ContentType']&.value]}.flatten]
        found_overrides = Hash[*doc.css(*['Override']).map{|node| [node.attributes['PartName']&.value&.downcase,node.attributes['ContentType']&.value]}.flatten]

        required_content_types.each do |req_type|
          l.error :invalid_content_type, mt: req_type unless found_types.values.include?(req_type)
        end

        doc.css(*['Default']).each do |node|
          extension = node['Extension']&.downcase
          l.info "Setting type hash #{extension}=#{node['ContentType']}"
        end

        doc.css(*['Override']).each do |node|
          l.error :empty_override_part_name if node['PartName']&.downcase&.empty?
        end

        doc.css('Types').xpath('.//*').select do |node|
          l.warning "[Content_Types].xml:#{node.line} contains unexpected element #{node.name}", page: 10 unless ['Default', 'Override'].include?(node.name)
        end

      rescue Nokogiri::XML::SyntaxError => e
        l.error :content_types_invalid_xml, e: "#{e}"
      end
    end
    return new(found_types, found_overrides)
  end
end
