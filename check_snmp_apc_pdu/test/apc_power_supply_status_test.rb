require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') 
require 'apc_power_supply_status'

class ApcPowerSupplyStatusTest < Test::Unit::TestCase
  def test_happy_path
    power = ApcPowerSupplyStatus.new(1)
    assert power.ok?
    power = ApcPowerSupplyStatus.new(2)
    assert power.failed?
    power = ApcPowerSupplyStatus.new(3)
    assert power.absent?
  end
end
