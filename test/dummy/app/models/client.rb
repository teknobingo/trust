class Client < ActiveRecord::Base
  attr_accessible :name
  has_many :accounts
  belongs_to :accountant, :class_name => 'User'

  before_create :set_accountant

  def set_accountant
    self.accountant = User.current
  end
end
