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
      attr_accessor :model_name
      attr_accessor :associations
      attr_accessor :new_actions
      attr_accessor :member_actions
      attr_accessor :collection_actions
      
      def initialize(controller)
        @controller = controller
        @associations = []
        @new_actions = [:new, :create]
        @member_actions = [:show, :edit, :update, :destroy]
        @collection_actions = [:index]
      end

      class << self
        def instantiate(controller)
          if controller.superclass.respond_to?(:properties) 
            object = controller.superclass.properties.clone
            object.instance_variable_set(:@controller, controller)
          else
            object = new(controller)
          end
          object
        end
      end

      def model_name(name = nil)
        @model_name ||= (name && name.to_s) || controller.controller_path
      end
      
      def model_class
        model_name.to_s.classify.constantize
      end
      
      # Specify associated resources
      # Example:
      #   belongs_to :lottery
      #   belongs_to :table, :card_game
      #
      def belongs_to(*resources)
        raise ArgumentError, "You must specify at least one resource after belongs_to" unless resources
        # options = resources.extract_options!
        @associations += Array.wrap(resources)
        logger.debug "#{@model_name || controller.controller_path} belongs_to #{@belongs_to}"
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
