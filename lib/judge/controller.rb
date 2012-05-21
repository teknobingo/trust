module Judge
  module Controller
    autoload :Resource,           'judge/controller/resource'
    autoload :Properties,         'judge/controller/properties'
    
    extend ActiveSupport::Concern
        
    module ClassMethods
      def properties
        @properties ||= Judge::Controller::Properties.instantiate(self)
      end      
      
      delegate :belongs_to, :actions, :model_name, :to => :properties
      
      def judged(options = {})
        module_eval do
          before_filter :set_user, options
          before_filter :resolve_resources, options
          before_filter :access_control, options
        end
      end
    end
    
    module InstanceMethods
      def set_user
        Judge::Authorization.user = current_user
      end
      
      def resource
        @resource ||= Judge::Resource.new(self, self.class.properties, action_name, params, request)
      end
      
      def resource_instance=(instance)
        instance_variable_set("@#{instance_name}", instance)
      end
      
      def resource_instance
        instance_variable_get("@#{instance_name}")
      end
      
      def resolve_resources
        resource # all we need to do is to ensure resource is instantiated
      end
    end
  end
end