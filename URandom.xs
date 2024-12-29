#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETRANDOM
#include <sys/random.h>
#else
#ifdef HAVE_CRYPT_URANDOM_SYSCALL_GETRANDOM
#include <sys/syscall.h>
#else
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETENTROPY
#include <sys/random.h>
#else
#ifdef HAVE_CRYPT_URANDOM_UNISTD_GETENTROPY
#include <unistd.h>
#endif
#endif
#endif
#endif
#ifdef GRND_NONBLOCK
#else
#define GRND_NONBLOCK	0x0001
#endif
#include <sys/types.h>
#include <errno.h>

MODULE = Crypt::URandom  PACKAGE = Crypt::URandom
PROTOTYPES: ENABLE

ssize_t
crypt_urandom_getrandom(buffer, length)
        SV *buffer
        size_t length
    PREINIT:
        char *data;
    CODE:
        if (length >= SSIZE_MAX) {
            errno = EFAULT;
            XSRETURN_UNDEF;
        }
        STRLEN curlen;
        SvPVbyte_force(buffer, curlen);
        (void)curlen;
        data = SvGROW(buffer, length + 1);
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETRANDOM
        RETVAL = getrandom(data, length, GRND_NONBLOCK);
#else
#ifdef HAVE_CRYPT_URANDOM_SYSCALL_GETRANDOM
	RETVAL = syscall(SYS_getrandom, data, length, GRND_NONBLOCK);
#else
#ifdef HAVE_CRYPT_URANDOM_NATIVE_GETENTROPY
        RETVAL = getentropy(data, length);
#else
#ifdef HAVE_CRYPT_URANDOM_UNISTD_GETENTROPY
        RETVAL = getentropy(data, length);
#else
        croak("Unable to find getrandom or an alternative");
#endif
#endif
#endif
#endif
        if (RETVAL == -1) {
            XSRETURN_UNDEF;
        }
        data[RETVAL] = '\0';
        SvCUR_set(buffer, RETVAL);
        SvUTF8_off(buffer);
        SvSETMAGIC(buffer);
    OUTPUT:
        RETVAL
