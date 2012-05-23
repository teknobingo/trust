module Trust
  module Controller
    autoload :Resource,           'trust/controller/resource'
    autoload :Properties,         'trust/controller/properties'
    
    extend ActiveSupport::Concern
        
    module ClassMethods
      def properties
        @properties ||= Trust::Controller::Properties.instantiate(self)
      end      
      
      delegate :belongs_to, :actions, :model_name, :to => :properties

      def trusted(options = {})
        module_eval do
          include TrustInstanceMethods
          before_filter :set_user, options
          before_filter :load_resource, options
          before_filter :access_control, options
          helper_method :can?
        end
      end
    end
    
    module TrustInstanceMethods
      def set_user
        Trust::Authorization.user = current_user
      end
      
      def resource
        @resource ||= Trust::Controller::Resource.new(self, self.class.properties, action_name, params, request)
      end
      
      def load_resource
        resource.load
      end
      
      def access_control
        Trust::Authorization.authorize!(action_name, resource.instance || resource.klass, resource.parent)
      end

      def can?(action_name, subject = resource.instance || resource.klass, parent = resource.parent)
        Trust::Authorization.authorize!(action_name, subject, parent)
      end
    end
  end
end
