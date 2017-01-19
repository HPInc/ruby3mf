class Relationships

  def self.parse(zip_entry)
    relationships = []
    Log3mf.context "parsing relationships" do |l|
      begin
        # Parse Relationships XML
        doc = XmlVal.validate_parse(zip_entry)

        # Verify <Relationships><Relationship/></Relationships>
        root_element = doc.children[0]
        if root_element.name == "Relationships"
          relationship_elements = root_element.children
          if relationship_elements.size > 0
            relationship_elements.each do |node|
              if node.is_a?(Nokogiri::XML::Element) && node.name == "Relationship"
                l.error :multiple_relationships if (relationships.select { |r| r[:target] == node['Target'] && r[:type] == node['Type'] }.size > 0)
                l.error :non_unique_rel_id, :file => zip_entry.name, :id => node['Id'] if (relationships.select { |r| r[:id] == node['Id'] }.size > 0)
                relationships << {target: node['Target'], type: node['Type'], id: node['Id']}
                l.info "adding relationship: #{relationships.last.inspect}"
              else
                unless node.is_a? Nokogiri::XML::Text
                  l.info "found non-Relationship node: #{node.name}"
                end
              end
            end

            if zip_entry.name=="_rels/.rels"
              l.context "Verifying StartPart" do |l|
                start_part_type = Document::MODEL_TYPE
                start_part_count = relationships.select { |r| r[:type] == start_part_type }.size
                if start_part_count != 1
                  l.error :invalid_startpart_type
                end
              end
            end
          else
            l.error "No relationship elements found", page: 4
          end
        else
          l.error ".rels XML must have &lt;Relationships&gt; root element", page: 4
        end

      rescue Nokogiri::XML::SyntaxError => e
        l.error "Relationships (.rel) file is not a valid XML file: #{e.message}", page: 4
      end
    end
    relationships
  end
end
