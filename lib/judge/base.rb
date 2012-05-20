module Judge
  class Base
    include InheritableAttribute
    attr_reader :user, :action, :klass, :object, :parent
    inheritable_attr :permissions
    class_attribute :action_aliases, :instance_writer => false, :instance_reader => false
    self.permissions = {}
    self.action_aliases = {
      read: [:index, :show],
      create: [:create, :new],
      update: [:update, :edit]
      }

    def initialize(user, action, klass, object, parent)
      @user, @action, @klass, @object, @parent = user, action, klass, object, parent
    end
    
  protected
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
    
    def eval_expr(options)
      options.collect do |oper, expr|
        res = case expr
        when Symbol then send(expr)
        when Proc   then expr.call
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
      def role(roles, &block)
        raise ArgumentError unless block_given?
        @perms = []
        @in_role_block = true
        yield
        @in_role_block = false
        Array.wrap(roles).each do |role|
          self.permissions[role] ||= []
          self.permissions[role] += @perms
        end
      end
      alias :roles :role
      
      # Defines permission
      #   action - can be an alias or an action of some kind
      #   options - :if/:unless :symbol or proc that will be called to evaluate an expression
      def can(actions, options = {})
        raise NoBlockError unless @in_role_block
        @perms += expand_aliases(actions).collect { |action| [action, options] }
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