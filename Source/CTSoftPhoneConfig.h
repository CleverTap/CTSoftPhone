#import <Foundation/Foundation.h>

typedef NS_ENUM(int, CTSoftPhoneTransportType) {
    CTSoftPhoneTransportTypeTCP = 0,
    CTSoftPhoneTransportTypeUDP = 1,
    CTSoftPhoneTransportTypeTLS = 2,
    CTSoftPhoneTransportTypeTCPIPv6 = 3,
    CTSoftPhoneTransportTypeUDPIPv6 = 4,
    CTSoftPhoneTransportTypeTLSIPv6 = 5
};

typedef NS_ENUM(int, CTSoftPhoneSRTPStatus) {
    CTSoftPhoneSRTPStatusOff = 0,
    CTSoftPhoneSRTPStatusOptional = 1,
    CTSoftPhoneSRTPStatusMandatory = 2
};

@interface CTSoftPhoneConfig : NSObject

@property (nonatomic, assign, readonly) int port;
@property (nonatomic, assign, readonly) CTSoftPhoneTransportType transport;
@property (nonatomic, assign, readonly) CTSoftPhoneSRTPStatus srtp;

- (instancetype _Nonnull) init __unavailable;

- (instancetype _Nonnull)initWithPort:(int)port
                            transport:(CTSoftPhoneTransportType)transport;
- (instancetype _Nonnull)initWithPort:(int)port
                            transport:(CTSoftPhoneTransportType)transport srtp:(CTSoftPhoneSRTPStatus)srtp;

@end
