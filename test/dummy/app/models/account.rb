class Account < ActiveRecord::Base
  attr_accessible :name, :client_id
  belongs_to :client
end
