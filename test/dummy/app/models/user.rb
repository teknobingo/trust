class User < ActiveRecord::Base

  def role_symbols
    [ name && name.to_sym]
  end

end
