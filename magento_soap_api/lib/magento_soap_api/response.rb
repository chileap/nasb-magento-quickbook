module MagentoSoapApi
  class Response
    attr_accessor :document

    def initialize(response)
      @document = response.to_hash
    end

    def self.attr_map
      @attr_map
    end

    def to_hash
      hash = {}
      self.class.attr_map.keys.each do |attr|
        hash[attr] = send(attr)
      end
      hash
    end

  end
end
