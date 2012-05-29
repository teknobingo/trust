class User < ActiveRecord::Base
  attr_accessible :name

  def role_symbols
    [ name && name.to_sym]
  end

  def self.current
    Thread.current["current_user"]
  end

  def self.current= user
    Thread.current["current_user"] = user
  end

end
