Pod::Spec.new do |s|
s.name = 'XCFSodium'
s.version = '0.8.0'
s.swift_version = '5.0'
s.license = { :type => "ISC", :file => 'LICENSE' }
s.summary = 'Swift-Sodium provides a safe and easy to use interface to perform common cryptographic operations on iOS and OSX.'
s.homepage = 'https://github.com/jedisct1/swift-sodium'
s.social_media_url = 'https://twitter.com/jedisct1'
s.authors = { 'Frank Denis' => '' }
s.source = { :git => 'https://github.com/0xacdc/Sodium-xcframework.git'}

s.ios.deployment_target = '8.0'
s.osx.deployment_target = '10.11'

#s.prepare_command = 'sh build.sh'
s.vendored_framework = 'LibSodium.xcframework' 
s.xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
s.static_framework = true

s.requires_arc = true
end
