class ApcPowerSupplyStatus
  FAIL = 2
  NOT_PRESENT = 3
  OK = 1
  def initialize(status_code)
    @status_code = status_code
  end

  def failed?
    @status_code == FAIL
  end

  def absent?
    @status_code == NOT_PRESENT
  end

  def ok?
    @status_code == OK
  end

  def to_s
    case @status_code
    when OK: 'Ok'
    when FAIL: 'Failed'
    when NOT_PRESENT: 'Not Present'
    end
  end
end
