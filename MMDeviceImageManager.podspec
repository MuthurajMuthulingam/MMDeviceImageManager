#
# Be sure to run `pod lib lint MMDeviceImageManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMDeviceImageManager'
  s.version          = '0.1.0'
  s.summary          = 'A manager helps to manage fetch image from device.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Support componant helps to isolate a set of generic tasks to keep your code more simpler and modular. This Helps in all your image needs from/using current running device'

  s.homepage         = 'https://github.com/MuthurajMuthulingam/MMDeviceImageManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Muthuraj Muthulingam' => 'muthurajmuthulingam@gmail.com' }
  s.source           = { :git => 'https://github.com/MuthurajMuthulingam/MMDeviceImageManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '18.0'
  s.swift_version = '4.0'

  s.source_files = 'MMDeviceImageManager/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MMDeviceImageManager' => ['MMDeviceImageManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
