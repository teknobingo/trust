module Trust
  class Permissions
    # Permissions should be specified in a separate file in you app/model directory. The file could look like this:
    #
    #   module Permissions
    #     class Default < Trust::Permissions
    #       ...
    #     end
    #     ...
    #   end
    #
    # The above is the minimum required definitions that must exist in you file. <tt>Default</tt> will be used if no classes
    # match the permissions requested, so the <tt>Default</tt> class definition is mandatory.
    #
    # If you want to separate the permissions into separate files that is ok. Then you shoud place these files in the 
    # /app/model/permissions directory.
    #
    # === Defining permisions
    #
    # The basic rules is to define classes in the Permissions module that matches your models.
    # Here are some examples:
    # * <tt>Project</tt> should have a matching class <tt>Permissions::Project</tt>
    # * <tt>Account</tt> should have a matching class <tt>Permissions::Account</tt>
    # * <tt>Account:Credit</tt> may have a matching class <tt>Permissions::Account::Credit</tt>, but if its inheriting from
    #   <tt>Account</tt> and no special handling is necessary, it is not necessary to create the permissions class.
    #
    # === Using inheritance
    #
    # Inheritance is also fully supported, but should generally follow your own inheritance model
    # 
    #   module Permissions
    #     class Account < Default
    #       role :admin, :accountant do 
    #         ...
    #       end
    #     end
    #     class Account::Credit < Account
    #       ...
    #     end
    #   end
    #
    # === Action aliases
    #
    # You can define aliases for actions. You do this by setting the <tt>action_aliases</tt> attribute on Trust::Permissions class
    # Example:
    #   Trust::Permissions.action_aliases = {
    #      read: [:index, :show],
    #      create: [:create, :new]
    #      }
    #
    # Keep in mind that all permissions are expanded upon declaration, so when using the <tt>can?</tt> method you must refer to 
    # the actual action and not the alias. The alias will never give a positive permission.
    #
    # === Accessors
    #
    # Accessors that can be used when testing permissions:
    # * <tt>user</tt> - the user currently logged in
    # * <tt>action</tt> - the action request from the controller such as :edit, or the action tested from helper or 
    #   from the object itself when using <tt>ActiveRecord::can?</tt> is being used.
    # * <tt>subject</tt> - the object that is being tested for permissions. This may be nil if there is no object,
    #   such as for +:create+ and +:new+ action.
    # * <tt>parent</tt> - the parent object if in a nested route, specified by +belongs_to+ in the controller.
    # * <tt>klass</tt> - the class of involed in the request. It can be a base class or the real class, depending on
    #   your controller design.
    #
    # === Defining your own accessors or instance methods
    #
    # You can easily define your own accessors in the classes. These can be helpful when declaring permissions.
    # Example:
    #
    #   class Account < Trust::Permissions
    #     role :admin, :accountant do
    #       can :update, :unless => :closed?
    #     end
    #     def closed? 
    #       subject.closed?
    #     end
    #   end
    #
    # In the above example closed is tes´ting on the subject to see if it is closed. The permission is referring to 
    # this method when evaluated.
    # Keep in mind that you must refer to the +subject+, as you do not access the inctance of the object directly.
    #
    
    
    include InheritableAttribute
    attr_reader :user, :action, :klass, :subject, :parent
    inheritable_attr :permissions
    class_attribute :action_aliases, :instance_writer => false, :instance_reader => false
    self.permissions = {}
    self.action_aliases = {
      read: [:index, :show],
      create: [:create, :new],
      update: [:update, :edit],
      manage: [:index, :show, :create, :new, :update, :edit, :destroy]
      }
    @@can_expressions = 0
  
    def initialize(user, action, klass, subject, parent)
      @user, @action, @klass, @subject, @parent = user, action, klass, subject, parent
    end
  
    def authorized?
      authorized = nil
      user.role_symbols.each do |role|
        (permissions[role] || {}).each do |act, opt|
          if act == action
            break if (authorized = opt.any? ? eval_expr(opt) : true)
          end
        end
        break if authorized
      end
      authorized
    end
  
  protected
    def eval_expr(options)
      options.collect do |oper, expr|
        res = case expr
        when Symbol then send(expr)
        when Proc
          if expr.lambda?
            instance_exec &expr
          else
            instance_eval &expr
          end
        else
          expr
        end
        case oper
        when :if then expr
        when :unless then !expr
        else
          raise UnsupportedCondition, expr.inspect
        end
      end.all?
    end
  
    class << self
      # Assign permissions to one or more roles.
      # You may call role or roles, they are the same function like <tt>role :admin</tt> or <tt>roles :admin, :accountant</tt>
      #
      # There are two ways to call role, with or without block. If you want to set multiple permissions with different conditons
      # then you should use a block.
      #
      #   module Permissions
      #     class Account < Trust::Permissions
      #       role :admin, can(:manage, :audit)
      #     end
      #   end
      #
      # The above assigns the manage and audit permissions to admin.
      #
      #   module Permissions
      #     class Account < Trust::Permissions
      #       role :admin, :accountant do 
      #         can :read
      #         can :update
      #       end
      #     end
      #   end
      # 
      # The above permits admin and accountant to read accounts.
      def role(*roles, &block)
        if block_given?
          if @@can_expressions > 0
            @@can_expressions = 0
            raise RoleAssigmnentMissing 
          end
          @perms = []
          @in_role_block = true
          yield
          @in_role_block = false
          perms = @perms          
        else
          if @@can_expressions > 1
            @@can_expressions = 0
            raise RoleAssigmnentMissing 
          end
          options = roles.extract_options!
          raise ArgumentError, "Must have a block or a can expression" unless perms = options[:can]
          @@can_expressions = 0
        end
        roles.each do |role|
          self.permissions[role] ||= []
          self.permissions[role] += perms
        end
      end
      alias :roles :role
  
      # Defines permissions
      #   action - can be an alias or an actions of some kind
      #   options - :if/:unless :symbol or proc that will be called to evaluate an expression
      #
      #   module Permissions
      #     class Account < Trust::Permissions
      #       role :admin, :accountant do 
      #         can :read
      #         can :update, :unless => :closed?
      #       end
      #     end
      #   end
      # 
      # The above permits admin and accountant to read accounts, but can update only if the account is not closed.
      # In the example above a method is used to test data on the actual record when testing for permissions.
      def can(*args)
        options = args.extract_options!
        p = expand_aliases(args).collect { |action| [action, options] }
        if @in_role_block
          @perms += p
        else
          @@can_expressions += 1
          return {:can => p }
        end
      end
  
    private
      def expand_aliases(actions)
        expanded = []
        Array.wrap(actions).each do |action|
          if self.action_aliases[action]
            expanded += Array.wrap(self.action_aliases[action])
          else
            expanded << action
          end
        end
        expanded
      end
    end
  end
end
