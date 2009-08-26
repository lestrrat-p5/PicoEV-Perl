package PicoEV;
use strict;
use XSLoader;

BEGIN {
    our $VERSION = '0.00001';
    XSLoader::load __PACKAGE__, $VERSION;
}

END {
    deinit();
}

1;