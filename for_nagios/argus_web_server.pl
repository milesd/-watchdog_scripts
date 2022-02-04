#!/usr/bin/perl
# 1.01 psc Wed Dec 09 14:11:31 GMT 2015 - Set flush for stdout.
# 1.00 arb Fri Dec  4 14:01:45 GMT 2015

use Socket; # for PF_INET and SOCK_STREAM
use POSIX;  # for strftime

# Flush stdout (don't buffer) so log on disk up to date.
$| = 1;

# Configuration
my $debug = 1;
my $log = "/opr/argus_web_server.log";
my $activelog = "/opr/argus_active.log";
$port = 18768;
$server_ip = "134.36.22.65";

# Startup
my $datetime = sprintf "%s",strftime('%Y-%m-%d %H:%M:%S',localtime);
print "$datetime starting web server on ${server_ip}:${port}\n" if ($debug);

# Create a TCP internet socket and bind to specific port on external interface
socket(SOCKET, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) || die "cannot create socket";
bind(SOCKET, pack_sockaddr_in($port, inet_aton($server_ip)))
   or die "Can't bind to port $port on $server_ip\n";

# Start listening from incoming client connections
listen(SOCKET, 1) || die "cannot listen on socket"; # queuesize=1

# For each connection that comes in create a new client socket for reading
while (1)
{
	my $client_addr = accept(CLIENT_SOCKET, SOCKET);
        my($client_port, $client_ip) = sockaddr_in($client_addr);
        my $client_host = gethostbyaddr($client_ip, AF_INET);
	my $datetime = sprintf "%s",strftime('%Y-%m-%d %H:%M:%S',localtime);
	print "$datetime connection from $client_host\n" if ($debug);
	# Read one line from the socket, eg. GET /test2 HTTP/1.0
	my $line = <CLIENT_SOCKET>;
	print "$datetime $line" if ($debug);
	# Do what the client asks then
	# reply so that client knows it got through
	if ($line =~ /please_reboot_argus_using_NMI/)
	{
		print CLIENT_SOCKET "100 OK\r\nContent-type: text/plain\r\n\r\nJolly good\r\n";
		system "/opr/argus_nmi.sh -f";
	}
	else
	{
		my $last_active_head = `tail -1 $activelog`;
		chomp $last_active_head;
		print CLIENT_SOCKET "100 OK\r\nContent-type: text/plain\r\n\r\nWhat? $last_active_head\r\n";
	}
	close CLIENT_SOCKET;
	$datetime = sprintf "%s",strftime('%Y-%m-%d %H:%M:%S',localtime);
	print "$datetime finished with $client_host\n" if ($debug);
}

exit 0;
