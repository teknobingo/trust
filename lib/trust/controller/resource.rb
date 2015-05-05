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
  module Controller
    # = Trust::Controller::Resource 
    #
    # Collects information about the current resource and relations. 
    # Handles the loading of the resource and its possible parent, i.e. setting the relevant instance variables
    # It assumes the name of the resource is built on the controllers name, but this can be overridden in your
    # controller by setting the +model+
    #
    # Examples:
    #
    #    # controller name AccountsController
    #    resource.instance # => @account
    #
    #    # controller name Customer::AccountsController
    #    resource.instance # => @customer_account
    #
    class Resource
      
      delegate :logger, :to => Rails
      attr_reader :properties, :params, :action
      attr_reader :info, :parent_info, :relation
      attr_reader :params_handler

      def initialize(controller, properties, action_name, params, request) # nodoc
        @action = action_name.to_sym
        @params_handler = {}
        @controller, @properties, @params = controller, properties, params
        @info = extract_resource_info(properties.model, params)
        if properties.has_associations?
          @parent_info = extract_parent_info(properties.associations, params, request)
          self.parent = parent_info.object if parent_info
        end
        @relation = @info.relation(@parent_info)
      end

      # Returns the instance variable in the controller
      def instance
        @controller.instance_variable_get(:"@#{instance_name}")
      end
      
      # Sets the instance variable
      #
      # Normally set by +load+.
      # You can access this method from the resource object.
      #
      # ==== Example
      #
      #    resource.instance = Account.find_by_number(123456)
      def instance=(instance)
        @controller.instance_variable_set(:"@#{instance_name}", instance)
      end      
      
      # Returns the parameters for the instance (Rails 3)
      #
      # ==== Example
      #
      #     # in AccountsController
      #     resource.instance_params  # same as params[:account]
      def instance_params
        info.params
      end
      
      # Returns strong parameters for the instance (Rails 4)
      # This call will take advantage of the spesified in permissions.
      # If no such permissions is defined, it will fall back to instance_params
      #
      # ==== Example
      #
      #     # assume the following permissions defined
      #     class Account < Default
      #       require :account
      #       permit :number, :amount
      #     end
      #
      #     # in AccountsController
      #     resource.strong_params  # same as params.require(:account).permit(:number, :amount)
      #
      #     # as a new action
      #     resource.strong_params(true)  # same as params.fetch(:account, {}).permit(:number, :amount)
      # 
      def strong_params(new_action = new_action?)
        if params_handler.size > 0
          if params_handler[:require]
            new_action ? 
              params.fetch(params_handler[:require], {}).permit(params_handler[:permit]) : 
              params.require(params_handler[:require]).permit(params_handler[:permit])
          else
            params.permit(params_handler[:permit])
          end
        else
          instance_params
        end
      end

      if Rails.version.split('.')[0].to_i < 4
        def strong_params(new_action = new_action?)
          instance_params
        end
      end

      # Returns the parents instance variable when you use +belongs_to+ for nested routes
      def parent
        parent_name && @controller.instance_variable_get(:"@#{parent_name}")
      end
      
      # Sets the parent instance variable
      def parent=(instance)
        @controller.instance_variable_set(:"@#{parent_name}", instance) if parent_name
      end

      # Returns the cinstance variable for ollection
      def instances
        @controller.instance_variable_get(:"@#{plural_instance_name}")
      end

      # Sets the instance variable for collection
      #
      # You may want to set this variable in your index action, we do not yet support loading of collections
      def instances=(instances)
        @controller.instance_variable_set(:"@#{plural_instance_name}", instances)
      end

      # Returns either the instances or the instance. 
      #
      # We have found that this can be useful in some implementation patterns
      def instantiated
        instances || instance
      end

      # Returns the class for the resource
      def klass
        info.klass
      end

      # Returns a collection that can be used for index, new and creation actions
      #
      # See Trust::Controller::ResourceInfo.collection which controls the behavior of this method.
      def collection(instance = nil)
        @info.collection(@parent_info, instance)
      end
      
      # true if action is a collection action
      def collection_action?
        @collection_action ||= properties.collection_action?(action)
      end
      
      # true if action is a collection action
      def member_action?
        @member_action ||= properties.member_action?(action)
      end
      
      # Returns a nested resource if parent is set
      def nested
        parent ? [parent, instance] : [instance]
      end
      
      # true if action is a new action
      def new_action?
        @new_action ||= properties.new_action?(action)
      end
      
      # Loads the resource
      #
      # See Trust::Controller::Properties which controls the behavior of this method.
      #
      # It will normally find the instance variable for existing object or initialize them as new.
      # If using nested resources and +belongs_to+ has been declared in the controller it will use the 
      # parent relation if found.
      def load
        if new_action?
#         logger.debug "Trust.load: Setting new: class: #{klass} strong_params: #{strong_params.inspect}"
          self.instance ||= relation.new(strong_params)
          @controller.send(:build, action) if @controller.respond_to?(:build, true)
        elsif properties.member_actions.include?(action)
#          logger.debug "Trust.load: Finding parent: #{parent.inspect}, relation: #{relation.inspect}"
          self.instance ||= relation.find(params[:id] || params["#{relation.name.underscore}_id".to_sym])
          @controller.send(:build, action) if @controller.respond_to?(:build,true)
        else # other outcome would be collection actions
