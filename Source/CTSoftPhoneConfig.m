#import "CTSoftPhoneConfig.h"
#import "ct_pjsua/ct_pjsua.h"

@interface CTSoftPhoneConfig () {}

@property (nonatomic, assign, readwrite) int port;
@property (nonatomic, assign, readwrite) CTSoftPhoneTransportType transport;
@property (nonatomic, assign, readwrite) CTSoftPhoneSRTPStatus srtp;

@end

@implementation CTSoftPhoneConfig

- (instancetype _Nonnull)initWithPort:(int)port
                            transport:(CTSoftPhoneTransportType)transport {
    return [self initWithPort:port transport:transport srtp: CTSoftPhoneSRTPStatusOptional];
}

- (instancetype _Nonnull)initWithPort:(int)port
                            transport:(CTSoftPhoneTransportType)transport srtp:(CTSoftPhoneSRTPStatus)srtp {
    self = [self init];
    if (self) {
        self.port = port;
        self.transport = transport;
        self.srtp = srtp;
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

- (pjmedia_srtp_use)pjSRTPStatus {
    switch(self.srtp) {
        case CTSoftPhoneSRTPStatusOff:
            return PJMEDIA_SRTP_DISABLED;
        case CTSoftPhoneSRTPStatusOptional:
            return PJMEDIA_SRTP_OPTIONAL;
        case CTSoftPhoneSRTPStatusMandatory:
            return PJMEDIA_SRTP_MANDATORY;
    }
}

/**
 * Specify whether SRTP requires secure signaling to be used. This option
 * is only used when \a use_srtp option above is non-zero.
 *
 * Valid values are:
 *  0: SRTP does not require secure signaling
 *  1: SRTP requires secure transport such as TLS
 *  2: SRTP requires secure end-to-end transport (SIPS), not supported currently
 *
 * Default: #PJSUA_DEFAULT_SRTP_SECURE_SIGNALING
 */

- (int)useSecureSignaling {
    switch(self.transport) {
        case CTSoftPhoneTransportTypeTCP:
            return 0;
        case CTSoftPhoneTransportTypeUDP:
            return 0;
        case CTSoftPhoneTransportTypeTLS:
            return 1;
        case CTSoftPhoneTransportTypeTCPIPv6:
            return 0;
        case CTSoftPhoneTransportTypeUDPIPv6:
            return 0;
        case CTSoftPhoneTransportTypeTLSIPv6:
            return 1;
    }
}

- (BOOL)isIPv6 {
    return self.transport > CTSoftPhoneTransportTypeTLS;
}

@end
