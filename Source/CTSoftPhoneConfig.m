#import "CTSoftPhoneConfig.h"
#import "ct_pjsua/ct_pjsua.h"

@interface CTSoftPhoneConfig () {}

@property (nonatomic, assign, readwrite) int port;
@property (nonatomic, assign, readwrite) CTSoftPhoneTransportType transport;

@end

@implementation CTSoftPhoneConfig

- (instancetype _Nonnull)initWithPort:(int)port
                            transport:(CTSoftPhoneTransportType)transport {
    self = [self init];
    if (self) {
        self.port = port;
        self.transport = transport;
    }
    return self;
}

- (NSString *_Nonnull)transportDescription {
    switch(self.transport) {
        case CTSoftPhoneTransportTypeTCP:
            return @"tcp";
        case CTSoftPhoneTransportTypeUDP:
            return @"udp";
        case CTSoftPhoneTransportTypeTLS:
            return @"tls";
        case CTSoftPhoneTransportTypeTCPIPv6:
            return @"tcp";
        case CTSoftPhoneTransportTypeUDPIPv6:
            return @"udp";
        case CTSoftPhoneTransportTypeTLSIPv6:
            return @"tls";
    }
}

- (pjsip_transport_type_e)pjTransportType {
    switch(self.transport) {
        case CTSoftPhoneTransportTypeTCP:
            return PJSIP_TRANSPORT_TCP;
        case CTSoftPhoneTransportTypeUDP:
            return PJSIP_TRANSPORT_UDP;
        case CTSoftPhoneTransportTypeTLS:
            return PJSIP_TRANSPORT_TLS;
        case CTSoftPhoneTransportTypeTCPIPv6:
            return PJSIP_TRANSPORT_TCP6;
        case CTSoftPhoneTransportTypeUDPIPv6:
            return PJSIP_TRANSPORT_UDP6;
        case CTSoftPhoneTransportTypeTLSIPv6:
            return PJSIP_TRANSPORT_TLS6;
    }
}

- (BOOL)isIPv6 {
    return self.transport > CTSoftPhoneTransportTypeTLS;
}

@end
