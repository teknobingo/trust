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
      def authorized?(action, object_or_class, *args)
        options = args.extract_options!
        parent = options[:parent] || options[:for] || args.first
        actor = options[:by] || user
        if object_or_class.is_a? Class
          klass = object_or_class
          object = nil
        else
          klass = object_or_class.class
          object = object_or_class
        end
        # Identify which class to instanciate and then check authorization
        auth = authorizing_class(klass)
        # Rails.logger.debug "Trust: Authorizing class for #{klass.name} is #{auth.name}"
        auth.new(actor, action.to_sym, klass, object, parent).authorized?
      end
      
      # Tests if user is authorized to perform +action+ on +object+ or +class+, with the 
      # optional parent and raises Trust::AccessDenied exception if not permitted.
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
      def authorize!(action, object_or_class, *args)
        options = args.extract_options!
        parent = options[:parent] || options[:for] || args.first
        message = options[:message]
        access_denied!(message, action, object_or_class, parent) unless authorized?(action, object_or_class, parent, options)
      end
      
      def access_denied!(message = nil, action = nil, subject = nil, parent = nil) #:nodoc:
        raise AccessDenied.new(message, action, subject)
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
      
    private
      def authorizing_class(klass) #:nodoc:
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
end
