module Interpolation

  INTERPOLATION_PATTERN = Regexp.union(
    /%%/,
    /%\{(\w+)\}/,                               # matches placeholders like "%{foo}"
    /%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps])/  # matches placeholders like "%<foo>.d"
  )

  def interpolate(string, values = {})
    string.gsub(INTERPOLATION_PATTERN) do |match|
      if match == '%%'
        '%'
      else
        key = ($1 || $2 || match.tr("%{}", "")).to_sym
        value = values[key]
        value = value.call(values) if value.respond_to?(:call)
        $3 ? sprintf("%#{$3}", value) : value
      end
    end
  end

  def symbolize_recursive(hash)
     {}.tap do |h|
       hash.each { |key, value| h[key.to_sym] = map_value(value) }
     end
   end

   def map_value(thing)
     case thing
     when Hash
       symbolize_recursive(thing)
     when Array
       thing.map { |v| map_value(v) }
     else
       thing
     end
   end

end
