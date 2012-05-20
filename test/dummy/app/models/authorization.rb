module Authorization
  class Default < Judge::Base
    role :system_admin do
      can :manage
      can :audit
    end
  end
  
  class Settlement < Default
    role :operator do 
      can :create
      can :read, :if => :owner?
      can :update, :if => :open?
    end    
    role :department_manager do
      can :update, :if => :open?
    end
    
    def owner?
      object.operator_id == user.id
    end
    
    def open?
      [:active, :due_department_approval].include? object.status.to_sym
    end
  end
  
  class Account < Default
    role :operator do
      can :create, :if => :owner_of_settlement?
    end
    role [:department_manager, :accountant] do
      can :create, :if => lambda { parent }
    end
    
    def owner_of_settlement?
      parent && parent.operator_id == user.id
    end
  end
end