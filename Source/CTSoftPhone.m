#import "CTSoftPhone.h"
#import "ct_pjsua/ct_pjsua.h"
#import <os/log.h>

#define CTSoftPhone_Log(level, ...)    do { \
                    if (level <= logLevel) { \
                        os_log_with_type(CTSoftPhoneLog, OS_LOG_TYPE_DEBUG, ##__VA_ARGS__); \
                    } \
                } while (0)

@interface CTSoftPhone () {
    pj_status_t status;
    AVAudioPlayer* audioPlayer;
    char * UsercallID;
    NSString * UserID;
    int count;
}

@property(nonatomic,assign) pjsua_call_id call_id;

@end

@implementation CTSoftPhone : NSObject

#define BIGVAL 0x7FFFFFFFL
pj_status_t status;
static pjsua_acc_id acc_id;
pjsua_call_id callId;
pjsua_call_info ci;
int logLevel = CTSoftPhoneLogOff;
os_log_t CTSoftPhoneLog;
static id _delegate = nil;

+ (void)setDelegate:(id<CTSoftPhoneDelegate>)delegate {
    if (delegate != _delegate) {
        _delegate = delegate;
    }
}

+ (id<CTSoftPhoneDelegate>)delegate {
    return _delegate;
}

+ (void)initialize {
    CTSoftPhoneLog = os_log_create("com.clevertap.CTSoftPhone", "CTSoftPhone");
}

+ (void)setDebugLevel:(CTSoftPhoneLogLevel)level {
    logLevel = level;
}

/**
 registers the user to sip server

 @param number  phone of the user
 @param host host to which user is to be connected
 @return return a enum value on successfull registration.
 */
- (CTSoftPhoneStatus) startWithNumber:(NSString *)number
                      withHost:(NSString*)host
               withCredentials:(NSString *)credentials {
    @try {
        NSString *num = number;
        NSString *_host = host;
       
        if (logLevel == CTSoftPhoneLogDebug) {
            pj_log_set_level(1);
        } else {
            pj_log_set_level(0);
        }
        
        status = pjsua_create();
        if (status != PJ_SUCCESS) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "failed creating pjsua");
            error_exit("error in pjsua_create()", status);
            return CTSoftPhoneStatusFail;
        }
        /* Init pjsua */
        pjsua_config cfg_log;
        pjsua_logging_config log_cfg;
        pjsua_config_default(&cfg_log);
        cfg_log.cb.on_incoming_call = &on_incoming_call;
        cfg_log.cb.on_call_media_state = &on_call_media_state;
        cfg_log.cb.on_call_state = &on_call_state;
        
        pjsua_logging_config_default(&log_cfg);
        if (logLevel == CTSoftPhoneLogDebug) {
            log_cfg.console_level = 4;
        } else {
            log_cfg.console_level = 0;
        }
        
        status = pjsua_init(&cfg_log, &log_cfg, NULL);
        if (status != PJ_SUCCESS) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "failed initializing pjsua");
            error_exit("Error in pjsua_init()", status);
            return CTSoftPhoneStatusFail;
        }
        
        pjsua_transport_config tcfg;
        pjsua_transport_config_default(&tcfg);
        tcfg.port = 7503;
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &tcfg, NULL);
        status = pjsua_start();
        if (status != PJ_SUCCESS) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "failed starting pjsua");
            error_exit("Error starting pjsua", status);
            return CTSoftPhoneStatusFail;
        }
        
        /* Register to SIP server by creating SIP account. */
        NSString *string1 = @"sip:";
        NSString *string2 = @"@";
        NSString *string3 = @":7503;transport=tcp";
        NSString *string4 = @";transport=tcp";
        NSString *uri = [string1 stringByAppendingString:num];
        NSString *reg = [string2 stringByAppendingString:_host];
        NSString *newUri = [uri stringByAppendingString:reg];
        NSString *proxy = [string1 stringByAppendingString:_host];
        NSString *reg_uri = [proxy stringByAppendingString:string4];
        proxy = [proxy stringByAppendingString:string3];
        const char *r = [reg_uri UTF8String];
        const char *p = [proxy UTF8String];
        const char *number = [num UTF8String];
        const char *pjsipPassword = [credentials UTF8String];
        pjsua_acc_config cfg;
        pjsua_acc_config_default(&cfg);
        NSArray *namesArray = [newUri componentsSeparatedByString:@"@"];
        NSString *newChar;
        if (namesArray.count > 0) {
            newChar = [namesArray[0] stringByAppendingString: @"@"];
            newChar = [newChar stringByAppendingString: namesArray[1]];
            
        }
        cfg.id = pj_str((char*)[newChar UTF8String]);
        cfg.reg_uri = pj_str((char*)r);
        cfg.proxy[cfg.proxy_cnt++] = pj_str((char*)p);
        cfg.cred_count = 1;
        cfg.cred_info[0].realm = pj_str("*");
        cfg.cred_info[0].scheme = pj_str("digest");
        cfg.cred_info[0].username = pj_str((char*)number);
        cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
        cfg.cred_info[0].data = pj_str((char*)pjsipPassword);
        
        status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        if (status == PJ_SUCCESS) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "sip server connection success");
            return CTSoftPhoneStatusSuccess;
        } else {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "failed connecting to sip server account");
            error_exit("error connecting pjsua account", status);
            return CTSoftPhoneStatusFail;
        }
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogInfo, "error: %@", exception.reason);
        return CTSoftPhoneStatusFail;
    }
}


