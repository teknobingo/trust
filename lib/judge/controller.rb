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
          include JudgeInstanceMethods
          before_filter :set_user, options
          before_filter :load_resource, options
          before_filter :access_control, options
        end
      end
    end
    
    module JudgeInstanceMethods
      def set_user
        Judge::Authorization.user = current_user
      end
      
      def resource
        @resource ||= Judge::Controller::Resource.new(self, self.class.properties, action_name, params, request)
      end
      
      def load_resource
        resource.load
      end
      
      def access_control
        Judge::Authorization.authorize!(action_name, resource.instance || resource.klass, resource.parent)
      end
    end
  end
end