require 'getoptlong'

$:.unshift File.join(File.dirname(__FILE__), "lib") 
require 'apc_status'
require 'snmp_apc_status'

ERRORS = {
  :ok => 0,
  :warning => 1,
  :critical => 2,
  :unknown => 3,
}

PROGNAME = 'check_snmp_apc_pdu'
PROGVERSION = '1.1'

def print_usage
  puts "Usage: #{PROGNAME} -H <Hostname> -C <Community> [-w <warn>] [-c <crit>] [-v] [-h] [--perfdata]"
end

def print_help
  print_revision(PROGNAME, PROGVERSION)
  puts "Copyright (c) 2005 Rouven Homann"
  puts "Copyright (c) 2007 Eddy Mulyono"
  puts "Copyright (c) 2011 Richard Clark"
  puts
  print_usage
  puts
  puts "-H <Hostname> = Hostname or IP-Address."
  puts "-C <Community> = Community read password."
  puts "-v = Verbose Output."
  puts "-h = This screen."
  puts "--perfdata = Output performance data."
  puts
  support
end

def print_revision(progname, revision)
end

def support
end

def check_snmp_apc_pdu_main
  opts = GetoptLong.new(
                        ['--version', '-V', GetoptLong::NO_ARGUMENT],
                        ['--help', '-h', GetoptLong::NO_ARGUMENT],
                        ['--verbose', '-v', GetoptLong::NO_ARGUMENT],
                        ['--warning', '-w', GetoptLong::REQUIRED_ARGUMENT],
                        ['--host', '-H', GetoptLong::REQUIRED_ARGUMENT],
                        ['--community', '-C', GetoptLong::REQUIRED_ARGUMENT],
                        ['--critical', '-c', GetoptLong::REQUIRED_ARGUMENT],
                        ['--perfdata', GetoptLong::NO_ARGUMENT]
                        )

  opt_h, verbose, opt_w, opt_H, opt_C, opt_c, perfdata = nil
  
  opts.each do |opt, arg|
    case opt
    when '-V','--version'
      print_revision(PROGNAME, PROGVERSION)
      exit(ERRORS[:unknown])
    when '-h','--help'
      opt_h = true
      print_help
      exit(ERRORS[:unknown])
    when '-v','--verbose'
      verbose = true
    when '-w','--warning'
      opt_w = arg
    when '-H','--host'
      opt_H = arg
    when '-C','--community'
      opt_C = arg
    when '-c','--critical'
      opt_c = arg
    when '--perfdata'
      perfdata = true
    end
  end
  
  unless defined?(opt_H) and defined?(opt_C):
      print_usage
    exit(ERRORS[:unknown]) unless defined? opt_h
  end

  begin
    snmp_apc_status = SnmpApcStatus.new(:host => opt_H, :community => opt_C)
  rescue
    exit(ERRORS[:unknown]);
  end

  apc_status = ApcStatus.new(snmp_apc_status.to_hash)
  
  apc_status.near_overload = opt_w.to_i if opt_w
  apc_status.overload = opt_c.to_i if opt_c
  
  puts apc_status.to_nagios_s(:verbose=>verbose, :perfdata=>perfdata)
  
  case
  when apc_status.ok?: exit(ERRORS[:ok])
  when apc_status.warning?: exit(ERRORS[:warning])
  when apc_status.critical?: exit(ERRORS[:critical])
  end
end

check_snmp_apc_pdu_main
