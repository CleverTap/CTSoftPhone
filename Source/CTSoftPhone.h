#import <AVFoundation/AVFoundation.h>
#import <CTSoftPhone/CTSoftPhoneConfig.h>

typedef NS_ENUM(int, CTSoftPhoneLogLevel) {
    CTSoftPhoneLogOff = 0,
    CTSoftPhoneLogInfo = 1,
    CTSoftPhoneLogDebug = 2,
};

typedef NS_ENUM(int, CTSoftPhoneRegistrationState) {
    CTSoftPhoneRegistrationStateSuccess = 0,
    CTSoftPhoneRegistrationStateFail = 1,
    CTSoftPhoneRegistrationStateDestroyed = 2
};

typedef NS_ENUM(int, CTSoftPhoneCallState) {
    CTSoftPhoneCallStateNull = 0,
    CTSoftPhoneCallStateCalling = 1,
    CTSoftPhoneCallStateIncoming = 2,
    CTSoftPhoneCallStateEarly = 3,
    CTSoftPhoneCallStateConnecting = 4,
    CTSoftPhoneCallStateConfired = 5,
    CTSoftPhoneCallStateMediaNone = 6,
    CTSoftPhoneCallStateMediaActive = 7,
    CTSoftPhoneCallStateMediaLocalHold = 8,
    CTSoftPhoneCallStateMediaRemoteHold = 9,
    CTSoftPhoneCallStateMediaError = 10,
};

@protocol CTSoftPhoneDelegate <NSObject>
@required
- (void)onRegistrationState:(CTSoftPhoneRegistrationState)state;
- (void)onCallState:(CTSoftPhoneCallState)state;
@end

@interface CTSoftPhone: NSObject

+ (void)setDebugLevel:(CTSoftPhoneLogLevel)level;
+ (instancetype _Nonnull)sharedInstanceWithDelegate:(id<CTSoftPhoneDelegate> _Nonnull)delegate
                                             config:(CTSoftPhoneConfig *_Nonnull)config;
+ (instancetype _Nullable)sharedInstance;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

- (void)registerWithAccountCuid:(NSString *_Nonnull)accountCuid
                   withHost:(NSString*_Nonnull)host
            withCredentials:(NSString *_Nonnull)credentials;
- (void)handleIpChange:(CTSoftPhoneTransportType)transport;
- (void)destroy;
- (void)hangup;
- (void)mute;
- (void)unmute;
- (void)speakeron;
- (void)speakeroff;

@end

