# Trust

### Trust is a framework for authorization control - for Ruby On Rails.

- Why yet another authorization framework you may ask?

Well, we used DeclarativeAuthorization[http://github.com/stffn/declarative_authorization] for a while, but got stuck when it comes to name-spaces and inheritance. So, we investigated in the possibilities of using CanCan[http://github.com/ryanb/cancan] and CanTango[http://github.com/kristianmandrup/cantango], and found that CanCan could be slow, because all authorizations has to be loaded on every request. CanTango has tackled this problem by implementing cashing, but the framework is still evolving and seems fairly complex. At the same time, CanTango is role focused and not resource focused.

### What will you benefit from when using Trust?

* Resource focused permissions, not role focused
* Complete support for inheritance in controllers
* Complete support for namespaces, both controllers and models
* Complete support for shortened associations (e.g. if you have models in name spaces that relates to other models in the name space)
* Fast permission loading, where no cashing is needed. All permissions are declared on class level, so once loaded, they stay in memory.
* Support for inheritance in the authorization model
* Natural code evaluation in the authorizations declaration, i.e. you understand completely what is going on, because the implementation is done the way you implement condifitions in rails for validations and alike.
* Automatic loading of instances and parents in controller

### What is not supported in Trust

* Loading datasets for the index action. You may use other plugins / gems for doing this, or you may implement your own mechanism.

### Currently not supported, but may be in the future

* Support for devise. However you may easily implement this by overriding one method in your controller.
* cannot and cannot? expressions.

# Install and Setup

Install the gem

    gem install trust

### Define authorizations

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
      parent && parent.is_a?(Client) parent.operators.find(user.id)
    end
  end
end
```

The following attributes will be accessible in a Permission class:

* *subject*  - the resource that is currently being tested for authorization
* *parent* - the parent of the authorization when resource is nested
* *user* - the user accessing the resource
* *klass* - the resource class
* *action* - the action that triggered the authorization

Keep in mind that the permission object is being instanciated to do authorization, and not the class.
You can extend the Trust::Permissions with more functionality if needed.

You can also create aliases for actions. We have defined a predefined set of aliases. See Trust::Permissions.action\_aliases.
Processing of aliases are done in such way that permissions per action is expanded when the permissions are loaded, so thif you define :update when declaring the permissions, there will be one permission for :update and one for :edit


### Apply access control in controller

Place _trusted_ in your controller after the user has been identified. Someshing like this:

``` Ruby
class AccountsController < ApplicationController
  login_required
  trusted
end
```

The trusted statement will set up 3 before_filters in your controller:
  
``` Ruby
before_filter :set_user
before_filter :load_resource
before_filter :access_control
```

Trust assumes that current\_user is accessible. The user object must repond to the method role\_symbols which should return an array of one or more roles for the user.

Handling access denied situations in your controller. Implement the following in your Application controller:

``` Ruby
class ApplicationController < ActionController::Base
  rescue_from Trust::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
    # or some other redirect
  end
end
```

### Define associations in your controller

For nested resources you can easily define the associations using _belongs\_to_ like this:

``` Ruby
class AccountsController < ApplicationController
  login_required
  belongs_to :client
  trusted
end
```

You can specify as many associations as you like.


## The can? and permits? method

The can? method is accessible from controller and views. Here are some coding examples:

In controller or views you will use can?

``` Ruby
can? :edit                          # does the current user have permission to edit the current resource? 
                                    # If there is a nested resource, the parent is automatically associated
can? :edit, @customer               # does the current user have permission to edit the given customer? 
                                    # Parent is also passed on here.
can? :edit, @account, @client       # is current user allowed to edit the account associated with the client?
```

On ActiveRecord objects you will use permits?

``` Ruby
@customer.permits? :edit            # does the current user have permission to edit the given customer?
Customer.permits? :create, @client  # does the current user have permission to create customers?
```

## Instance variables

The filter :load\_resource will automatically load the instance for the resource in the controller. It will by default use the controller\_path to determine the name of the instance variable. Here are a couple of examples:

``` Ruby
UsersController => @user
Account::CreditsController => @account_credit
```

If it is a nested resource, it will also instantiate the parent class, using the namedefined in belongs\_to to determine the name. E.g. if you have defined belongs_to :client, it will look for the parameter :client\_id and perform a find like Client.find(client\_id). Finding the resource will be done through the association between the two, such as client.accounts.find(id)

You can override the naming by specifying model\_name before trusted, like this

``` Ruby
class AccountsController < ApplicationController
  login_required
  model_name :wackount
  trusted
end
```

If you want to override the name with namespacing then

``` Ruby
class Account::CreditsController < ApplicationController
  login_required
  model_name :"account/wreckit"
  trusted
end
```

You can also access the instances in a generic manner if you like. Use following statements:
  
``` Ruby
resource.instance => accesses the instance variable
resource.parent   => accesses the parent instance
```

You can even assign these if you like. The resource is also exposed as helper, so you can access it in views.




## Overriding defaults

If you prefer to use some other user reference than current_user you can override the method set_user like this in your controller:

``` Ruby
def set_user
  Trust::Authorization.user = Thread[:current_user]
end
```

You may choose not to use all the before\_filers setup by Trust, and rather use your own implementation. This is entirely up to you.
You may want to have a look at Trust::Controller to see what it is doing to make your own customizations.




        
