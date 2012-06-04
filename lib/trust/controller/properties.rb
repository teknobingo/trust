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
    class Properties
      delegate :logger, :to => Rails
      attr_reader :controller
      attr_accessor :model
      attr_accessor :associations
      attr_accessor :new_actions
      attr_accessor :member_actions
      attr_accessor :collection_actions
      
      def initialize(controller, properties) # nodoc
        @controller = controller
        @model = controller.controller_path
        if properties
          @associations = properties.associations.dup
          @new_actions = properties.new_actions.dup
          @member_actions = properties.member_actions.dup
          @collection_actions = properties.collection_actions.dup
        else
          @associations = {}
          @new_actions = [:new, :create]
          @member_actions = [:show, :edit, :update, :destroy]
          @collection_actions = [:index]
        end
      end

      class << self
        # returns a controller properties object
        # ensures controller properties are instantiated in a correct manner and that inheritance is supported
        def instantiate(controller)
          new(controller, controller.superclass.instance_variable_get(:@properties))
        end
      end

      # returns or sets the model to be used in a controller
      # If not set, the controller_path is used
      # You can override the model to be accessed in a controller by setting the model
      #
      # ==== Example
      #
      #    # You have a controller which inherits from a generic controller and it has not the same name. Below
      #    model :account # will assume that the class to be Account and instance variables to be @account/@accounts
      #
      #    # name spaced models
      #    model :"customer/account"
      #
      def model(name = nil)
        @model = name.to_s if name
        @model
      end
      
      # Returns the class for the model
      def model_class
        model.to_s.classify.constantize
      end
      
      # Specify associated resources (nested resources)
      # Example:
      #   belongs_to :lottery
      #   belongs_to :table, :card_game
      #   belongs_to :card_game, :as => :bridge
      #
      def belongs_to(*resources)
        raise ArgumentError, "You must specify at least one resource after belongs_to" unless resources
        logger.debug "#{@model} belongs_to #{resources.inspect}"
        options = resources.extract_options!
        resources.each do |resource|
          @associations[resource] = options[:as]
        end
      end
      
      def has_associations?
        @associations.size > 0
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
