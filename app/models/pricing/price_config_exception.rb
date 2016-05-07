
class PriceConfigException < RuntimeError
  def initialize(issue)
    @issue = issue
  end
  
  def issue
    @issue
  end
end