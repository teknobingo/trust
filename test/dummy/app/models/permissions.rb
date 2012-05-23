module Permissions
  class Default < Trust::Permissions
    role :system_admin do
      can :manage
      can :audit
    end
  end
  
  # class Account < Default
  #   role :operator do
  #     can :create, :if => :owner_of_settlement?
  #   end
  #   role [:department_manager, :accountant] do
  #     can :create, :if => lambda { parent }
  #   end
    
  #   def owner_of_settlement?
  #     parent && parent.operator_id == user.id
  #   end
  # end

end
