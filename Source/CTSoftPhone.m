#import "CTSoftPhone.h"
#import "ct_pjsua/ct_pjsua.h"
#import <os/log.h>
#import "CTSoftPhoneConfig.h"

#define CTSoftPhone_Log(level, ...)    do { \
                    if (level <= logLevel) { \
                        os_log_with_type(CTSoftPhoneLog, OS_LOG_TYPE_DEBUG, ##__VA_ARGS__); \
                    } \
                } while (0)

@interface CTSoftPhoneConfig (Private) {}

@property (nonatomic, assign, readwrite) CTSoftPhoneTransportType transport;

- (NSString *_Nonnull)transportDescription;
- (pjsip_transport_type_e)pjTransportType;
- (BOOL)isIPv6;

@end

@interface CTSoftPhone () {
    dispatch_queue_t _serialQueue;
}

@property (nonatomic, weak, readwrite) id<CTSoftPhoneDelegate> _Nullable delegate;
@property (atomic, strong, readwrite) CTSoftPhoneConfig *_Nonnull config;

@property(atomic,assign) pjsua_call_id call_id;
@property(atomic,assign) bool pjsuaInitialized;

@end

@implementation CTSoftPhone : NSObject

#define BIGVAL 0x7FFFFFFFL
pj_status_t status;
static pjsua_acc_id acc_id = -1;
static _Atomic pjsua_call_id callId;
pjsua_call_info ci;
pj_pool_t *pool;
int logLevel = CTSoftPhoneLogOff;
os_log_t CTSoftPhoneLog;
static CTSoftPhone * _sharedInstance;
static const void *const kQueueKey = &kQueueKey;

+ (void)initialize {
    CTSoftPhoneLog = os_log_create("com.clevertap.CTSoftPhone", "CTSoftPhone");
}

+ (void)setDebugLevel:(CTSoftPhoneLogLevel)level {
    logLevel = level;
}

+ (void)setSharedInstance:(CTSoftPhone * _Nullable)sharedInstance {
    @synchronized ([self class]) {
        _sharedInstance = sharedInstance;
    }
}

+ (instancetype _Nullable)sharedInstance {
    @synchronized ([self class]) {
        return _sharedInstance;
    }
}

+ (instancetype _Nonnull)sharedInstanceWithDelegate:(id<CTSoftPhoneDelegate> _Nonnull)delegate
                                             config:(CTSoftPhoneConfig *_Nonnull)config; {
    CTSoftPhone *instance = [self sharedInstance];
    if (instance == nil) {
        instance = [[CTSoftPhone alloc] initWithDelegate:delegate config:config];
        [self setSharedInstance:instance];
    }
    return instance;
    
}

+ (void)onRegistrationState:(CTSoftPhoneRegistrationState)state {
    [[self sharedInstance] onRegistrationState:state];
}

+ (void)onCallState:(CTSoftPhoneCallState)state {
    [[self sharedInstance] onCallState:state];
}

- (instancetype _Nonnull)initWithDelegate:(id<CTSoftPhoneDelegate> _Nonnull)delegate config:(CTSoftPhoneConfig *_Nonnull)config {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.config = config;
        _serialQueue = dispatch_queue_create([@"com.clevertap.CTSoftPhone" UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_serialQueue, kQueueKey, (__bridge void *)self, NULL);
    }
    return self;
}


- (void)registerThread {
    pj_status_t status;
    pj_thread_desc aPJThreadDesc;
    if (!pj_thread_is_registered()) {
        pj_thread_t *pjThread;
        status = pj_thread_register(NULL, aPJThreadDesc, &pjThread);
        if (status != PJ_SUCCESS) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "Error registering thread at PJSUA");
        }
    }
}

#pragma mark - Serial Queue Operations

- (void)runAsync:(void (^)(void))taskBlock {
    if ([self inSerialQueue]) {
        taskBlock();
    } else {
        dispatch_async(_serialQueue, taskBlock);
    }
}

- (BOOL)inSerialQueue {
    CTSoftPhone *currentQueue = (__bridge id) dispatch_get_specific(kQueueKey);
    return currentQueue == self;
}

/**
 registers the user to sip server

 @param number number phone of the user
 @param host host to which user is to be connected
 @param credentials credentials required to establish the connection
 */
