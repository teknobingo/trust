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
          helper_method :can?, :resource
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
