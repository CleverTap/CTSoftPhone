# CTSoftPhone

Basic [PJSUA/PJSIP](https://www.pjsip.org/) wrapper supporting VOIP calling on iOS devices and simulators

## Usage

```
import CTSoftPhone

// set logging level
CTSoftPhone.setDebugLevel(CTSoftPhoneLogLevel.debug)
// CTSoftPhone.setDebugLevel(CTSoftPhoneLogLevel.info)
// CTSoftPhone.setDebugLevel(CTSoftPhoneLogLevel.off)

... 

// implement CTSoftPhoneDelegate
@objc func onRegistrationState(_ state: CTSoftPhoneRegistrationState) {...}
@objc func onCallState(_ state: CTSoftPhoneCallState) {...}

// init sharedInstance with your delegate
pjsipInstance = CTSoftPhone.sharedInstance(with: self) 

...

// register account
pjsipInstance.register(withNumber: <sip account number>, withHost: <sip host>, withCredentials: <sip account credentials>)
 
...
 
// unregister account 
pjsipInstance.destroy()

// end call 
pjsipInstance.hangup()
 
// mute/unmute
pjsipInstance.mute()
pjsipInstance.unmute()
 
// speaker
pjsipInstance.speakeron()
pjsipInstance.speakeroff()
 
```


## Install

### [Swift Package Manager](https://swift.org/package-manager/) 

Add the `https://github.com/CleverTap/CTSoftPhone.git` url to your project's Swift packages

### [CocoaPods](https://cocoapods.org)

```
 target 'YOUR_TARGET_NAME' do  
      pod 'CTSoftPhone'  
  end 
```

### Manual

Download the `CTSoftPhone.xcframework` included in this repository, drag it into your project and add it as an embedded framework in your build settings

