require 'test/unit'

require 'rubygems'
require 'mocha'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'snmp_apc_status'
require 'apc_power_supply_status'

class SnmpApcStatusTest < Test::Unit::TestCase
  
  def my_response value
    SNMP::Response.new(0,SNMP::VarBindList.new([SNMP::VarBind.new('0', value)]))
  end

  def helper(kwargs={})
    manager = SNMP::Manager.new
    kwargs[:get].each { |k,v|
      manager.expects(:get).with(SnmpApcStatus::COMMON_STRING_OIDS[:get][k]).returns(my_response(v))
    }
    
    kwargs[:phase].each { |k, v|
      manager.expects(:get).with(SnmpApcStatus::THRESHOLD_STRING_OIDS[:phase][k]).returns(my_response(v))
    } if kwargs.has_key? :phase

    kwargs[:bank].each { |k, v|
      manager.expects(:get).with(SnmpApcStatus::THRESHOLD_STRING_OIDS[:bank][k]).returns(my_response(v))
    } if kwargs.has_key? :bank

    expectation = manager.expects(:walk).with(SnmpApcStatus::COMMON_STRING_OIDS[:walk][:load])
    kwargs[:walk][:load].each { |load|
      expectation.yields(SNMP::VarBind.new('0', load))
    }
    
    SNMP::Manager.expects(:open).with(:Host => '127.0.0.1',
                                      :Version => :SNMPv1,
                                      :Community => 'public',
                                      :MibModules => "PowerNet-MIB"
                                      ).yields(manager)
    hash = SnmpApcStatus.new(:host => '127.0.0.1', :community => 'public').to_hash
    
    kwargs[:get].each { |k, v|
      assert_equal(v, hash[k])
    }
    assert_equal(kwargs[:walk][:load].max, hash[:load])
    
    if kwargs.has_key? :phase:
        assert_equal(kwargs[:phase][:near_overload], hash[:near_overload])
      assert_equal(kwargs[:phase][:overload], hash[:overload])
    end

    if kwargs.has_key? :bank:
        assert_equal(kwargs[:bank][:near_overload], hash[:near_overload])
      assert_equal(kwargs[:bank][:overload], hash[:overload])
    end
  end
  
  def test_happy_path_v2
    helper(
           :get => {
             :firmware_revision => 'v2.6.5',
             :hardware_revision => 'B2',
             :model_number => 'AP7941',
             :serial_number => 'IA0714009010',
             :power1 => ApcPowerSupplyStatus::OK,
             :power2 => ApcPowerSupplyStatus::OK,
             :outlet_count => 24,
             :bank_count => 2
           },
           :walk => {
             :load => [37,21,15]
           },
           :phase => {
             :near_overload => 18,
             :overload => 24
           }
           )
  end
  
  def test_happy_path_v3
    helper(
           :get => {
             :firmware_revision => 'v3.3.3',
             :hardware_revision => 'B2',
             :model_number => 'AP7941',
             :serial_number => 'IA0714009010',
             :power1 => ApcPowerSupplyStatus::OK,
             :power2 => ApcPowerSupplyStatus::OK,
             :outlet_count => 24,
             :bank_count => 2
           },
           :walk => {
             :load => [0,0,0]
           },
           :bank => {
             :near_overload => 18,
             :overload => 24
           }
           )
  end
  
  def test_single_bank
    helper(
           :get => {
             :firmware_revision => 'v3.3.3',
             :hardware_revision => 'B2',
             :model_number => 'AP7940',
             :serial_number => 'JA0416006757',
             :power1 => ApcPowerSupplyStatus::OK,
             :power2 => ApcPowerSupplyStatus::OK,
             :outlet_count => 24,
             :bank_count => 0
           },
           :walk => {
             :load => [56]
           },
           :phase => {
             :near_overload => 12,
             :overload => 16
           }
           )
  end
end
