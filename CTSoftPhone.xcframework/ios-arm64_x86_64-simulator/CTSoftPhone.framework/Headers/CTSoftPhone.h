#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(int, CTSoftPhoneLogLevel) {
    CTSoftPhoneLogOff = 0,
    CTSoftPhoneLogInfo = 1,
    CTSoftPhoneLogDebug = 2,
};

typedef NS_ENUM(int, CTSoftPhoneStatus) {
    CTSoftPhoneStatusSuccess = 0,
    CTSoftPhoneStatusFail = 1
};

@interface CTSoftPhone: NSObject

+ (void)setDebugLevel:(CTSoftPhoneLogLevel)level;

- (CTSoftPhoneStatus)startWithNumber:(NSString *)number
                            withHost:(NSString*)host
                     withCredentials:(NSString *)credentials;
- (void)stop;
- (void)hangup;
- (void)mute;
- (void)unmute;
- (void)speakeron;
- (void)speakeroff;

void answercall(void);

@end

