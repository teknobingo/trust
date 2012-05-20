module Judge
  module ActionController
    autoload :Resource,           'judge/action_controller/resource'
    autoload :AssociatedResource, 'judge/action_controller/resource'
    
    extend ActiveSupport::Concern
    
    module ClassMethods
      def judged(options = {})
        module_eval do
          include JudgeInstanceMethods
          before_filter :set_user, options
          before_filter :resolve_instance, options
          before_filter :access_control, options
        end
      end
    end
    
    module JudgeInstanceMethods
    protected
      def set_user
        Judge::Authorization.user = current_user
      end
      
      def resource_instance=(object)
        instance_variable_set("@#{instance_name}", instance)
      end
      
      def resource_instance
        instance_variable_get("@#{instance_name}")
      end
      
      def parent_instance
        @parent_instance ||= NYI
      end
      def access_control
        Judge::Authorization.authorize! action_name, resource_instance, parent_instance
      end
      
      def resolve_object
        action = action_name.to_sym

        logger.debug "Resolve object: Resource class: #{resource.klass}, action: #{action_name}" +  (associated_object && ", belongs_to: #{associated.klass}" || '')
        if new_actions.include?(action)
          logger.debug "Setting new: resource.params: #{resource.params.inspect}"
          set_instance relation.new(resource.params)
          build action
        elsif !collection_actions.include?(action)
          logger.debug "Finding object: associated_object: #{associated_object.inspect}, relation: #{relation.inspect}"
          set_instance resource_instance  || resource.klass.find(params[:id])
          build action
        end # other outcome would be index
      end
    
    private 
      def instance_name
        @options[:instance_name] || name
      end
    end
  end
end