module Polyglot
  module Translator
    class Base
      def self.detect_language(text)
        raise NotImplementedError
      end

      def self.translate(text:, from:, to:, context:)
        raise NotImplementedError
      end
    end
  end
end
