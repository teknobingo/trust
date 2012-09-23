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
  # = Trust::ActiveModel extension
  #
  # Extends ActiveRecord with the +permits?+ and +ensure_permitted!+ method on class and instances
  # If using Mongoid same features are included there
  #
  # Options:
  #
  # * +:parent+ - Specifies that the persmision should be tested in the context of a parent 
  # * +:by+ - Specifies an actor to be used instead of the currently logged in user
  #
  # ==== Examples
  #
  #    # If current user is permitted to create customers, create it
  #    if Customer.permits? :create
  #      Customer.create attributes
  #    end
  #    
  #    # If current user is permitted to create accounts for the given customer, create it
  #    if Account.permits? :create, @customer
  #      Account.create attributes
  #    end
  #    
  #    # If the specified actor is permitted to create accounts for the given customer, create it
  #    if Account.permits? :create, @customer, :by => @actor
  #      Account.create attributes
  #    end
  #    
  #    # Raise an exception if user is not permitted to update the given customer, else save it
  #    @customer.ensure_permitted! :update
  #    @customer.save
  #    
  #    # Raise an exception if the specified user is not permitted to update the given customer, else save it
  #    @customer.ensure_permitted! :update, :by => @actor
  #    @customer.save
  module ActiveModel
    extend ActiveSupport::Concern

    included do
      include ClassMethods
    end
    
    module ClassMethods
      def permits?(action, *args)
        Trust::Authorization.authorized?(action, self, *args)
      end
      def ensure_permitted!(action, *args)
        Trust::Authorization.authorize!(action, self, *args)
      end
    end
  end
end
