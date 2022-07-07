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
static pjsip_transport *the_transport;
pjsua_call_id callId;
pjsua_call_info ci;
pj_pool_t *pool;
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
               withCredentials:(NSString *)credentials
                           isReinvite: (BOOL) isReinvite {
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
        cfg_log.cb.on_reg_state2 = &on_reg_state2;
        cfg_log.cb.on_reg_started2 = &on_reg_started2;
        cfg_log.cb.on_transport_state = &on_transport_state;
        cfg_log.cb.on_ip_change_progress = &on_ip_change_progress;
//        on_reg_started2
//        on_reg_state2
//        on_transport_state
//        ip_change
        
        
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
        
        //check params meaning
        cfg.sip_stun_use = PJSUA_STUN_USE_DEFAULT;
        cfg.media_stun_use = PJSUA_STUN_USE_DEFAULT;
        cfg.allow_via_rewrite = PJ_TRUE;
        cfg.ip_change_cfg.shutdown_tp = PJ_TRUE;
        cfg.ip_change_cfg.hangup_calls = PJ_FALSE;
        cfg.ip_change_cfg.reinvite_flags = PJSUA_CALL_REINIT_MEDIA;
        cfg.contact_use_src_port = PJ_TRUE;
        NSLog(@"Acc_id:::::::: %d", acc_id);
        status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        NSLog(@"Acc_id::::::: %d", acc_id);
        
        
//        if (isReinvite) {
////            var call_info = pjsua_call_info();
////            guard pjsua_call_get_info(call_id, &call_info) == PJ_SUCCESS.rawValue else {return}
//                
//            pjsua_call_info;
//            pjsua_call_id call_id  = getCallid();
//            NSLog(@"CALLID %d", call_id);
//            pj_status_t status2 = pjsua_call_reinvite(call_id, PJ_TRUE, nil);
//
//            if (status2 != PJ_SUCCESS)
//                PJ_PERROR(1,(THIS_FILE, status2, "xxx: pjsua_acc_set_registration(0) error"));
//            else
//                PJ_LOG(3,(THIS_FILE, "xxx: Reregistration started.."));
//        }
        
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
        PJ_LOG(1,("CTSoftPhone", "Incoming call from"));
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
        PJ_LOG(1,(THIS_FILE, "xxx: on_incoming_call.."));
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

- (void)reRegistration:(NSString *)number1
              withHost:(NSString*)host
       withCredentials:(NSString *)credentials {
//    pj_pool_t *tmp_pool = pjsua_pool_create("tmp-pjsua", 1000, 1000);
//    pjsua_acc_config acc_cfg;
//    pjsua_acc_get_config(acc_id, tmp_pool, &acc_cfg);
//
//
////    pjsua_acc_get_config(acc_id, &app_config.acc_cfg[i]);
////    app_config.acc_cfg[i].reg_timeout = timeout;
////    pjsua_acc_modify(i, &app_config.acc_cfg[i]);
//
//
//    status = pjsua_acc_modify(0, &acc_cfg);
//    if (status == PJ_SUCCESS) {
//        CTSoftPhone_Log(CTSoftPhoneLogInfo, "reregister sip server connection success");
//    } else {
//        CTSoftPhone_Log(CTSoftPhoneLogInfo, "reregister failed connecting to sip server account");
//        error_exit("error connecting pjsua reregister account", status);
//    }
//
//    pj_pool_release(tmp_pool);
    
//    if (pjsua_acc_is_valid(acc_id)) {
//        pj_status_t status = pjsua_acc_set_registration(acc_id, PJ_TRUE);
//
//    }

//    if (status != PJ_SUCCESS)
//        PJ_PERROR(1,(THIS_FILE, status, "xxx: pjsua_acc_set_registration(0) error"));
//    else
//        PJ_LOG(3,(THIS_FILE, "xxx: Reregistration started.."));
    //check the IP address/port in the response, and re-REGISTER again and update the account URI as necessary.
//    pjsua_media_transport_c
//    pjsua_media_transports_create(); //to recreate the media transports.
//    To update the dialog's Contact URI, application can use the flag PJSUA_CALL_UPDATE_CONTACT when calling the API pjsua_call_reinvite()
    pjsua_call_id call_id  = getCallid();
    pj_status_t status2 = pjsua_call_reinvite(call_id, PJ_TRUE, nil);

    if (status2 != PJ_SUCCESS)
        PJ_PERROR(1,(THIS_FILE, status2, "xxx: pjsua_acc_set_registration(0) error"));
    else
        PJ_LOG(3,(THIS_FILE, "xxx: Reregistration started.."));
    
    
    
//    pjsua_call_reinvite(i, PJ_TRUE, NULL);
//                pjsua_call_get_info(i, &ci);
//                pjsua_conf_connect(pjsua_call_get_conf_port(ci.id), pjsua_call_get_conf_port(current_call));
//                pjsua_conf_connect(pjsua_call_get_conf_port(current_call), pjsua_call_get_conf_port(ci.id));
           
}


- (void)destroy {
    @try {
        pjsua_destroy();
        
        CTSoftPhone_Log(CTSoftPhoneLogInfo, "call stop success");
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "unable to handle call stop: %@", exception);
    }
}