- (void)registerWithNumber:(NSString *)number
                      withHost:(NSString*)host
           withCredentials:(NSString *)credentials {
    CTSoftPhone_Log(CTSoftPhoneLogInfo, "register called");
    [self runAsync: ^{
        @try {
            [self registerThread];
            NSString *num = number;
            NSString *_host = host;
            if (!self.pjsuaInitialized) {
               self.pjsuaInitialized = true;
                
                if (logLevel == CTSoftPhoneLogDebug) {
                    pj_log_set_level(1);
                } else {
                    pj_log_set_level(0);
                }
                
                status = pjsua_create();
                if (status != PJ_SUCCESS) {
                    CTSoftPhone_Log(CTSoftPhoneLogInfo, "failed creating pjsua");
                    error_exit("error in pjsua_create()", status);
                    [self.delegate onRegistrationState: CTSoftPhoneRegistrationStateFail];
                    return;
                }
                /* Init pjsua */
                pjsua_config cfg_log;
                pjsua_logging_config log_cfg;
                pjsua_config_default(&cfg_log);
                cfg_log.cb.on_incoming_call = &on_incoming_call;
                cfg_log.cb.on_call_media_state = &on_call_media_state;
                cfg_log.cb.on_call_state = &on_call_state;
                cfg_log.cb.on_reg_state2 = &on_reg_state2;
                
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
                    [self.delegate onRegistrationState: CTSoftPhoneRegistrationStateFail];
                    return;
                }
                
                pjsua_transport_config tcfg;
                pjsua_transport_config_default(&tcfg);
                tcfg.port = self.config.port;
                status = pjsua_transport_create([self.config pjTransportType], &tcfg, NULL);
                status = pjsua_start();
                if (status != PJ_SUCCESS) {
                    CTSoftPhone_Log(CTSoftPhoneLogInfo, "failed starting pjsua");
                    error_exit("Error starting pjsua", status);
                    [self.delegate onRegistrationState: CTSoftPhoneRegistrationStateFail];
                    return;
                }
            }
            NSString *transport = [self.config transportDescription];
            NSString *string1 = @"sip:";
            NSString *string2 = @"@";
            NSString *string3 = [NSString stringWithFormat:@":%i;transport=%@", self.config.port, transport];
            NSString *string4 = [NSString stringWithFormat:@";transport=%@", transport];
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
            if (acc_id >= 0) {
                status = pjsua_acc_modify(acc_id, &cfg);
            } else {
                status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
            }
            
            if (status == PJ_SUCCESS) {
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "sip account add success");
                return;
            } else {
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "failed adding sip server account");
                error_exit("error adding pjsua account", status);
                [self.delegate onRegistrationState: CTSoftPhoneRegistrationStateFail];
                return;
            }
        }
         @catch (NSException *exception) {
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "error: %@", exception.reason);
            [self.delegate onRegistrationState: CTSoftPhoneRegistrationStateFail];
            return;
        }
    }];
}

- (void)handleIpChange:(CTSoftPhoneTransportType)transport {
    [self runAsync: ^{
        @try {
            [self registerThread];
            if (callId < 0 || acc_id < 0) {
                return;
            }
            pjsua_ip_change_param param;
            
            if(self.config.transport != transport) {
                //create new transport, if it's not yet available
                pjsua_transport_config tcfg;
                pjsua_transport_config_default(&tcfg);
                tcfg.port = self.config.port;
                pjsua_transport_id transportId;
                self.config.transport = transport;
                status = pjsua_transport_create([self.config pjTransportType], &tcfg, &transportId);
                pjsua_acc_set_transport(acc_id, transportId);
                // modify specific account configuration
                pjsua_acc_config acc_cfg;
                pj_pool_t pool;
                pjsua_acc_get_config(acc_id, &pool, &acc_cfg);
                acc_cfg.ipv6_media_use = true;
                acc_cfg.ip_change_cfg.hangup_calls = PJ_TRUE;
                pjsua_acc_modify(acc_id, &acc_cfg);
            }
            pjsua_ip_change_param_default(&param);
            pjsua_handle_ip_change(&param);
            
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "handleIPChange running");
        }
        @catch (NSException *exception) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "unable to handle ip change: %@", exception);
        }
    }];
}

/**
 called by user to shutdown the service.
 */

