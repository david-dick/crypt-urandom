use Config;

my $test_file_name = 'test.c';
my $binary_name = 'a.out';
open FOO, ">$test_file_name" or die "Failed to open $test_file_name for writing:$!";
print FOO <<'_OUT_';
#include <sys/random.h>

int main(void)
{
        char buf[5];
        int l = 5;
        unsigned int o = 1;
        int r = getrandom(buf, l, o);
        return 0;
}
_OUT_
close FOO or die "Failed to close $test_file_name:$!";
my $result = system { $Config{cc} } $Config{cc}, '-o', $binary_name, $test_file_name;
unlink $test_file_name or die "Failed to unlink $test_file_name:$!";
if ($result == 0) {
	unlink $binary_name or die "Failed to unlink $binary_name:$!";
	$optional{DEFINE} = '-DHAVE_CRYPT_URANDOM_NATIVE_GETRANDOM';
} else {
	open FOO, ">$test_file_name" or die "Failed to open $test_file_name for writing:$!";
	print FOO <<'_OUT_';
#include <sys/syscall.h>

int main(void)
{
        char buf[5];
        int l = 5;
        unsigned int o = 1;
        int r = syscall(SYS_getrandom, buf, l, o);
        return 0;
}
_OUT_
	close FOO or die "Failed to close $test_file_name:$!";
	my $result = system { $Config{cc} } $Config{cc}, '-o', $binary_name, $test_file_name;
	if ($result == 0) {
		unlink $binary_name or die "Failed to unlink $binary_name:$!";
		$optional{DEFINE} = '-DHAVE_CRYPT_URANDOM_SYSCALL_GETRANDOM';
	}
	unlink $test_file_name or die "Failed to unlink $test_file_name:$!";
}
