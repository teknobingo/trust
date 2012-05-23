module Permissions
  class Default < Trust::Permissions
    role :system_admin do
      can :manage
      can :audit
    end
  end

  class Client < Default
    role :accountant do
      can :manage
    end
  end
  
  class Account < Default
    role :accountant do
      can :create, :if => :associated_with_client?
    end
    role [:department_manager, :accountant] do
      can :create, :if => lambda { parent }
    end
    
    def associated_with_client?
      parent && parent.is_a?(Client) && parent.accountant == user.name
    end
  end

  class Account::Credit < Account
    role :guest do
      can :create, :if => lambda { user.name == 'wife'}
    end
    
  end


end
