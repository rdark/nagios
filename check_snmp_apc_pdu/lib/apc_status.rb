require 'apc_power_supply_status'

class ApcStatus
  attr_reader :power1,
  :power2, 
  :load, 
  :hardware_revision, 
  :firmware_revision, 
  :outlet_count, 
  :serial_number, 
  :model_number
  
  attr_accessor :near_overload, :overload
  
  def initialize(hash)
    @firmware_revision = hash[:firmware_revision]
    @power1 = ApcPowerSupplyStatus.new hash[:power1]
    @power2 = ApcPowerSupplyStatus.new hash[:power2]
    @hardware_revision = hash[:hardware_revision]
    @outlet_count = hash[:outlet_count]
    @serial_number = hash[:serial_number]
    @model_number = hash[:model_number]
    @near_overload = hash[:near_overload].to_i
    @overload = hash[:overload].to_i
    @load = hash[:load].to_i / 10 # intentional flooring.
  end
  
  def ok?
    @load < @near_overload and power1.ok? and power2.ok?
  end
  
  def overloaded?
    @load >= @overload
  end
  
  def critical?
    overloaded? or power1.failed? or power2.failed?
  end
  
  def warning?
    near_overload?
  end
  
  def near_overload?
    @load.between?(@near_overload, @overload - 1)
  end
  
  def to_nagios_s(kwargs={})
    result = case
             when ok?: "OK"
             when warning? : "WARNING"
             when critical? : "CRITICAL"
             end
    
    result += ': '
    
    if kwargs[:verbose]
      result += to_verbose_s
    else
      result += "Load #{@load}A, " + power_supplies_to_s
    end
    
    result += perfdata if kwargs[:perfdata]

    return result
  end
  
  def power_supplies_to_s
    ["Power1: #{@power1}", "Power2: #{@power2}"].join ', '
  end
  
  def to_verbose_s
    ["Hardware Revision: #{@hardware_revision}",
     "Firmware Revision: #{@firmware_revision}",
     "Model: #{@model_number}", 
     "Serial: #{@serial_number}",
     power_supplies_to_s,
     "Ports #{@outlet_count}",
     "Load #{@load}A",
    ].join ', '
  end
  
  def perfdata
    "|apc_load=#{@load}"
  end
end
