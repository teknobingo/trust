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
  # = Trust Authorization
  class Authorization
    
    # raised if attempting to do resource related operations and resource is not passed on to the Authorization object
    class ResourceNotLoaded < StandardError; end
    
    class << self
      
      # Returns true if user is authorized to perform +action+ on +object+ or +class+.
      #
      # Options:
      # 
      # * +:parent+ - the parent class to associate the subject with, can also be specified after the object
      #   or class. If +parent+ is given, +parent+ may be tested in the implemented Permissions class.
      #   +:parent+ is also aliased to +:for+.
      #
      # * +:by+ - Spoecify an actor instead of the user currently logged in 
      # 
      # This method is called by the +can?+ method in Trust::Controller, and is normally 
      # not necessary to call directly.
      def authorized?(action, object_or_class_or_resource, *args)
        new(action, object_or_class_or_resource, *args).authorized?
      end
      
      # Tests if user is authorized to perform +action+ on +object+ or +class+, with the 
      # optional parent and raises Trust::AccessDenied exception if not permitted.
      # If user is authorized, sets the params_handler for the resource.
      #
      # Options:
      #
      # * +:parent+ - the parent class to associate the subject with, can also be specified after the object
      #   or class. If +parent+ is given, +parent+ may be tested in the implemented Permissions class.
      #   +:parent+ is also aliased to +:for+.
      #
      # * +:by+ - Spoecify an actor instead of the user currently logged in 
      # 
      # * +:message+ - The message to be passed onto the AccessDenied exception class      
      #
      # This method is used by the +access_control+ method in Trust::Controller
      def authorize!(action, object_or_class_or_resource, *args)
        new(action, object_or_class_or_resource, *args).authorize!
      end
      
      # Returns the current +user+ being used in the authorization process
      def user
        Thread.current["current_user"] 
      end
      
      # Sets the current +user+ to be used in the authorization process.
      # The +user+ is thread safe.
      def user=(user)
        Thread.current["current_user"] = user
      end
    end
    
    attr_reader :authorization, :action, :resource, :klass, :object, :parent, :actor
    
    delegate :user, to: :class
    
    def initialize(action, resource_object_or_class, *args)
      options = args.extract_options!
      @action = action.to_sym
      if resource_object_or_class.is_a? Trust::Controller::Resource
        @resource = resource_object_or_class
        @klass = resource.klass
        @object = resource.instance
        @actor = options[:by] || user
        @parent = resource.parent
      else
        @parent = options[:parent] || options[:for] || args.first
        @actor = options[:by] || user
        if resource_object_or_class.is_a? Class
          @klass = resource_object_or_class
          @object = nil
        else
          @klass = resource_object_or_class.class
          @object = resource_object_or_class
        end
      end
      auth = authorizing_class
      # Rails.logger.debug "Trust: Authorizing class for #{klass.name} is #{auth.name}"
      @authorization = auth.new(@actor, @action, @klass, @object, @parent)
    end

    def access_denied!(message = nil, action = nil, subject = nil, parent = nil) #:nodoc:
      raise AccessDenied.new(message, action, subject)
    end

    def authorize!
      if perm = permissions
        resource.params_handler = perm
      else
        access_denied!(nil, action, object || klass)
      end
    end

    def authorized?
      !!permissions
    end
    
    def instance_loaded(instance)
      @authorization.subject = instance
    end
    
    # Preloads resource require and permit attributes, so that new objects can be initialized properly
    # raises ResourceNotLoaded if Authorization object was not initialized with a resource object
    def preload
      raise ResourceNotLoaded unless resource
      resource.params_handler = authorization.preload
    end
    
    def permissions
      authorization.authorized?
    end
    

  private
    def authorizing_class #:nodoc:
      auth = nil
      klass.ancestors.each do |k|
        break if k == ::ActiveRecord::Base
        begin
          auth = "::Permissions::#{k}".constantize
          break
        rescue
        end
      end
      auth || ::Permissions::Default
    end
  
  end
end
