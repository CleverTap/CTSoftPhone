#define PJ_CONFIG_IPHONE 1
#undef PJ_IPHONE_OS_HAS_MULTITASKING_SUPPORT
#define PJ_IPHONE_OS_HAS_MULTITASKING_SUPPORT 0
#define PJMEDIA_VIDEO_DEV_HAS_OPENGL 1
#define PJMEDIA_VIDEO_DEV_HAS_OPENGL_ES 1
#define PJMEDIA_VIDEO_DEV_HAS_IOS_OPENGL 1
#include <OpenGLES/ES3/glext.h>
#define PJMEDIA_HAS_VIDEO 1
#define PJMEDIA_HAS_VID_TOOLBOX_CODEC 1
#define PJ_HAS_IPV6 1
#define PJ_HAS_SSL_SOCK 1
#define PJSIP_HAS_TLS_TRANSPORT 1
#define PJMEDIA_HAS_SRTP 1
#define PJMEDIA_SRTP_HAS_DTLS 1
