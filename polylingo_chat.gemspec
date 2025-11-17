Gem::Specification.new do |s|
  s.name = 'polylingo_chat'
  s.version = '0.1.1'
  s.summary = 'Realtime chat with automatic AI translation for Ruby/Rails apps'
  s.authors = ['Shoaib Malik']
  s.email = ['shoaib2109@gmail.com']
  s.files = Dir['lib/**/*.rb'] + Dir['lib/**/*'] + Dir['templates/**/*'] + ['README.md']
  s.homepage = 'https://github.com/AdwareTechnologies/polylingo_chat'
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.7.0'


  s.add_runtime_dependency 'rails', '>= 6.0', '< 9'
  s.add_runtime_dependency 'faraday', '~> 2.0'
  s.add_runtime_dependency 'concurrent-ruby', '~> 1.2'

  # Optional: Add one of these to your Gemfile based on your choice
  # s.add_development_dependency 'sidekiq', '~> 7.0'
  # s.add_development_dependency 'solid_queue', '~> 0.3'
  # s.add_development_dependency 'delayed_job_active_record', '~> 4.1'
end
