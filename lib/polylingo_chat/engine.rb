require 'rails/engine'
module PolylingoChat
  class Engine < ::Rails::Engine
    isolate_namespace PolylingoChat

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
