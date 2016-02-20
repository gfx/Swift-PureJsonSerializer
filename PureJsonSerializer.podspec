Pod::Spec.new do |spec|
  spec.name         = 'PureJsonSerializer'
  spec.version      = '1.1.3'
  spec.license      = { :type => 'Apache 2.0'}
  spec.homepage     = 'https://github.com/gfx/Swift-JsonSerializer'
  spec.authors      = { 'Goro Fuji' => 'gfuji@cpan.org' }
  spec.summary      = 'A pure-Swift JSON serializer and deserializer'
  spec.source       = { :git => 'https://github.com/gfx/Swift-JsonSerializer.git', :tag => "#{spec.version}" }
  spec.source_files = 'JsonSerializer/*.{swift}', 'Source/**/*.{swift}'

  spec.ios.deployment_target = "8.0"
  spec.osx.deployment_target = "10.9"
  spec.watchos.deployment_target = "2.0"
  spec.tvos.deployment_target = "9.0"
  spec.requires_arc = true
  spec.social_media_url = 'https://twitter.com/__gfx__'
end
