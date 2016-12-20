module Buckaruby
  module Support
    # The case insensitive Hash is a Hash with case insensitive keys that
    # can also be accessed by using a Symbol.
    class CaseInsensitiveHash < Hash
      def initialize(constructor = {})
        if constructor.is_a?(Hash)
          super()
          update(constructor)
        else
          super(constructor)
        end
      end

      def [](key)
        super(convert_key(key))
      end

      def []=(key, value)
        super(convert_key(key), value)
      end

      protected

      def update(hash)
        hash.each_pair { |key, value| self[convert_key(key)] = value }
      end

      def convert_key(key)
        string = key.is_a?(Symbol) ? key.to_s : key
        string.downcase
      end
    end
  end
end
