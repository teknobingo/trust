module Judge
  module Controller
    class Properties
      
      attr_reader :controller
      attr_accessor :model_name
      attr_accessor :belongs_to
      attr_accessor :new_actions
      attr_accessor :member_actions
      attr_accessor :collection_actions
      
      def initialize(controller)
        @controller = controller
        @belongs_to = []
        @new_actions = [:new, :create]
        @member_actions = [:show, :edit, :update, :destroy]
        @collection_actions = [:index]
      end

      class << self
        def instantiate(controller)
          if controller.superclass.respond_to?(:properties) 
            object = controller.superclass.properties.clone
            object.instace_variable_set(:@controller, controller)
          else
            object = new(controller)
          end
          object
        end
      end

      def model_name
        @model_name ||= controller.controller_path
      end
      
      # Specify associated resources
      # Example:
      #   belongs_to :lottery
      #
      def belongs_to(*resources)
        raise ArgumentError, "You must specify at least one resource after belongs_to" unless resources
        options = resources.extract_options!
        @belongs_to += Array.wrap(resources)
        logger.debug "#{controller_path} belongs_to #{self.properties.belongs_to}"
      end
      
      # actions(options)
      # Options
      #  :new => actions        # specify new actions - default id :new, :create
      #  :member => actions     # specify member actions - default is :show, :edit, :update, :destroy
      #  :collection => actions # specify collection actions - default is :index
      #  :except => actions     # removes any standard actions
      #  :only => actions       # selects only the standard actions specifiec
      #  :add => {options}      # to add options, eg  :add => {:new => :confirm} 
      #
      def actions(options)
        if add = options[:add]
          self.new_actions += Array.wrap(add[:new]) if add[:new]
          self.member_actions += Array.wrap(add[:member]) if add[:member]
          self.collection_actions += Array.wrap(add[:collection]) if add[:collection]
        end
        self.new_actions = Array.wrap(options[:new]) if options[:new]
        self.member_actions = Array.wrap(options[:member]) if options[:member]
        self.collection_actions = Array.wrap(options[:collection]) if options[:collection]
        if options[:only]
          only = Array.wrap(options[:only])
          self.new_actions &= only
          self.member_actions &= only
          self.collection_actions &= only
        end
        if options[:except]
          except = Array.wrap(options[:except])
          self.new_actions -= except
          self.member_actions -= except
          self.collection_actions -= except
        end
      end
    end
  end
end
