require 'rails/engine'
module Polyglot
  class Engine < ::Rails::Engine
    isolate_namespace Polyglot

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
