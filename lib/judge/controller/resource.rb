module Judge
  module Controller
    class Resource
      attr_reader :properties, :params, :action
      attr_reader :resource_info, :parent_info, :relation

      def initialize(controller, properties, action_name, params, request)
        @action = action_name.to_sym
        
        @properties, @params = properties, params
        @resource_info = InstanceInfo.new(properties.model_name, params)
        if properties.has_associations?
          @parent_info = ParentInfo.new(properties.belongs_to, params, request)
          self.parent = @parent_info.object
        end
        @relation = @resource_info.relation(@parent_info)        
      end
      
      # Controller accessors
      def instance=(instance)
        @controller.instance_variable_set("@#{instance_name}", instance)
      end
      
      def instance
        @controller.instance_variable_get("@#{instance_name}")
      end
      
      def parent=(instance)
        @controller.instance_variable_set("@#{parent_name}", instance)        
      end

      def parent
        @controller.instance_variable_get("@#{parent_name}")
      end
      
      def load
        if properties.new_actions.include?(action)
          logger.debug "Setting new: resource_info.params: #{resource_info.params.inspect}"
          self.instance ||= relation.new(resource_info.params)
          @controller.send(:build, action) if @controller.respond_to(:build)
        elsif properties.member_actions.include?(action)
          logger.debug "Finding parent: #{parent.inspect}, relation: #{relation.inspect}"
          self.instance ||= relation.find(params[:id])
          @controller.send(:build, action) if @controller.respond_to(:build)
        end # other outcome would be collection actions
      end
    end

    # Resorce resolves information about the resource accessed in action controller
    # This is automatically included in ActionController as long as the method resource is accessed
    #
    # Examples in PeopleController (simple case)
    # ===
    #   resource.klass => Person
    #   resource.params => {:person => {...}}       # fetches the parameters for the resource
    #   resource.name => :person
    #   resource.plural_name => :people
    #   resource.path => 'people'                   # this is the controller_path
    #
    # Examples in Lottery::AssignmentsController (with name space)
    # ===
    #   resource.klass => Lottery::Assignment
    #   resource.params => {:lottery_assignment => {...}}
    #   resource.name => :lottery_assignment
    #   resource.plural_name => :lottery_assignments
    #   resource.path => 'lottery/assignments'      # this is the controller_path
    #
    # Examples in ArchiveController (with inheritance) 
    # Assumptions on routes:
    #   resources :archives
    #   resources :secret_acrvives, :controller => :archives
    #   resources :public_acrvives, :controller => :archives
    # examples below assumes that the route secret_arcives is being accessed at the moment
    # ===
    #   resource.klass => Archive
    #   resource.params => {:secret_archive => {...}}
    #   resource.name => :archive
    #   resource.plural_name => :archives
    #   resource.path => 'archive'                   # this is the controller_path
    #   resource.real_class => SecretArchive         # Returns the real class which is accessed at the moment
    #
    
    class Resource::Info
      attr_reader :klass, :params, :name, :path, :real_class
      
      def params
        @data
      end
   
    protected
      def var_name(klass)
        klass.to_s.underscore.tr('/','_').to_sym
      end
    end
    

    class Resource::InstanceInfo < Resource::Info

      def initialize(model_name, params)
        @path, params = model_name, params
        @klass = model_name.classify.constantize
        @name = model_name.singularize.underscore.gsub('/','_').to_sym
        ptr = @klass.descendants.detect do |c|
          params.key? var_name(c)
        end || @klass
        @real_class = ptr
        @data = params[var_name(ptr)]
      end

      def plural_name
        @plural_name ||= path.underscore.tr('/','_').to_sym
      end

      # returns an accessor for association. Tries with full name association first, and if that does not match, tries the demodularized association.
      #
      # Explanation:
      #   Assuming 
      #     resource is instance of Lottery::Package #1 (@lottery_package)
      #     association is Lottery::Prizes
      #     if association is named lottery_prizes, then that association is returned
      #     if association is named prizes, then that association is returned
      #   
      def relation(associated_resource)
        if associated_resource && associated_resource.object
          associated_resource.klass.reflect_on_association(plural_name) ? 
            associated_resource.object.send(plural_name) : associated_resource.object.send(klass.to_s.demodulize.underscore.pluralize)
        else
          klass
        end
      end
    end

    class Resource::ParentInfo < Resource::Info
      attr_reader :object
      def initialize(resources, params, request)
        ptr = resources.detect do |r|
          @klass = classify(r)
          ([@klass] + @klass.descendants).detect do |c|
            @name = c.to_s.underscore.tr('/','_').to_sym
            unless @id = request.symbolized_path_parameters["#{@name}_id".to_sym]
              # see if name space handling is necessary
              if c.to_s.include?('::')
                @name = c.to_s.demodulize.underscore.to_sym
                @id = request.symbolized_path_parameters["#{@name}_id".to_sym]
              end
            end
            @id
          end
          @id
        end
        if ptr
          @object = @klass.find(@id)
        else
          @klass = @name = nil
        end
        @data = params[var_name(ptr)]
      end

      def object?
        !!@object
      end

      def real_class
        @object && @object.class
      end
    private
      def classify(resource)
        case resource
        when Symbol, String
          resource.to_s.classify.constantize
        else
          resource
        end
      end
    end
  end
end