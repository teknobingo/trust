class User < ActiveRecord::Base
  attr_accessible :name

  def role_symbols
    [:system_admin]
  end

end
