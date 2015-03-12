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
  # = Trust Controller
  module Controller
    autoload :Resource,           'trust/controller/resource'
    autoload :Properties,         'trust/controller/properties'
    
    extend ActiveSupport::Concern
        
    module ClassMethods
      
      # Returns the controller Trust::Controller::Properties.
      # If no properties are instantiated, it will be instantiated
      # 
      # == Delegated methods
      #
      # The following methods are delegated to properties. See Trust::Controller::Properties for details
      # * +belongs_to+ - define one or more associations to parents
      # * +actions+ - acion definitions outside the restful actions
      # * +model+ - Redefine the model used in the controller (if it's name does not match the 
      #   controller_path)
      #
      def properties
        @properties ||= Trust::Controller::Properties.instantiate(self)
      end      
      
      delegate :belongs_to, :actions, :model, :to => :properties

      # Enables authorization in controller
      #
      # +trustee+ accepts +:off+ or a hash of +callback+ options such as +:except+ and +:only+
      #
      # +trustee+ automatically calls the class methods: +set_user+, +load_resource+ and +access_control+
      # +trustee+ accepts +:off+ for +set_user+, +load_resource+ and +access_control+ individually
      #
      # +trustee+ will raise an Trust::AccessDenied exception if the user is not permitted the action
      # 
      # ==== Examples
      #
      #   # enable permission check for all restful actions
      #   class AccountsController < ApplicationController
      #     login_required
      #     trustee
      #   end
      #
      #   # disable all permission check
      #   class PasswordController < ApplicationController
      #     # assuming login_required and trustee has been in your application controller
      #     trustee :off
      #   end
      #
      #   # enable permission check and loading for only :new and :create action
      #   class AccountsController < ApplicationController
      #     login_required
      #     trustee :only => [:new, :create]
      #   end
      #
      #   # enable permission check for all restful actions, but without loading resources
      #   class AccountsController < ApplicationController
      #     login_required
      #     trustee :load_resource => :off
      #     model :objects
      #   end
      #
      # ==== Caching Trust::AccessDenied exception
      # Normally an exception handler is included in the ApplicationController. Example:
      #   class ApplicationController < ActionController::Base
      #     rescue_from Trust::AccessDenied do |exception|
      #       redirect_to root_url, :alert => exception.message
      #     end
      #   end
      def trustee(*args)
        module_eval do
          include TrustInstanceMethods
          set_user *args
          load_resource *args
          access_control *args
          helper_method :can?, :resource
        end
      end
      
      # Enable or disable +before_filter+ callback for setting the current user
      #
      # === Arguments:
      #
      #  +:off+ - switch callback off
      #  +:only+ - only include these actions
      #  +:except+ - except these actions
      def set_user(*args)
        _filter_setting(:set_user, *args)
      end
      
      # Enable or disable +before_filter+ callback for setting the loading resource
      #
      # === Arguments:
      #
      #  +:off+ - switch callback off
      #  +:only+ - only include these actions
      #  +:except+ - except these actions
      def load_resource(*args)
        _filter_setting(:load_resource, *args)
      end
      # Enable or disable +before_filter+ callback for setting the access control, i.e. verifying permissions
      # for the logged in user
      #
      # === Arguments:
      #
      #  +:off+ - switch callback off
      #  +:only+ - only include these actions
      #  +:except+ - except these actions
      def access_control(*args)
        _filter_setting(:access_control, *args)
      end
      
    private
      def _filter_setting(method, *args)
        options = args.extract_options!
        skip_before_filter method
        unless args.include? :off or options[method] == :off
          before_filter method, options
        end
      end
    end
    
    module TrustInstanceMethods
      # Returns the controller Trust::Controller::Properties.
      # If no properties are instantiated, it will be instantiated.
      # 
      # == Delegated methods
      #
      # The following methods are delegated to properties. See Trust::Controller::Properties for details
      # * +belongs_to+ - define one or more associations to parents
      # * +actions+ - acion definitions outside the restful actions
      # * +model+ - Redefine the model used in the controller (if it's name does not match the 
      #   controller_path)
      #
      def properties
        self.class.properties
      end
      
      # Sets the current user. It assumes +current_user+ is defined.
      #
      # This method is triggered as a callback on +before_filter+.
      # You may override this method.
      #
      # ==== Example
      # 
      #   def set_user
      #     Trust::Authorization.user = Thread[:current_user]
      #   end
      def set_user
        Trust::Authorization.user = current_user
      end

      # Returns the Trust::Controller::Resource resource for the controller.
      #
      # Available as a helper in views.
      # See {Trust::Controller::Resource} for relevant methods.
      def resource
        @resource ||= Trust::Controller::Resource.new(self, self.class.properties, action_name, params, request)
      end
      
      # Loads the resource which basically means loading the instance and eventual parent defined through +belongs_to+
      #
      # This method is triggered as a callback on +before_filter+
      # See {Trust::Controller::Resource} for more information
      def load_resource
        if resource.new_action?
          authorization.preload
          authorization.instance_loaded resource.load # need to set instance on authorizing object
        else
          resource.load
        end
      end
      
      # Performs the actual access_control.
      #
      # This method is triggered as a callback on +before_filter+
      def access_control
        authorization.authorize!
      end

      # maintains access to the authorization object
      def authorization
        @authorization ||= Trust::Authorization.new(action_name, resource)
      end

      # Tests for current users permissions.
      #
      # If access control is not sufficient in controller, you may use this method.
      # Also available as a helper in views.
      #
      # ==== Examples
      #   +can? :edit+                          # does the current user have permission to edit the current resource? 
      #                                         # If there is a nested resource, the parent is automatically associated
      #   +can? :edit, @customer+               # does the current user have permission to edit the given customer? 
      #                                         # Parent is also passed on here.
      #   +can? :edit, @account, @client+       # is current user allowed to edit the account associated with the client?
      def can?(action_name, subject = resource.instance || resource.relation.new, parent = resource.parent)
        Trust::Authorization.authorized?(action_name, subject, parent)
      end
    end
  end
end
