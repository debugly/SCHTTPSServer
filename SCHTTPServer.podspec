#
# Be sure to run `pod lib lint SCHTTPServer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SCHTTPServer'
  s.version          = '0.1.0'
  s.summary          = 'A short description of SCHTTPServer.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  SCHTTPServer is a small, lightweight, embeddable HTTPS server for Mac OS X applications,based on CocoaHTTPServer.
                       DESC

  s.homepage         = 'https://github.com/debugly/SCHTTPServer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Matt Reach' => 'qianlongxu@sohu-inc.com' }
  s.source           = { :git => 'https://github.com/debugly/SCHTTPServer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  #s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  
  s.source_files = 'SCHTTPServer/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SCHTTPServer' => ['SCHTTPServer/Assets/*.png']
  # }
  s.requires_arc = true
  s.public_header_files = 'SCHTTPServer/Classes/Connection/HTTPConnection.h' , 'SCHTTPServer/Classes/HTTP/HTTPServer.h', 'SCHTTPServer/Classes/Connection/P12HTTPConnection.h',  'SCHTTPServer/Classes/HTTP/HTTPLogger.h'
  s.frameworks = 'Security', 'Foundation'
  s.dependency 'CocoaAsyncSocket'
  
end
