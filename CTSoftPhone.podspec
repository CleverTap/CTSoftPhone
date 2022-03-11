Pod::Spec.new do |s|
s.name                      = "CTSoftPhone"
s.version                   = '0.0.2-alpha'
s.summary                   = "Basic PJSUA/PJSIP wrapper enabling iOS voip calling"
s.homepage                  = "https://github.com/CleverTap/CTSoftPhone"
s.source                    = { :http => "https://github.com/CleverTap/CTSoftPhone/releases/download/#{s.version}/CTSoftPhone.xcframework.zip" }
s.license                   = { :type => 'MIT', :file => 'License.txt' }
s.author                    = { "CleverTap" => "http://www.clevertap.com" }
s.module_name               = 'CTSoftPhone'

s.platform                  = :ios, '10.0'
s.ios.deployment_target     = '10.0'

s.pod_target_xcconfig       = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}
s.user_target_xcconfig      = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'}

s.ios.frameworks            = 'Foundation', 'UIKit', 'Security', 'CoreGraphics', 'CoreImage', 'CoreFoundation', 'AVFoundation', 'AudioToolbox', 'VideoToolbox'
s.vendored_frameworks       = 'CTSoftPhone.xcframework'

end
