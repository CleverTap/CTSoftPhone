# CTSoftPhone

Basic [PJSUA/PJSIP](https://www.pjsip.org/) wrapper supporting VOIP calling on iOS devices and simulators

## Usage

```
import CTSoftPhone

... 

static var pjsipClient: CTSoftPhone = CTSoftPhone() // init

...

// set logging level
CTSoftPhone.setDebugLevel(CTSoftPhoneLogLevel.debug)
// CTSoftPhone.setDebugLevel(CTSoftPhoneLogLevel.info)
// CTSoftPhone.setDebugLevel(CTSoftPhoneLogLevel.off)

let status = pjsipClient.start(withNumber: num, withHost: host, withCredentials: credentials)
if (status == CTSoftPhoneStatus.success) {
    // connected 
 } else {
    // handle not connected
 }
 
 ...
 
 // terminate connection 
 pjsipClient.stop()
 
 // mute/unmute
 pjsipClient.mute()
 pjsipInstance.unmute()
 
 // speaker
 pjsipClient.speakeron()
 pjsipClient.speakeroff()
 
```


## Install

### [Swift Package Manager](https://swift.org/package-manager/) 

Add the `https://github.com/CleverTap/CTSoftPhone.git` url to your project's Swift packages

### [CocoaPods](https://cocoapods.org)

```
 target 'YOUR_TARGET_NAME' do  
      pod 'CTSimplePhone'  
  end 
```

### Manual

Download the `CTSoftPhone.xcframework` included in this repository, drag it into your project and add it as an embedded framework in your build settings

