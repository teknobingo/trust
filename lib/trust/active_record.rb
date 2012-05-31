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
  module ActiveRecord
    extend ActiveSupport::Concern
# = Trust::ActiveRecord extension
# Extends ActiveRecord with the +permits?+ and +ensure_permitted!+ method on class and instances
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
#    # If current user is permitted to update the given customer, update it
#    if @customer.permits? :update
#      @customer.save
#    end
#    
#    # Raise an exception if user is not permitted to update the given customer, else save it
#    @customer.ensure_permitted! :update 
#    @customer.save

    included do
      include ClassMethods
    end
    
    module ClassMethods
      def permits?(action, parent = nil)
        Trust::Authorization.authorized?(action, self, parent)
      end
      def ensure_permitted!(action, parent = nil)
        Trust::Authorization.authorize!(action, self, parent)
      end
    end
  end
end
