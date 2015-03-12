1.0

Trust::Permissions.action_aliases - defaults has been removed

Support for rails 4.

Permissions has been extended to support the keywords for strong params:
  * require
  * permit

Setting default:
  class Permission::Invoice < Default
    require :invoice # Not really necessary to set. If not set it will default to the class name
    permit :date, :due_days
  end

Setting on action:
  class Permission::Invoice < Default
    role :accountant do
      can :search, require: :criteria, permit: [:date, :due_date, :client_no]
      can :create, permit: [:date, :due_date]
    end
  end

Accessing strong params:
  resource.strong_params # can be accessed once resource has been loaded.