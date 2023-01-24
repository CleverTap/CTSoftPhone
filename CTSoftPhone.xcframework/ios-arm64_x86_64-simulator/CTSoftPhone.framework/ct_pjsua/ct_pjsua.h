#ifndef CallCFunction_h
#define CallCFunction_h
#define THIS_FILE "APP"
#define KEEP_ALIVE_INTERVAL 600
// NOTE: Must be placed *before* any pjsip stuff.
#ifndef PJ_IS_LITTLE_ENDIAN
#define PJ_IS_LITTLE_ENDIAN 1
#endif
#ifndef PJ_IS_BIG_ENDIAN
#define PJ_IS_BIG_ENDIAN 0
#endif
#ifndef PPJ_AUTOCONF
#define PJ_AUTOCONF 1
#endif
// Workaround buggy PJSIP arch detection logic when building for the phone. Simulator builds seems
// to be okay.
#ifndef PJ_HAS_PENTIUM
#  ifdef TARGET_IPHONE_SIMULATOR
#    define PJ_M_X86_64
#  else
#    define PJ_M_ARMV4 1
#  endif
#endif
#define current_acc    pjsua_acc_get_default()
#define PJ_THREAD_DESC_SIZE      (64)
#include "include/pjsua-lib/pjsua.h"
#endif /*CallCFunction_h*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
