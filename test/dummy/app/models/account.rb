class Account < ActiveRecord::Base
  attr_accessible :name, :client_id
  belongs_to :client
  belongs_to :created_by, :class_name => 'User'

  before_create :set_owner

  def set_owner
    self.created_by = User.current
  end
end
