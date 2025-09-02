#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint app_security_lock.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'app_security_lock'
  s.version          = '0.0.1'
  s.summary          = 'A comprehensive Flutter plugin for app security features including screen lock detection, background timeout, and lifecycle monitoring.'
  s.description      = <<-DESC
A comprehensive Flutter plugin for app security features including screen lock detection, background timeout, and lifecycle monitoring.
                       DESC
  s.homepage         = 'http://bxmao.net'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'zxj417870308@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'app_security_lock_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
