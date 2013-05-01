#!/usr/bin/perl -w
#################################
# Version 1.1
# Date 02:22 PM 2008/10/23
# Author Paul Slabbert
# Updated 26/10/2010 by rclark
# added maximum uptime support
# Updated 14/11/2011 by jwagner
# added human readable time for 
# output (hours / days ...)
#################################

use strict;
use Net::SNMP;
use Getopt::Long;

use lib "/usr/lib/nagios/plugins";
use utils qw(%ERRORS $TIMEOUT);

my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
#################################
# VARS
my $uptime='.1.3.6.1.2.1.1.3.0';
my $host= "";
my $community= "";
my $port=161;
my $minwarn;
my $mincrit;
my $maxwarn;
my $maxcrit;
my $timeout=20;

my $session;
my $error=undef;
my $perfout = undef;
my $minute;
my $state;

#################################


sub print_usage {
    print "Usage: $0 -H <host> -C <snmp_community> [-p <port>] -w <warn *mins*> -c<crit *mins*> -m<max*mins*> -x<max*mins*>\n";
}

sub check_options {
    Getopt::Long::Configure ("bundling");
GetOptions(
"H=s"=>\$host,
'C=s' => \$community,
'p=i' => \$port,
'w=s' => \$minwarn,
'c=s' => \$mincrit,
    'm=s' => \$maxwarn,
    'x=s' => \$maxcrit,
);
if (!defined($host)){
print"Must define Host name\n";
print_usage();
exit $ERRORS{"UNKNOWN"}
}

if (!defined($community)){
print"Must define Community String\n";
print_usage();
exit $ERRORS{"UNKNOWN"}
}

if (!defined($minwarn)){
print"Must define warn\n";
print_usage();
exit $ERRORS{"UNKNOWN"}
}
if (!defined($mincrit)){
print"Must define critical\n";
print_usage();
exit $ERRORS{"UNKNOWN"}
}
if (!defined($maxwarn)){
print"Must define maximum uptime warn\n";
print_usage();
exit $ERRORS{"UNKNOWN"}
}
if (!defined($maxcrit)){
print"Must define maximum uptime critical\n";
print_usage();
exit $ERRORS{"UNKNOWN"}
}
}#end check options

sub get_uptime(){

my $resultat=undef;
my $result;

   # SNMP1 Login
#verb("SNMP v1 login");
($session, $error) = Net::SNMP->session(
-hostname => $host,
-community => $community,
-port => $port,
-timeout => $timeout,
-translate => [
-timeticks => 0x0
]
);
#error handle for connection error
if (!defined($session)) {
printf("ERROR opening session: %s.\n", $error);
exit $ERRORS{"UNKNOWN"};
}

$resultat=$session->get_request($uptime);

#error handle for OID error
if (!defined($resultat)) {
printf("ERROR: Description table : %s.\n", $session->error);
$session->close;
exit $ERRORS{"UNKNOWN"};
}
$session->close;

#get regex on output
$result=$resultat->{$uptime};

$minute=int($result / 6000);
# JW removed string minutes after number 
$perfout=int($result / 6000);
# JW create uptime string as human readable
display_uptime();

}#end Get_uptime

sub warn_crit(){
#can have critical changing to warning
#critical
if($minute<$mincrit){
print "CRITICAL - Device Rebooted ".$perfout.'|'.'uptime='.$minute.';'.$minwarn.';'.$mincrit.';'.$maxwarn.';'.$maxcrit.';';
$state=$ERRORS{"CRITICAL"};
return $state;
}
    elsif($minute>$maxcrit){
        print "CRITICAL - Device Exceeded Maximum Uptime ".$perfout.'|'.'uptime='.$minute.';'.$minwarn.';'.$mincrit.';'.$maxwarn.';'.$maxcrit.';';
        $state=$ERRORS{"CRITICAL"};
        return $state;
    }
#warning
elsif($minute<$minwarn){
print "WARNING - Device Rebooted ".$perfout.'|'.'uptime='.$minute.';'.$minwarn.';'.$mincrit.';'.$maxwarn.';'.$maxcrit.';';
$state=$ERRORS{"WARNING"};
return $state;
}
elsif($minute>$maxwarn){
print "WARNING - Device Reached Maximum Uptime ".$perfout.'|'.'uptime='.$minute.';'.$minwarn.';'.$mincrit.';'.$maxwarn.';'.$maxcrit.';';
$state=$ERRORS{"WARNING"};
return $state;
}
#OK
elsif($minute>=$mincrit){
print "OK - Device UP ".$perfout.'|'.'uptime='.$minute.';'.$minwarn.';'.$mincrit.';'.$maxwarn.';'.$maxcrit.';';
$state=$ERRORS{"OK"};
return $state;
}
}#end warn_crit
### start main ###

check_options();
get_uptime();
warn_crit();

exit($state);
#-------------------------------------------------------------------------
#----- inserted by Jochen Wagner to get human readable uptime values -----
#----- original from check_wmiplus.pl Matthew Jurgens --------------------
#-------------------------------------------------------------------------
sub display_uptime {
# pass in an uptime string
# if it looks like it is in seconds then we convert it to look like days, hours minutes etc
# my ($perfdata)=@_;
my $new_uptime_string=$perfout;
if ($perfout=~/^[0-9\.]+$/) {
   # its in seconds, so convert it
   my $uptime_minutes=sprintf("%d",$perfout/60);
   my $uptime=$perfout;
   my $days=int($uptime/86400);
   $uptime=$uptime%86400;
   my $hours=int($uptime/3600);
   $uptime=$uptime%3600;
   my $mins=int($uptime/60);
   $uptime=$uptime%60;

   my $day_info='';
   if ($days==1) {
      $day_info="$days day";
   } elsif ($days>1) {
      $day_info="$days days";
   }
   $perfout="$day_info " . sprintf("%02d:%02d:%02d (%smin)",$hours,$mins,$uptime,$uptime_minutes);
}
return $new_uptime_string; 
}
