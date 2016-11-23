# https://gist.github.com/huy/819999
require 'nokogiri'

class Hash
  class << self
    def from_xml(xml_doc)
      begin
        return { xml_doc.root.name.to_sym => xml_node_to_hash(xml_doc.root)}
      rescue Exception => e
        # raise your custom exception here
      end
    end

    def xml_node_to_hash(node)
      # If we are at the root of the document, start the hash
      if node.element?
        result_hash = {}
        if node.attributes != {}
          attributes = {}
          node.attributes.keys.each do |key|
            attributes[node.attributes[key].name.to_sym] = node.attributes[key].value
          end
        end
        if node.children.size > 0
          node.children.each do |child|
            result = xml_node_to_hash(child)

            if child.name == "text"
              unless child.next_sibling || child.previous_sibling
                return result unless attributes
                result_hash[child.name.to_sym] = result
              end
            elsif result_hash[child.name.to_sym]

              if result_hash[child.name.to_sym].is_a?(Object::Array)
                 result_hash[child.name.to_sym] << result
              else
                 result_hash[child.name.to_sym] = [result_hash[child.name.to_sym]] << result
              end
            else
              result_hash[child.name.to_sym] = result
            end
          end
          if attributes
             #add code to remove non-data attributes e.g. xml schema, namespace here
             #if there is a collision then node content supersets attributes
             result_hash = attributes.merge(result_hash)
          end
          return result_hash
        else
          return attributes
        end
      else
        return node.content.to_s
      end
    end
  end
end
