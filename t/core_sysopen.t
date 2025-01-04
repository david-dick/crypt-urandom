#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use English();
use Carp();
use English qw( -no_match_vars );
use Exporter();
use XSLoader();
use constant;
use overload;

SKIP: {
	if ($^O eq 'MSWin32') {
		skip("No functions to override in Win32", 1);
	} else {
		no warnings;
		*CORE::GLOBAL::sysopen = sub { $! = POSIX::EACCES(); return };
		use warnings;
		require POSIX;
		my $required_error_message = q[(?:] . (quotemeta POSIX::strerror(POSIX::EACCES())) . q[|Permission[ ]denied)];
		require FileHandle;
		@INC = qw(blib/lib); # making sure we're testing pure perl version
		require Crypt::URandom;
		my $generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when sysopen is overridden:$@");
		$generated = 0;
		eval {
			Crypt::URandom::urandom(1);
			$generated = 1;
		};
		chomp $@;
		ok(!$generated && $@ =~ /$required_error_message/smx, "Correct exception thrown when sysopen is overridden twice:$@");
	}
}
done_testing();
