class DeliveryHelper
  class Gemrc
    # Returns true if the attribute should be a Gemrc symbol, false otherwise
    def self.symbol?(attr)
      symbol_list.include?(attr)
    end

    # Returns a list of Gemrc attributes that must be symbols
    def self.symbol_list
      %w(benchmark verbose update_sources sources backtrace bulk_threshold gemhome gempath)
    end

    # Converts a Hash into a Gemrc YAML format file
    def self.to_yaml(hash)
      parameters = {}

      hash.each do |attr, value|
        attr = attr.to_sym if symbol?(attr)
        value = value.to_a if value.is_a?(Chef::Node::ImmutableArray)
        parameters.merge!(attr => value)
      end

      parameters.to_yaml
    end
  end
end
