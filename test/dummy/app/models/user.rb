class User < ActiveRecord::Base
  attr_accessible :name

  def role_symbols
    [ name && name.to_sym]
  end

end
