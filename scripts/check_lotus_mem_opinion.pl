#!/usr/bin/perl -w
#
# check_lotus_mem_opinion.pl - nagios plugin
#
# Copyright (C) 2011 Richard Clark <richard@fohnet.co.uk>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
# 15.05.2011 Version 0.01
#
 
use strict;
use Getopt::Long;
use Net::SNMP;
use vars qw($PROGNAME);
use lib "/usr/local/nagios/libexec";
use utils qw ($TIMEOUT %ERRORS &print_revision &support);

sub print_help ();
sub print_usage ();
sub print_version ();
 
my $Version='0.01';
my ($opt_V, $opt_h, $opt_C, $opt_P, $opt_H, $opt_p, $opt_t, $opt_v);
my ($status, $result, $opinion, $check_oid, $o_login, $o_passwd, @check_oids, $warn_state, $crit_state, $ok_state);

$check_oid = "1.3.6.1.4.1.334.72.1.1.9.4.0";
@check_oids=($check_oid);
 
my $PROGNAME = "check_lotus_mem_opinion";
 
$opt_C="public";
$opt_P="2";
$opt_H="";
$opt_p=161;
$opt_t="10";
$o_login = undef;
$o_passwd = undef;
$ok_state = "Plentiful";
$warn_state = "Normal";
$crit_state = "Painful";
 
Getopt::Long::Configure('bundling');
GetOptions(
        "V"   => \$opt_V, "version"     => \$opt_V,
        "v"   => \$opt_v, "verbose"     => \$opt_v,
        "h"   => \$opt_h, "help"        => \$opt_h,
        "C=s" => \$opt_C, "community"   => \$opt_C,
        "P=s" => \$opt_P, "protocol=s"  => \$opt_P,
        "H=s" => \$opt_H, "hostname"    => \$opt_H,
        "p=i" => \$opt_p, "port"        => \$opt_p,
        "t=i" => \$opt_t, "timeout"     => \$opt_t);
 
if ($opt_t) {
    $TIMEOUT=$opt_t;
}

# For verbose output
sub verb { my $t=shift; print $t,"\n" if defined($opt_v) ; }
 
# Just in case of problems, let's not hang Nagios
$SIG{'ALRM'} = sub {
    print "UNKNOWN - Plugin Timed out\n";
    exit $ERRORS{"UNKNOWN"};
};
alarm($TIMEOUT);
 
sub print_usage () {
    print "Usage:\n";
    print "  $PROGNAME -H <hostname> [-C <COMMUNITY>] [-p <port>] [-P <snmp-version>]\n";
    print "  $PROGNAME [-h | --help]\n";
    print "  $PROGNAME [-V | --version]\n";
    print "\n\nOptions:\n";
    print "  -H, --hostname\n";
    print "     Host name or IP Address\n";
    print "  -C, --community\n";
    print "     Optional community string for SNMP communication\n";
    print "     (default is \"public\")\n";
    print "  -p, --port\n";
    print "     Port number (default: 161)\n";
    print "  -P, --protocol\n";
    print "     SNMP protocol version [1,2c,3]\n";
    print "     (SNMPv3 not fully supported in this version)\n";
    print "  -h, --help\n";
    print "     Print detailed help screen\n";
    print "  -V, --version\n";
    print "     Print version information\n\n";
}

sub print_version () {
    print " $PROGNAME v$Version\n";
}
 
sub print_help () {
        print "Copyright (c) 2011 Richard Clark\n\n";
        print_version();
        print "\n";
        print_usage();
        print "\n";
        support();
}

# error checking 

if ($opt_h) {
    print_help();
    exit $ERRORS{'OK'};
}

if ($opt_V) {
    print_version();
    exit $ERRORS{'OK'};
}
 
if (! $opt_H) {
    print "No Hostname specified\n\n";
    print_usage();
    exit $ERRORS{'UNKNOWN'};
}

if (! $opt_C) {
    print "No SNMP community specified\n\n";
    print_usage();
    exit $ERRORS{'UNKNOWN'};
}
 

 
#### MAIN ####

if (defined($TIMEOUT)) {
    verb("Alarm at $TIMEOUT");
    alarm($TIMEOUT);
} else {
    verb("no timeout defined : $opt_t + 10");
    alarm ($opt_t+10);
}

# Connect to host
my ($session,$error);
if ( defined($o_login) && defined($o_passwd)) {
  # SNMPv3 login
  verb("SNMPv3 login");
  ($session, $error) = Net::SNMP->session(
      -hostname         => $opt_H,
      -version          => '3',
      -username         => $o_login,
      -authpassword     => $o_passwd,
      -authprotocol     => 'md5',
      -privpassword     => $o_passwd,
      -timeout          => $opt_t
   );
} else {
   if (defined ($opt_P) && ($opt_P == 2)) {
     # SNMPv2 Login
         ($session, $error) = Net::SNMP->session(
        -hostname  => $opt_H,
        -version   => 2,
        -community => $opt_C,
        -port      => $opt_p,
        -timeout   => $opt_t
     );
   } else {
    # SNMPV1 login
    ($session, $error) = Net::SNMP->session(
       -hostname  => $opt_H,
       -community => $opt_C,
       -port      => $opt_p,
       -timeout   => $opt_t
    );
  }
}

if (!defined($session)) {
   printf("ERROR opening session: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

$result = (Net::SNMP->VERSION < 4) ?
                 $session->get_request(@check_oids)
                 :$session->get_request(-varbindlist => \@check_oids);

if (!defined($result)) {
    printf("ERROR: SNMP error : %s.\n", $session->error);
    $session->close;
    exit $ERRORS{"UNKNOWN"};
}

$result = ($$result{$check_oid});

if ($result = $ok_state) {
    $status = "OK";
} elsif ($result = $warn_state) {
    $status = "WARNING";
} elsif ($result = $crit_state) {
    $status = "CRITICAL";
} else {
    $status = "UNKNOWN";
}
print $status . ": Server opinion on memory is: " . $result . "\n";
$session->close; 
exit $ERRORS{$status};

