module Judge
  class Authorization
    class << self
      def authorized?(action, object_or_class, parent)
        if object_or_class.is_a? Class
          klass = object_or_class
          object = nil
        else
          klass = object_or_class.class
          object = object_or_class
        end
        # Identify which class to instanciate and then check authorization
        authorizing_class(klass).new(user, action.to_sym, klass, object, parent).authorized?
      end
      
      def authorize!(action, object_or_class, parent, message = nil)
        access_denied!(message, action, object_or_class, parent) unless authorized?(action, object_or_class, parent)
      end
      
      def access_denied!(message = nil, action = nil, subject = nil, parent = nil)
        raise AccessDenied.new(message, action, subject)
      end
      
      def user
        Thread.current["current_user"] 
      end
      def user=(user)
        Thread.current["current_user"] = user
      end
      
    private
      def authorizing_class(klass)
        auth = nil
        klass.ancestors.each do |k|
          break if k == ActiveRecord::Base
          begin
            auth = "Permissions::#{k}".constantize
            break
          rescue
          end
        end
        auth || ::Permissions::Default
      end
    end
  end
end