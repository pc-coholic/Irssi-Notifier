use strict;
use vars qw($VERSION %IRSSI);

use Irssi;

$VERSION = '1.00';
%IRSSI = (
    authors     => 'Martin Gross',
    contact     => 'martin@pc-coholic.de',
    name        => 'Irssi notifier',
    description => 'This script pushes ' .
                   'notifications to your ' .
                   'devices.',
    license     => 'Public Domain',
    url		=> 'http://www.pc-coholic.de/',
);

#--------------------------------------------------------------------
# Are we running inside a screen?
# Executed once on startup
# Based on code from screen_away from Andreas 'ads' Scherbaum
#--------------------------------------------------------------------

if (!defined($ENV{STY})) {
	print("ERROR: Irssi is not running inside a screen. Quitting.");
	return;
}

my ($socket_name, $socket_path);

my $socket = `LC_ALL="C" screen -ls`;

if ($socket !~ /^No Sockets found/s) {
	# ok, should have only one socket
	$socket_name = $ENV{'STY'};
	$socket_path = $socket;
	$socket_path =~ s/^.+\d+ Sockets? in ([^\n]+)\.\n.+$/$1/s;
	
	if (length($socket_path) == length($socket)) {
		print "ERROR: Problems reading from socket " . $socket;
		return;
	}
}

# build complete socket name
$socket = $socket_path . "/" . $socket_name;

#--------------------------------------------------------------------
# Check if screen is attached at this precise moment
# Based on code from screen_away from Andreas 'ads' Scherbaum
#--------------------------------------------------------------------

sub screenstat {
	my @screen = stat($socket);
	# 00100 is the mode for "user has execute permissions", see stat.h
	if (($screen[2] & 00100) == 0) {
		# no execute permissions, Detached
		return 0;
	} else {
		# execute permissions, Attached
		return 1;
	}
}

#--------------------------------------------------------------------
# Process queries and pass them to notify
#--------------------------------------------------------------------

sub process_query {
	my ($server,$msg,$nick,$address,$target) = @_;
	notify("query", $nick, $msg);
}

#--------------------------------------------------------------------
# Process hilights and pass them to notify
#--------------------------------------------------------------------

sub process_hilight {
    my ($dest, $text, $stripped) = @_;
    if ($dest->{level} & MSGLEVEL_HILIGHT) {
	# Get only username without <@ >
	$stripped =~ /((?:[a-z][a-z0-9_]*))/;
	my $sender = $&;
	
	# Remove <username> and get rest as message
	$stripped =~ /(<[^>]+>\s)/;
	my $message = $';

	notify("hilight", $sender, $message, $dest->{target});
    }
}

#--------------------------------------------------------------------
# print the notifications
#--------------------------------------------------------------------

sub notify {
	my ($type, $sender, $message, $channel) = @_;
	print $type;
	print $sender;
	print $message;
	print $channel;
	print screenstat();
}

#--------------------------------------------------------------------
# Listen to irssi-signals
#--------------------------------------------------------------------

Irssi::signal_add_last("message private", "process_query");
Irssi::signal_add_last("print text", "process_hilight");
