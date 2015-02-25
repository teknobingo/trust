# Copyright (c) 2012 Bingo Entreprenøren AS
# Copyright (c) 2012 Teknobingo Scandinavia AS
# Copyright (c) 2012 Knut I. Stenmark
# Copyright (c) 2012 Patrick Hanevold
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Trust
  # = Trust Permissions
  #
  # Permissions should be specified in a separate file in you app/model directory. The file could look like this:
  #
  #   module Permissions
  #     class Default < Trust::Permissions
  #       ...
  #     end
  #     ...
  #   end
  #
  # The above is the minimum required definitions that must exist in you file. +Default+ will be used if no classes
  # match the permissions requested, so the +Default+ class definition is mandatory.
  #
  # If you want to separate the permissions into separate files that is ok. Then you shoud place these files in the 
  # /app/model/permissions directory.
  #
  # == Defining permisions
  #
  # The basic rules is to define classes in the Permissions module that matches your models.
  # Here are some examples:
  # * +Project+ should have a matching class +Permissions::Project+
  # * +Account+ should have a matching class +Permissions::Account+
  # * +Account:Credit+ may have a matching class +Permissions::Account::Credit+, but if its inheriting from
  #   +Account+ and no special handling is necessary, it is not necessary to create the permissions class.
  #
  # == Using inheritance
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
  # == Action aliases
  #
  # You can define aliases for actions. You do this by setting the +action_aliases+ attribute on Trust::Permissions class
  # Example:
  #   Trust::Permissions.action_aliases = {
  #      read: [:index, :show],
  #      create: [:create, :new]
  #      }
  #
  # Keep in mind that all permissions are expanded upon declaration, so when using the +can?+ method you must refer to
  # the actual action and not the alias. The alias will never give a positive permission.
  #
  # == Accessors
  #
  # Accessors that can be used when testing permissions:
  # * +user+ - the user currently logged in
  # * +action+ - the action request from the controller such as :edit, or the action tested from helper or
  #   from the object itself when using +ActiveRecord::can?+ is being used.
  # * +subject+ - the object that is being tested for permissions. This may be a an existing object, a new object
  #   (such as for +:create+ and +:new+ action), or nil if no object has been instantiated.
  # * +parent+ - the parent object if in a nested route, specified by +belongs_to+ in the controller.
  # * +klass+ - the class of involed in the request. It can be a base class or the real class, depending on
  #   your controller design.
  #
  # == Defining your own accessors or instance methods
  #
  # You can easily define your own accessors in the classes. These can be helpful when declaring permissions.
  #
  # === Example:
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
  # In the above example closed is testing on the subject to see if it is closed. The permission is referring to 
  # this method when evaluated.
  # Keep in mind that you must refer to the +subject+, as you do not access the inctance of the object directly.
  #
  class Permissions
    
    include InheritableAttribute
    attr_reader :user, :action, :klass, :subject, :parent
    inheritable_attr :permissions
    inheritable_attr :member_permissions
    class_attribute :action_aliases, :instance_writer => false, :instance_reader => false
    self.permissions = {}
    self.member_permissions = {}
    self.action_aliases = {
      # read: [:index, :show],
      # create: [:create, :new],
      # update: [:update, :edit],
      # manage: [:index, :show, :create, :new, :update, :edit, :destroy]
      }
    @@can_expressions = 0
  
    # Initializes the permission object
    #
    # calling the +authorized?+ method on the instance later will test for the authorization.
    #
    # == Parameters:
    #
    #   +user+ - user object, must respond to role_symbols
    #   +action+ - action, such as :create, :show, etc. Should not be an alias
    #   +klass+ - the class of the subject.
    #   +subject+ - the subject tested for authorization
    #   +parent+ - the parent object, normally declared through belongs_to
    #
    # See {Trust::Authorization} for more details
    #
    def initialize(user, action, klass, subject, parent)
      @user, @action, @klass, @subject, @parent = user, action, klass, subject, parent
    end
  
    # Returns true if the user is authorized to perform the action
    def authorized?
      trace 'authorized', 0, "@user: #{@user.inspect}, @action: #{@action.inspect}, @klass: #{@klass.inspect}, @subject: #{@subject.inspect}, @parent: #{@parent.inspect}"
      user && (authorize_by_member_role? || authorize_by_role?)
    end

    # Implement this in your permissions class if using membership roles
    #
    # One example is that you have teams or projects that have members with role and you want to 
    # Authorize against that role instead of any of the roles associated with the user directly
    #
    # === Example:
    #
    #   class Sprint < Trust::Permissions
    #     member_role :scrum_master, can(:update)
    #     def members_role()
    #       @members_role ||= subject.memberships.where(user_id: user.id).first.role_symbol
    #     end
    def members_role()
      {}
    end
    
    # Returns subject if subject is an instance, otherwise parent
    # 
    def subject_or_parent
      (subject.nil? || subject.is_a?(Class)) ? parent : subject
    end
  private
    def eval_expr(options) #:nodoc:
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
        when :if then res
        when :unless then !res
        else
          raise UnsupportedCondition, expr.inspect
        end
      end.all?
    end
    
    def authorize_by_role?
      trace 'authorize_by_role?', 0, "#{user.try(:name)}"
      user.role_symbols.any? do |role| 
        trace 'authorize_by_role?', 1, "#{role}"
        if p = permissions[role]
          trace 'authorize_by_role?', 2, "permissions: #{p.inspect}"          
          has_permissions? p
        end
      end
    end
    
    # Checks is a member is authorized
    # You will need to implement members_role in permissions yourself
    def authorize_by_member_role?
      m = members_role
      trace 'authorize_by_member_role?', 0, "#{user.try(:name)}:#{m}"
      p = member_permissions[m]
      trace 'authorize_by_role?', 1, "permissions: #{p.inspect}"      
      p && has_permissions?( p)
    end
    
    def has_permissions?(permissions = {})
      permissions.any? do |act, opt|
        act == action && (opt.any? ? eval_expr(opt) : true)
      end
    end
    
    def trace(method, indent = 0, msg = nil)
      return unless Trust.log_level == :trace
      Rails.logger.debug "Trust::Permissions.#{method}: #{"\t" * indent}#{msg}"
    end
    
    class << self
      # Assign permissions to one or more roles.
      #
      # You may call role or roles, they are the same function like +role :admin+ or +roles :admin, :accountant+
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
      #
      def role(*roles, &block)
        self.permissions = _role(self.permissions, *roles, &block)
      end
      alias :roles :role
      
      # Assign permissions to one or more roles on a member role.
      #
      # You may call member_role or member_roles, they are the same function like 
      #   +member_role :scrum_master+ or +member_roles :scrum_master, :product_owner+
      #
      # When using this feature, your permission class must respond to members_rols, and return only one role
      #
      # See {Trust::Permissions.role} for definition
      # See {Trust::Permissions.members_role} for how to implement this method
      #
      def member_role(*roles, &block)
        self.member_permissions = _role(self.member_permissions, *roles, &block)
      end
      alias :member_roles :member_role
      
      def _role(existing_permissions, *roles, &block)
        if block_given?
          if @@can_expressions > 0
            @@can_expressions = 0
            raise RoleAssigmnentMissing 
          end
          @perms = {:can => [], :cannot => []}
          @in_role_block = true
          yield
          @in_role_block = false
          perms = @perms
        else
          if @@can_expressions > 1
            @@can_expressions = 0
            raise RoleAssigmnentMissing 
          end
          perms = roles.extract_options!
          unless perms.size >= 1 && (perms[:can] || perms[:cannot])
            raise ArgumentError, "Must have a block or a can or a cannot expression: #{perms.inspect}"
          end
          @@can_expressions = 0
        end
        roles.flatten.each do |role|
          existing_permissions[role] ||= []
          if perms[:cannot] && perms[:cannot].size > 0
            perms[:cannot].each do |p|
              existing_permissions[role].delete_if { |perm| perm[0] == p  }
            end
          end
          if perms[:can] && perms[:can].size > 0
            existing_permissions[role] += perms[:can]
          end
        end
        existing_permissions
      end
  
      # Defines permissions
      #
      # === Arguments
      #
      #   action - can be an alias or an actions of some kind
      #   options - control the behavior of the permission
      #
      # === Options
      #   +:if/:unless+ - :symbol or proc that will be called to evaluate an expression
      #   +enforce+ - set to true to enforce the permission, delete any previous grants given from parent classes. Most meaningful in
      #               combination with +:if+ and +:unless+ options
      #
      # === Example
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
        enforce = options.delete(:enforce)
        p = expand_aliases(args).collect { |action| [action, options] }
        if @in_role_block
          @perms[:can] += p
          if enforce
            @perms[:cannot] = expand_aliases(args).collect { |action| action }
          end
        else
          @@can_expressions += 1
          perms = {:can => p }
          if enforce
            perms[:cannot] = expand_aliases(args).collect { |action| action }
          end
          return perms
        end
      end
      
      # Revokes permissions.
      #
      # Revokes any previous permissions given in parent classes. This cannot be used with conditions. See also +:enforce+ option
      # for +can+
      #
      # +can+ has presedence over +cannot+. In practice this means that in a block; +cannot+ statements are processed before +can+,
      # and any previously permissions granted are deleted. 
      # Another way to say this is; if you have +cannot :destroy+ and +can :destroy+, then all inheritied destroys will first be
      # deleted, and then the can destroy will be granted.
      #
      #
      # === Arguments
      # 
      #   action - actions to be revoked permissions for. Cannot be aliases
      #
      # === Example
      #
      #   module Permissions
      #     class Account < Trust::Permissions
      #       role :admin, :accountant do 
      #         can :read
      #         can :read
      #         can :update, :destroy, :unless => :closed?
      #       end
      #     end
      #
      #     class Account::Credit < Account
      #        role :accountant do
      #          cannot :destroy    # revoke permission to destroy
      #        end
      #     end
      #   end
      #
      def cannot(*args)
        options = args.extract_options!
        raise ArgumentError, "No options (#{options.inspect}) are allowed for cannot. It is just meaning less" if options.size > 0
        p = expand_aliases(args).collect { |action| action }
        if @in_role_block
          @perms[:cannot] += p
        else
          @@can_expressions += 1
          return {:cannot => p }
        end
      end
  
    private
      def expand_aliases(actions) #:nodoc:
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
