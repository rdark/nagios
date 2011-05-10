require 'rubygems'
require 'snmp'

MY_MIB_PATH='/usr/share/snmp/mibs/'

# see README
# SNMP::MIB.import_module(MY_MIB_PATH + 'BRIDGE-MIB.txt')
# SNMP::MIB.import_module(MY_MIB_PATH + 'CISCO-SMI-V1SMI.txt')
# SNMP::MIB.import_module(MY_MIB_PATH + 'CISCO-VTP-MIB-V1SMI.txt')
# SNMP::MIB.import_module(MY_MIB_PATH + 'RFC1155-SMI.txt')
# SNMP::MIB.import_module(MY_MIB_PATH + 'RFC1213-MIB.txt')
SNMP::MIB.import_module(MY_MIB_PATH + 'PowerNet-MIB.txt')

class SnmpApcStatus
  SOID_PREFIX = 'PowerNet-MIB::rPDU'

  COMMON_STRING_OIDS = {
    :get => {
      :firmware_revision => SOID_PREFIX + 'IdentFirmwareRev.0',
      :hardware_revision => SOID_PREFIX + 'IdentHardwareRev.0',
      :model_number => SOID_PREFIX + 'IdentModelNumber.0',
      :serial_number => SOID_PREFIX + 'IdentSerialNumber.0',
      :outlet_count => SOID_PREFIX + 'OutletDevNumCntrlOutlets.0',
      :power1 => SOID_PREFIX + 'PowerSupply1Status.0',
      :power2 => SOID_PREFIX + 'PowerSupply2Status.0',
      :bank_count => SOID_PREFIX + 'LoadDevNumBanks.0'
    },
    :walk => {
      :load => SOID_PREFIX + 'LoadStatusLoad'
    }
  }
  
  THRESHOLD_STRING_OIDS = {
    :phase => {
      :near_overload => SOID_PREFIX + 'LoadPhaseConfigNearOverloadThreshold.1',
      :overload => SOID_PREFIX + 'LoadPhaseConfigOverloadThreshold.1'
    },
    :bank => {
      :near_overload => SOID_PREFIX + 'LoadBankConfigNearOverloadThreshold.3',
      :overload => SOID_PREFIX + 'LoadBankConfigOverloadThreshold.3',
    },
  }
  
  def v3?
    @apc_info[:firmware_revision] =~ /^v3/
  end
  
  def phase?
    (@apc_info[:firmware_revision] =~ /^v2/) or (v3? and @apc_info[:bank_count] == 0)
  end
  
  def initialize(kwargs = {})
    @apc_info = {}
    begin
      SNMP::Manager.open(:Host => kwargs[:host],
                         :Version => :SNMPv1,
                         :Community => kwargs[:community],
                         :MibModules => "PowerNet-MIB"
                         ) do |manager|
        COMMON_STRING_OIDS[:get].each { |k, string_oid|
          manager.get(string_oid).each_varbind { |vb|
            @apc_info[k] = vb.value
          }
        }

        load = []
        manager.walk(COMMON_STRING_OIDS[:walk][:load]) { |vb| load << vb.value.to_i }
        @apc_info[:load] = load.max
        
        if phase?:
          THRESHOLD_STRING_OIDS[:phase].each { |k, string_oid|
            manager.get(string_oid).each_varbind { |vb| @apc_info[k] = vb.value }
          }
        else
          THRESHOLD_STRING_OIDS[:bank].each { |k, string_oid|
            manager.get(string_oid).each_varbind { |vb| @apc_info[k] = vb.value}
          }
        end
      end
    rescue
      puts "UNKNOWN: An error occured while running snmp command, possible wrong pdu or mib not present!"
      raise
    end
  end
  
  def to_hash
    @apc_info
  end
end
