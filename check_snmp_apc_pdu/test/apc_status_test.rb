require 'test/unit'

require 'rubygems'
require 'snmp'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'apc_status'

class ApcStatusTest < Test::Unit::TestCase
  def make_hash(kwargs={})
    kwargs[:load] ||= 59
    kwargs[:power1] ||= ApcPowerSupplyStatus::OK
    kwargs[:power2] ||= ApcPowerSupplyStatus::OK
    hash = {
      :hardware_revision =>"B2",
      :overload => SNMP::Integer.new(24),
      :power1 => SNMP::Integer.new(kwargs[:power1]),
      :outlet_count =>SNMP::Integer.new(24),
      :serial_number=>"ZA0542019626",
      :model_number=>"AP7941",
      :firmware_revision=>"v3.3.3",
      :load=>SNMP::Gauge32.new(kwargs[:load]),
      :near_overload=>SNMP::Integer.new(18),
      :power2=>SNMP::Integer.new(kwargs[:power2])
    }
  end
  
  def test_init
    apc_status = ApcStatus.new(make_hash)
    assert_equal("B2", apc_status.hardware_revision)
    assert_equal(24, apc_status.outlet_count)
    assert_equal("ZA0542019626", apc_status.serial_number)
    assert_equal("AP7941", apc_status.model_number)
    assert_equal("v3.3.3", apc_status.firmware_revision)
    assert_equal(5, apc_status.load)
    assert apc_status.power1.ok?
    assert apc_status.power2.ok?
    assert apc_status.ok?
    assert(!apc_status.near_overload?)
    assert(!apc_status.overloaded?)
  end

  def test_near_overload
    loads = [180, 190, 230]
    loads.collect {|load| ApcStatus.new(make_hash(:load => load)) }.each do |apc_status| 
      assert !apc_status.ok?
      assert apc_status.near_overload?
      assert !apc_status.overloaded?
    end
  end
  
  def test_overload
    apc_status = ApcStatus.new(make_hash(:load => 240))
    assert !apc_status.ok?
    assert !apc_status.near_overload?
    assert apc_status.overloaded?
  end

  def test_to_nagios_s
    apc_status = ApcStatus.new(make_hash)
    assert_equal('OK: Hardware Revision: B2, Firmware Revision: v3.3.3, Model: AP7941, Serial: ZA0542019626, Power1: Ok, Power2: Ok, Ports 24, Load 5A|apc_load=5', apc_status.to_nagios_s(:verbose => true, :perfdata => true))
    assert_equal('OK: Hardware Revision: B2, Firmware Revision: v3.3.3, Model: AP7941, Serial: ZA0542019626, Power1: Ok, Power2: Ok, Ports 24, Load 5A', apc_status.to_nagios_s(:verbose => true))
    assert_equal('OK: Load 5A, Power1: Ok, Power2: Ok', apc_status.to_nagios_s)
  end
end
