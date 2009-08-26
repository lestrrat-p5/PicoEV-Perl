use inc::Module::Install;

name('PicoEV');
all_from('lib/PicoEV.pm');

use_ppport;
cc_src_paths 'src' ;
# cc_define    "-DVERSION=\"" . version() . "\"";

WriteAll;

