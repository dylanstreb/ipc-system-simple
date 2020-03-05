#!/usr/bin/perl -w
use strict;
use Test::More tests => 12;
use Config;
use constant NO_SUCH_CMD => "this_command_had_better_not_exist";

# We want to invoke our sub-commands using Perl.

my $perl_path = $Config{perlpath};

if ($^O ne 'VMS') {
	$perl_path .= $Config{_exe}
		unless $perl_path =~ m/$Config{_exe}$/i;
}

# Win32 systems don't support multi-arg pipes.  Our
# simple captures will begin with single-arg tests.
my $output_exe = "$perl_path output.pl";

use_ok("IPC::System::Simple","capture");
chdir("t");

#Open a Perl script as backup input. If Perl is called with no arguments, it
#waits for input on STDIN.
#This ensures there's data on STDIN so it doesn't hang.
open my $input, '<', 'fail_test.pl' or die "Couldn't open perl script - $!";
my $fileno = fileno($input);
open STDIN, "<&", $fileno or die "Couldn't dup - $!";

# Scalar capture

my $output = capture($output_exe);
seek($input, 0, 0); #Rewind STDIN. Necessary after every potential Perl call
ok(1);

is($output,"Hello\nGoodbye\n","Scalar capture");
is($/,"\n","IFS intact");

my $qx_output = qx($output_exe);
seek($input, 0, 0);
is($output, $qx_output, "capture and qx() return same results");

# List capture

my @output = capture($output_exe);
seek($input, 0, 0);
ok(1);

is_deeply(\@output,["Hello\n", "Goodbye\n"],"List capture");
is($/,"\n","IFS intact");

my $no_output;
eval {
	$no_output = capture(NO_SUCH_CMD);
};

like($@,qr/failed to start/, "failed capture");
is($no_output,undef, "No output from failed command");

# The following is to try and catch weird buffering issues
# as we move around filehandles inside capture().

print "# buffer test string";	# NB, no trailing newline

$output = capture($output_exe);
seek($input, 0, 0);

print "\n";  # Terminates our test string above in TAP output

like($output,qr{Hello},"Single-arg capture still works");
unlike($output,qr{buffer test},"No unflushed data readback");
