Pod::Spec.new do |s|
  s.name             = "DeluxeInjection"
  s.version          = "0.5.2"
  s.summary          = "Simplest Objective-C Dependency Injection (DI:syringe:) implementation ever"

  s.description      = <<-DESC
                       DeluxeInjection allows you simply inject any property of any class by defining value or
                       getter of this property with a block. This should be the simplest DI library ever.
                       DESC

  s.homepage         = "https://github.com/k06a/DeluxeInjection"
  s.license          = 'MIT'
  s.author           = { "Anton Bukov" => "k06aaa@gmail.com" }
  s.source           = { :git => "https://github.com/k06a/DeluxeInjection.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/k06a'

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '1.0'

  s.source_files = 'DeluxeInjection/Classes/**/*'
  s.dependency 'RuntimeRoutines'
end
