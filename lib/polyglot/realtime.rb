module Polyglot
  module Realtime
    def self.channel_template
      # returns a string of the channel implementation for host app generator
      File.read(File.expand_path('../../templates/polyglot_chat_channel.rb', __dir__))
    end
  end
end
