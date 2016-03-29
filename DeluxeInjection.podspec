Pod::Spec.new do |s|
  s.name             = "DeluxeInjection"
  s.version          = "0.1.3"
  s.summary          = "Simplest DI implementation ever"

  s.description      = <<-DESC
                       DeluxeInjection allows you simply to inject any property to any class by defining getter of this property within a block. This should be the simplest DI library.
                       DESC

  s.homepage         = "https://github.com/k06a/DeluxeInjection"
  s.license          = 'MIT'
  s.author           = { "Anton Bukov" => "k06aaa@gmail.com" }
  s.source           = { :git => "https://github.com/k06a/DeluxeInjection.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/k06a'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
end