static void error_exit(const char *title, pj_status_t status) {
    @try {
        pjsua_perror("CTSoftPhone", title, status);
        pjsua_destroy();
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "error_exit error: %@", exception);
    }
}


/**
 when the call state is changed
 
 @param call_id call_id of the call given by pjsua.
 @param e event of the call.
 */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    @try {
        PJ_UNUSED_ARG(e);
        pjsua_call_get_info(call_id, &ci);
        PJ_LOG(1,("CTSoftPhone", "Call %d state=%.*s", call_id,
                  (int)ci.state_text.slen,
                  ci.state_text.ptr));
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "on_call_state: %@", exception);
    }
}


/**
 when the call media state is changed.
 
 @param call_id call_id of the given call by pjsua.
 */
static void on_call_media_state(pjsua_call_id call_id) {
    @try {
        pjsua_call_get_info(call_id, &ci);
        if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
            // When media is active, connect call to sound device.
            pjsua_conf_connect(ci.conf_slot, 0);
            pjsua_conf_connect(0, ci.conf_slot);
            [_delegate mediaTransferActive];
        }
        if (ci.media_status == PJSUA_CALL_MEDIA_NONE) {
            pjsua_conf_disconnect(ci.conf_slot, 0);
        }
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "on_call_media_state: %@", exception);
    }
}

/**
 called when a incoming call is received from the asterisk
 
 @param acc_id account_id of the user given by pjsip
 @param call_id call_id of the user given by the pjsip
 @param rdata rx_data of pjsip
 */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata) {
    @try {
        PJ_UNUSED_ARG(acc_id);
        PJ_UNUSED_ARG(rdata);
        PJ_LOG(1,("CTSoftPhone", "Incoming call from %.*s!!",
                  (int)ci.remote_info.slen,
                  ci.remote_info.ptr));
        setCallid(call_id) ;
        pjsua_call_answer(call_id, 200, NULL, NULL);
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "on_incoming_call: %@", exception);
    }
}


/**
 returns the call_id of pjsip
 @return object of call_id
 */
pjsua_call_id getCallid(void) {
    return callId;
}

/**
 set the callid of pjsip
 @param callid call_id given by pjsip
 */
void setCallid(pjsua_call_id callid) {
    callId = callid;
}

void answercall () {
    @try {
        pjsua_call_id call_id  = getCallid();
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "call id in answer: %d", call_id);
        pjsua_call_answer(call_id, 200, NULL, NULL);
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "answercall: %@", exception);
    }
}


/**
 called when the user is trying to disconnect the call to hangup the current call by pjsip
 */
- (void)hangup {
    @try {
        pjsua_call_id call_id = getCallid();
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "call id in hangup: %d", call_id);
        pjsua_call_hangup(call_id, 200, NULL, NULL);
        CTSoftPhone_Log(CTSoftPhoneLogInfo, "call hangup success");
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "hangup: %@", exception);
    }
}

/**
 called when user is trying to start the speaker.
 */
- (void)speakeron {
    BOOL success;
    @try {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                 error:&error];
        if (!success) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "AVAudioSession error setCategory: %@", [error localizedDescription]);
        }
        
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        if (!success) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "AVAudioSession error overrideOutputAudioPort: %@", [error localizedDescription]);
        }
        
        success = [session setActive:YES error:&error];
        if (!success) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "AVAudioSession error setActive: %@", [error localizedDescription]);
        }
        
        if (success) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "call speakeron success");
        }
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "speakeron: %@", exception);
    }
}


/**
 called when user is trying to stop the speaker.
 */
- (void)speakeroff {
    BOOL success;
    @try {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                 error:&error];
        if (!success) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "AVAudioSession error setCategory: %@", [error localizedDescription]);
        }
        
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        if (!success) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "AVAudioSession error overrideOutputAudioPort: %@", [error localizedDescription]);
        }
        
        success = [session setActive:YES error:&error];
        if (!success) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "AVAudioSession error setActive: %@", [error localizedDescription]);
        }
        
        if (success) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "call speakeroff success");
        }
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "speakeroff: %@", exception);
    }
}

/**
 called when user is trying to unmute the call.
 */
- (void)unmute {
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ci.conf_slot != 0 && ci.conf_slot != -1 ) {
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "microphone disconnected from call");
                pjsua_conf_connect(0,ci.conf_slot);
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "call unmute success");
            }
        });
        
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "unmute: %@", exception);
    }
}

/**
 called when user is trying to mute the call.
 */
- (void)mute {
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "call mute status: %d", ci.conf_slot);
            if (ci.conf_slot != 0 && ci.conf_slot != -1) {
                CTSoftPhone_Log(CTSoftPhoneLogDebug, "microphone disconnected from call");
                pjsua_conf_disconnect(0, ci.conf_slot);
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "call mute success");
            }
        });
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "unable to mute microphone: %@", exception);
    }
}

/**
 called when user is trying to stop all the call.
 */
- (void)stop {
    @try {
        pjsua_call_hangup_all();
        pjsua_destroy();
        CTSoftPhone_Log(CTSoftPhoneLogInfo, "call stop success");
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "unable to handle call stop: %@", exception);
    }
}

@end
