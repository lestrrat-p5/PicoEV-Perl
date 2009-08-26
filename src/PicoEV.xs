#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "picoev.h"

#define PICOEV_MAX_FDS 1024

static void
Perl_picoev_exec_callback(picoev_loop *loop, int fd, int events, void *args) {

    AV *cb_arg = (AV *) args;
    SV *self;
    SV *cv;
    SV *io;
    AV *cv_arg;
    SV **svr;
    I32 cv_arg_len = 0;

    svr = av_fetch(cb_arg, 0, 0);
    if (svr == NULL) {
        croak("callback did not receive proper object");
    }
    self = (SV *) *(svr);

    svr = av_fetch(cb_arg, 1, 0);
    if (svr == NULL) {
        croak("callback did not receive proper code reference");
    }
    cv = (SV *) *(svr);

    svr = av_fetch(cb_arg, 2, 0);
    if (svr == NULL) {
        croak("Lost IO ref");
    }
    io = (SV *) *(svr);

    svr = av_fetch(cb_arg, 3, 0);
    if (svr != NULL) {
        cv_arg = (AV *) SvRV(*(svr));
        cv_arg_len = av_len(cv_arg) + 1;
    }

    {
        int i;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

        XPUSHs(self);
        XPUSHs(io);
        if (cv_arg_len > 0) {
            for(i = 0; i < cv_arg_len; i++) {
                SV **svr;
                svr = av_fetch(cv_arg, i, 0);
                if (svr != NULL) {
                    XPUSHs( *svr );
                }
            }
        }
        PUTBACK;
        call_sv( (SV *)cv, G_VOID);
    }

    FREETMPS;
    LEAVE;
}

MODULE = PicoEV      PACKAGE = PicoEV         PREFIX = picoev_

PROTOTYPES: DISABLE

BOOT:
    picoev_init(PICOEV_MAX_FDS);

int
picoev_deinit()

MODULE = PicoEV      PACKAGE = PicoEV::Loop   PREFIX = Perl_picoev_loop_

PROTOTYPES: DISABLE

picoev_loop *
Perl_picoev_loop_create(class_sv, max_timeout)
        SV *class_sv;
        int max_timeout;
    CODE:
        RETVAL = picoev_create_loop(max_timeout);
    OUTPUT:
        RETVAL

int
Perl_picoev_loop_DESTROY(loop)
        picoev_loop *loop;
    CODE:
        RETVAL = picoev_destroy_loop(loop);
    OUTPUT:
        RETVAL

int
Perl_picoev_loop_once(loop, max_wait)
        picoev_loop *loop;
        int max_wait;
    CODE:
        RETVAL = picoev_loop_once(loop, max_wait);
    OUTPUT:
        RETVAL

int
Perl_picoev_loop_add(loop, fd, events, timeout_in_secs, callback, cb_arg)
        picoev_loop *loop;
        SV *fd;
        int events;
        int timeout_in_secs;
        SV *callback;
        SV *cb_arg;
    PREINIT:
        AV *real_cb_arg = newAV();
    CODE:
        if (! SvOK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV ) {
            croak("callback must be a coderef");
        }

        /* we will NOT refcnt_inc the loop object */
        av_store(real_cb_arg, 0, ST(0));
        av_store(real_cb_arg, 1, SvREFCNT_inc(callback) );
        av_store(real_cb_arg, 2, SvREFCNT_inc(fd));
        if (SvOK(cb_arg)) {
            if ( SvTYPE(SvRV(cb_arg)) != SVt_PVAV ) {
                croak("cb_arg must be an arrayref");
            }
            av_store(real_cb_arg, 3, SvREFCNT_inc(cb_arg));
        }

        RETVAL = picoev_add(loop, 
            PerlIO_fileno( IoIFP(sv_2io(fd) ) ),
            events,
            timeout_in_secs,
            Perl_picoev_exec_callback,
            (void *) real_cb_arg
        );
    OUTPUT:
        RETVAL

