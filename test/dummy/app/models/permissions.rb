module Permissions
  class Default < Trust::Permissions
    role :system_admin do
      can :manage
      can :audit
    end
    
    def self.all
      [:system_admin, :accountant, :department_manager, :guest]
    end
    
    def creator?
      subject.created_by == user
    end
  end

  class Client < Default
    role :accountant, can(:manage)
    role all, can(:read)
  end
  
  class Account < Default
    role :accountant do
      can :create, :if => :associated_with_client?
      can :update, :if => :creator?
    end
    role :department_manager, :accountant do
      can :create, :if => lambda { parent && parent.accountant == :superspecial }
    end
    
    def associated_with_client?
      parent && parent.is_a?(::Client) && parent.accountant == user.name
    end
  end

  class Account::Credit < Account
    role :guest do
      can :create, :if => lambda { user.name == 'wife'}
    end
    
  end


end