- (void)destroy {
    [self runAsync: ^{
        @try {
            [self registerThread];
            ct_pjsua_destroy();
            self.pjsuaInitialized = false;
            [[CTSoftPhone class] onRegistrationState: CTSoftPhoneRegistrationStateDestroyed];
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "destroy success");
        }
        @catch (NSException *exception) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "unable to handle destroy: %@", exception);
        }
    }];
}

- (void)answercall {
    [self runAsync: ^{
        @try {
            [self registerThread];
            pjsua_call_id call_id  = getCallid();
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "call id in answer: %d", call_id);
            pjsua_call_answer(call_id, 200, NULL, NULL);
        }
        @catch (NSException *exception) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "answercall: %@", exception);
        }
    }];
}

/**
 called when the user is trying to disconnect the call to hangup the current call by pjsip
 */
- (void)hangup {
    [self runAsync: ^{
        @try {
            [self registerThread];
            pjsua_call_id call_id = getCallid();
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "call id in hangup: %d", call_id);
            pjsua_call_hangup(call_id, 200, NULL, NULL);
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "call hangup success");
        }
        @catch (NSException *exception) {
            CTSoftPhone_Log(CTSoftPhoneLogDebug, "hangup: %@", exception);
        }
    }];
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
        [self runAsync: ^{
            [self registerThread];
            if (ci.conf_slot != 0 && ci.conf_slot != -1 ) {
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "microphone disconnected from call");
                pjsua_conf_connect(0,ci.conf_slot);
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "call unmute success");
            }
        }];
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
       [self runAsync: ^{
           [self registerThread];
            CTSoftPhone_Log(CTSoftPhoneLogInfo, "call mute status: %d", ci.conf_slot);
            if (ci.conf_slot != 0 && ci.conf_slot != -1) {
                CTSoftPhone_Log(CTSoftPhoneLogDebug, "microphone disconnected from call");
                pjsua_conf_disconnect(0, ci.conf_slot);
                CTSoftPhone_Log(CTSoftPhoneLogInfo, "call mute success");
            }
        }];
    }
    @catch (NSException *exception) {
        CTSoftPhone_Log(CTSoftPhoneLogDebug, "unable to mute microphone: %@", exception);
    }
}

- (void)onRegistrationState:(CTSoftPhoneRegistrationState)state {
    [self.delegate onRegistrationState:state];
}

- (void)onCallState:(CTSoftPhoneCallState)state {
    [self.delegate onCallState:state];
}

static void error_exit(const char *title, pj_status_t status) {
    @try {
        pjsua_perror("CTSoftPhone", title, status);
        ct_pjsua_destroy();
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
        [[CTSoftPhone class] onCallState: ci.state];
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
            [[CTSoftPhone class] onCallState: CTSoftPhoneCallStateMediaActive];
        }
        else if (ci.media_status == PJSUA_CALL_MEDIA_NONE) {
            pjsua_conf_disconnect(ci.conf_slot, 0);
            [[CTSoftPhone class] onCallState: CTSoftPhoneCallStateMediaNone];
        }
        else if (ci.media_status == PJSUA_CALL_MEDIA_LOCAL_HOLD) {
            [[CTSoftPhone class] onCallState: CTSoftPhoneCallStateMediaLocalHold];
        }
        else if (ci.media_status == PJSUA_CALL_MEDIA_REMOTE_HOLD) {
            [[CTSoftPhone class] onCallState: CTSoftPhoneCallStateMediaRemoteHold];
        }
        else if (ci.media_status == PJSUA_CALL_MEDIA_ERROR) {
            [[CTSoftPhone class] onCallState: CTSoftPhoneCallStateMediaError];
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

void ct_pjsua_destroy(void) {
    ct_pjsua_deleteAccount();
    pjsua_destroy();
}

void ct_pjsua_deleteAccount(void) {
    if (acc_id < 0) {
        return;
    }
    pjsua_call_hangup_all();
    pjsua_acc_del(acc_id);
    acc_id = -1;
}

void on_reg_state2(pjsua_acc_id new_acc_id, pjsua_reg_info *info) {
    struct pjsip_regc_cbparam *rp = info->cbparam;
    if (rp->status == PJ_SUCCESS && rp->code/100 == 2 && rp->expiration > 0 && rp->contact_cnt > 0) {
        [[CTSoftPhone class] onRegistrationState: CTSoftPhoneRegistrationStateSuccess];
    } else {
        [[CTSoftPhone class] onRegistrationState: CTSoftPhoneRegistrationStateFail];
    }
}
 
@end
