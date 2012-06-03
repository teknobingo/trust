# Trust

### Trust is a no-nonsense framework for authorization control - for Ruby On Rails.

- Why yet another authorization framework you may ask?

Well, we used [DeclarativeAuthorization](http://github.com/stffn/declarative_authorization) for a while, but got stuck when it comes to name-spaces and inheritance. So, we investigated in the possibilities of using [CanCan](http://github.com/ryanb/cancan) and [CanTango](http://github.com/kristianmandrup/cantango), and found that CanCan could be slow, because all permissions has to be loaded on every request. CanTango has tackled this problem by implementing caching, but the framework is still evolving and seems fairly complex. At the same time, CanTango is role focused and not resource focused.

### What will you benefit from when using Trust?

* Resource focused permissions, not role focused
* Complete support for inheritance in controllers
* Complete support for namespaces, both controllers and models
* Complete support for nested resources
* Complete support for shortened associations (e.g. if you have models in name spaces that relates to other models in the name space)
* Fast permission loading, where no cashing is needed. All permissions are declared on class level, so once loaded, they stay in memory.
* Support for inheritance in the permissions model
* Natural code evaluation in the permission declarations, i.e. you understand completely what is going on, because the implementation is done the way you implement condifitions in rails for validations and alike.
* Automatic loading of instances and parents in controller

### What is not supported in Trust

* Loading datasets for the index action. You may use other plugins / gems for doing this, or you may implement your own mechanism.

### Currently not supported, but may be in the future

* Support for devise. However you may easily implement this by overriding one method in your controller.
* cannot and cannot? expressions.

# Install and Setup

Install the gem

    gem install trust

### Define permissions

Create the permissions file in your model directory. Example

``` Ruby
module Permissions
  class Default < Trust::Permissions
    role :system_admin do
      can :manage
      can :audit
    end
  end

  class Account < Default
    role :support, can(:manage)
    role :accountant do
      can :edit, :show, :if => :associated_with_client?
    end
    role :department_manager, :accountant do
      can :create, :if => lambda { parent }
    end

    def associated_with_client?
      parent && parent.is_a?(Client) && parent.operators.find(user.id)
    end
  end
end
```

The following attributes will be accessible in a Permissions class:

* ```subject``` - the resource that is currently being tested for authorization
* ```parent```  - the parent of the authorization when resource is nested
* ```user```    - the user accessing the resource
* ```klass```   - the resource class
* ```action```  - the action that triggered the authorization

Keep in mind that the permission object will be instanciated to do authorization, and not the class.
You can extend the Trust::Permissions with more functionality if needed.

You can also create aliases for actions. We have defined a predefined set of aliases. See Trust::Permissions.action_aliases.
Processing of aliases are done in such way that permissions per action is expanded when the permissions are loaded, so thif you define :update when declaring the permissions, there will be one permission for :update and one for :edit


### Apply access control in controller

Place ```trustee``` in your controller after the user has been identified. Something like this:

``` Ruby
class AccountsController < ApplicationController
  login_required
  trustee
end
```

The trustee statement will set up 3 before_filters in your controller:
  
``` Ruby
before_filter :set_user
before_filter :load_resource
before_filter :access_control
```

Trust assumes that ```current_user``` is accessible. The user object must respond to the method ```role_symbols``` which should return an array of one or more roles for the user.

Handling access denied situations in your controller. Implement something like the following in your ApplicationController:

``` Ruby
class ApplicationController < ActionController::Base
  rescue_from Trust::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
    # or some other redirect
  end
end
```

### Define associations in your controller

For nested resources you can easily define the associations using ```belongs_to``` like this:

``` Ruby
class AccountsController < ApplicationController
  login_required
  belongs_to :client
  trustee
end
```

You can specify as many associations as you like.


## The can? and permits? method

The can? method is accessible from controller and views. Here are some coding examples:

#### In controller or views you will use can?

``` Ruby
can? :edit                          # does the current user have permission to edit the current resource? 
                                    # If there is a nested resource, the parent is automatically associated
can? :edit, @customer               # does the current user have permission to edit the given customer? 
                                    # Parent is also passed on here.
can? :edit, @account, @client       # is current user allowed to edit the account associated with the client?
```

#### On ActiveRecord objects you will use permits?

``` Ruby
@customer.permits? :edit            # does the current user have permission to edit the given customer?
Customer.permits? :create, @client  # does the current user have permission to create customers?
```

## Instance variables

The filter ```load_resource``` will automatically load the instance for the resource in the controller. It will by default use the controller_path to determine the name of the instance variable. Here are a couple of examples:

``` Ruby
UsersController => @user
Account::CreditsController => @account_credit
```

If it is a nested resource, it will also instantiate the ```parent``` class, using the namedefined in belongs_to to determine the name. E.g. if you have defined belongs_to :client, it will look for the parameter ```:client_id``` and perform a find like ```Client.find(client_id)```. Finding the resource will be done through the association between the two, such as ```client.accounts.find(id)```.

You can override the naming by specifying ```model``` like this

``` Ruby
class AccountsController < ApplicationController
  login_required
  model :wackount
  trustee
end
```

If you want to override the name with namespacing then

``` Ruby
class Account::CreditsController < ApplicationController
  login_required
  model :"account/wreckit"
  trustee
end
```

You can also access the instances in a generic manner if you like. Use following statements:
  
``` Ruby
resource.instance => accesses the instance variable
resource.parent   => accesses the parent instance
```

You can even assign these if you like. The resource is also exposed as helper, so you can access it in views.
For simplicity we have also exposed an ```instances``` accessor that you can assign when you have a multirecord result,
such as for index action.

## Overriding defaults

### Overriding resource permits in the controller

Say you have a controller without a model or do not want to perform access control. You can turn off the featur in your controller

``` Ruby
class ApplicationController < ActionController::Base
  login_required
  trustee  # By default we want to test for permissions
end

class MyController < ApplicationController
  trustee :off   # turns off all callbacks
end
```

#### Alternatives
``` Ruby
class MyController < ApplicationController
  set_user :off         # turns off set_user callback
  load_resource :off    # do not load resources
  access_control :off   # turn access control off
end
```

#### More specifically
For all call backs and ```trustee``` you can use ```:only``` and ```:except``` options.
Example toggle create action off
``` Ruby
class MyController < ApplicationController
  load_resource   :except => :create
  access_control  :except => :create
end
```

#### Yet another alternative, avoiding resource loading
Avoid resource loading on ```show``` action
``` Ruby
class MyController < ApplicationController
  actions :except => :show
end
```

### Overriding set_user

If you prefer to use some other user reference than current_user you can override the method ```set_user``` like this in your controller:

``` Ruby
def set_user
  Trust::Authorization.user = User.current
end
```


