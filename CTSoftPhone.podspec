Pod::Spec.new do |s|
s.name                      = "CTSoftPhone"
s.version                   = '0.0.6-alpha'
s.summary                   = "Basic PJSUA/PJSIP wrapper enabling iOS voip calling"
s.homepage                  = "https://github.com/CleverTap/CTSoftPhone"
s.source                    = { :http => "https://github.com/CleverTap/CTSoftPhone/releases/download/#{s.version}/CTSoftPhone.xcframework.zip" }
s.license                   = { :type => 'MIT', :text => 'Copyright (c) 2022 CleverTap The MIT License (MIT) Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall beincluded in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.' }
s.author                    = { "CleverTap" => "http://www.clevertap.com" }
s.module_name               = 'CTSoftPhone'

s.platform                  = :ios, '10.0'
s.ios.deployment_target     = '10.0'

s.ios.frameworks            = 'Foundation', 'UIKit', 'Security', 'CoreGraphics', 'CoreImage', 'CoreFoundation', 'AVFoundation', 'AudioToolbox', 'VideoToolbox'
s.vendored_frameworks       = 'CTSoftPhone.xcframework'

end