//static void on_reg_state2(pjsua_acc_id new_acc_id, pjsua_reg_info *info) {
//    struct pjsip_regc_cbparam *rp = info->cbparam;
//
//    if (acc_id != new_acc_id)
//        return;
//
//    if (rp->code/100 == 2 && rp->expiration > 0 && rp->contact_cnt > 0) {
//        /* Registration success */
//        if (the_transport) {
//            PJ_LOG(3,(THIS_FILE, "xxx: Releasing transport.."));
//            pjsip_transport_dec_ref(the_transport);
//            the_transport = NULL;
//        }
//        /* Save transport instance so that we can close it later when
//         * new IP address is detected.
//         */
//        PJ_LOG(3,(THIS_FILE, "xxx: Saving transport.."));
//        the_transport = rp->rdata->tp_info.transport;
//        pjsip_transport_add_ref(the_transport);
//    } else {
//        if (the_transport) {
//            PJ_LOG(3,(THIS_FILE, "xxx: Releasing transport.."));
//            pjsip_transport_dec_ref(the_transport);
//            the_transport = NULL;
//        }
//    }
//}

static void on_reg_started2(pjsua_acc_id new_acc_id, pjsua_reg_info *info) {
    pjsip_regc_info regc_info;
    
    pjsip_regc_get_info(info->regc, &regc_info);
    
    if (acc_id != new_acc_id)
        return;
    
    if (the_transport != regc_info.transport) {
        if (the_transport) {
            PJ_LOG(3,(THIS_FILE, "xxx: Releasing transport.."));
            pjsip_transport_dec_ref(the_transport);
            the_transport = NULL;
        }
        /* Save transport instance so that we can close it later when
         * new IP address is detected.
         */
        PJ_LOG(3,(THIS_FILE, "xxx: Saving transport.."));
        the_transport = regc_info.transport;
        pjsip_transport_add_ref(the_transport);
    }
}

static void on_reg_state2(pjsua_acc_id new_acc_id, pjsua_reg_info *info) {
    struct pjsip_regc_cbparam *rp = info->cbparam;
    
    if (acc_id != new_acc_id)
        return;
    
    if (rp->code/100 == 2 && rp->expiration > 0 && rp->contact_cnt > 0) {
        /* We already saved the transport instance */
    } else {
        if (the_transport) {
            PJ_LOG(3,(THIS_FILE, "xxx: Releasing transport.."));
            pjsip_transport_dec_ref(the_transport);
            the_transport = NULL;
        }
    }
}

/* Also release the transport when it is disconnected (see ticket #1482) */
static void on_transport_state(pjsip_transport *tp,
                               pjsip_transport_state state,
                               const pjsip_transport_state_info *info) {
    if (state == PJSIP_TP_STATE_DISCONNECTED && the_transport == tp) {
        PJ_LOG(3,(THIS_FILE, "xxx: Releasing transport.."));
        pjsip_transport_dec_ref(the_transport);
        the_transport = NULL;
    }
}

static void on_ip_change_progress(pjsua_ip_change_op op, pj_status_t status, const pjsua_ip_change_op_info *info) {
    PJ_LOG(3,(THIS_FILE, "xxx: Enetered on_ip_change_progress"));
}
 
//void pjsua_handle_ip_change(const pjsua_ip_change_param *param) {
//
//}

//Check if this need to be called manually
static void ip_change() {
    pj_status_t status;

    PJ_LOG(3,(THIS_FILE, "xxx: IP change.."));

    if (the_transport) {
        status = pjsip_transport_shutdown(the_transport);
        if (status != PJ_SUCCESS)
            PJ_PERROR(1,(THIS_FILE, status, "xxx: pjsip_transport_shutdown() error"));
        pjsip_transport_dec_ref(the_transport);
        the_transport = NULL;
    }

    status = pjsua_acc_set_registration(acc_id, PJ_FALSE);
    if (status != PJ_SUCCESS)
        PJ_PERROR(1,(THIS_FILE, status, "xxx: pjsua_acc_set_registration(0) error"));
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
