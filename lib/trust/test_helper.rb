class Trust::ResourceHelper
  attr_accessor :instance
  class << self
    attr_accessor :properties
  end
end

class ActionView::TestCase
  # allows you to 
  def resource
    @resource ||= Trust::ResourceHelper.new    
  end
end

