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

// create config with port and transport type
let pjsipConfig = CTSoftPhoneConfig.init(port: 7503, transport: .TCP)

// init sharedInstance with your delegate and config
pjsipInstance = CTSoftPhone.sharedInstance(with: self, config: pjsipConfig)

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

### Caveats
Usage with transports other than TCP has not been tested.
Asterisk v18.9.0 is the only SIP server this has been tested with so far.
This is a basic wrapper around pjsua and does not implement all functionality.  
The current version requires an external trigger to your SIP server to generate an invite once the client is registered with the SIP server.
There is no general plan to implement all available functionality although happyt to consider PRs.