#          logger.debug "Trust.load: Parent is: #{parent.inspect}, collection or unknown action."
        end 
      end
      
      # Returns the name of the instance for the resource
      #
      # ==== Example
      #
      #     # in AccountsController
      #     resource.instance_name  # => :account
      def instance_name
        info.name
      end
      
      # Assigns the handler for safe parameters
      #
      # This is normally set by the controller during authorization
      # If you want to set this your self it should
      def params_handler=(handler)
        @params_handler = handler
      end
      
      
      
      # Returns the plural name of the instance for the resource
      #
      # ==== Example
      #
      #     # in AccountsController
      #     resource.plural_instance_name  # => :accounts
      def plural_instance_name
        info.plural_name
      end
      
      # Returns the name of the parent resource
      #
      # ==== Example
      #
      #     # in AccountsController where belongs_to :customer has been declared
      #     resource.parent_name  # => :customer
      def parent_name
        parent_info && parent_info.name
      end
      
      # Returns the association name with the parent
      def association_name
        parent_info && info.association_name(parent_info)
      end
    private
      def extract_resource_info(model, params) # nodoc
        ResourceInfo.new(model, params)
      end
      
      def extract_parent_info(associations, params, request) #nodoc
        ParentInfo.new(associations, params, request)
      end      
    end

    # = ResorceInfo 
    #
    # resolves information about the resource accessed in action controller
    #
    # === Examples in PeopleController (simple case)
    # 
    #   resource.info.klass => Person
    #   resource.info.params => {:person => {...}}       # fetches the parameters for the resource
    #   resource.info.name => :person
    #   resource.info.plural_name => :people
    #   resource.info.path => 'people'                   # this is the controller_path
    #
    # === Examples in Lottery::AssignmentsController (with name space)
    # 
    #   resource.info.klass => Lottery::Assignment
    #   resource.info.params => {:lottery_assignment => {...}}
    #   resource.info.name => :lottery_assignment
    #   resource.info.plural_name => :lottery_assignments
    #   resource.info.path => 'lottery/assignments'      # this is the controller_path
    #
    # === Examples in ArchiveController (with inheritance) 
    # Assumptions on routes:
    #
    #   resources :archives
    #   resources :secret_acrvives, :controller => :archives
    #   resources :public_acrvives, :controller => :archives
    #
    # === Examples below assumes that the route secret_arcives is being accessed at the moment
    # 
    #   resource.info.klass => Archive
    #   resource.info.params => {:secret_archive => {...}}
    #   resource.info.name => :archive
    #   resource.info.plural_name => :archives
    #   resource.info.path => 'archive'                   # this is the controller_path
    #   resource.info.real_class => SecretArchive         # Returns the real class which is accessed at the moment
    #
    class Resource::Info
      attr_reader :klass, :params, :name, :path, :real_class
      
      def params #:nodoc:
        @data
      end
   
    protected
      def self.var_name(klass)  #:nodoc:
        klass.to_s.underscore.tr('/','_').to_sym
      end
      def var_name(klass)  #:nodoc:
        self.class.var_name(klass)
      end
    end
    
    # = Resource::ResorceInfo 
    # 
    # Resolves the resource in subject
    # (see #Resource::Info)
    class Resource::ResourceInfo < Resource::Info

      def initialize(model, params)  #:nodoc:
        @path, params = model, params
        @klass = model.to_s.classify.constantize
        @name = model.to_s.singularize.underscore.gsub('/','_').to_sym
        ptr = @klass.descendants.detect do |c|
          params.key? var_name(c)
        end || @klass
        @real_class = ptr
        @data = params[var_name(ptr)]
      end

      # Returns the plural name of the resource
      def plural_name
        @plural_name ||= path.underscore.tr('/','_').to_sym
      end

      # Returns an accessor for association. Tries with full name association first, and if that does not match, tries the demodularized association.
      #
      # === Explanation
      #
      #   Assuming 
      #     resource is instance of Lottery::Package #1 (@lottery_package)
      #     association is Lottery::Prizes
      #     if association is named lottery_prizes, then that association is returned
      #     if association is named prizes, then that association is returned
      #   
      def relation(associated_resource)
        if associated_resource && associated_resource.object
          associated_resource.object.send(association_name(associated_resource))
        else
          klass
        end
      end
      
      # Returns a collection that can be used for index, new and creation actions.
      #
      # If specifying an instance, returns the full path for that instance. Can be used when not using shallow routes
      #
      # === Example
      #
      #   Assumption
      #     resource is instance of Lottery::Package #1 (@lottery_package)
      #     association is Lottery::Prizes
      #     if association is named lottery_prizes, then [@lottery_package, :lottery_prizes] is returned
      #     if association is named prizes, then [@lottery_package, :prizes] is returned
      #     if you specify an instance, then [@lottery_package, @prize] is returned
      #
      def collection(associated_resource, instance = nil)
        if associated_resource && associated_resource.object
          [associated_resource.object, instance || association_name(associated_resource)]
        else
          klass
        end
      end
      
      def association_name(associated_resource) # :nodoc
        name = associated_resource.as || plural_name
        associated_resource.object.class.reflect_on_association(name) ? name : klass.to_s.demodulize.underscore.pluralize        
      end
    end

    # = Resource::ParentInfo 
    # 
    # Resolves the parent resource in subject
    # (see #Resource::ResourceInfo)
    class Resource::ParentInfo < Resource::Info
      attr_reader :object,:as
      def initialize(resources, params, request)
        ptr = resources.detect do |r,as|
          @klass = classify(r)
          @as = as
          ([@klass] + @klass.descendants).detect do |c|
            @name = c.to_s.underscore.tr('/','_').to_sym
            unless @id = request.path_parameters["#{@name}_id".to_sym]
              # see if name space handling is necessary
              if c.to_s.include?('::')
                @name = c.to_s.demodulize.underscore.to_sym
                @id = request.path_parameters["#{@name}_id".to_sym]
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
