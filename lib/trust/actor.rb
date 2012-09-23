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
  # = Trust::Actor extension
  #
  # Include this module if you want to check if an actor can act upon a specific subject
  #
  # ==== Examples
  #
  #    # If the @actor can create customers, create it
  #    if @actor.can? :create, Customer
  #      Customer.create attributes
  #    end
  #    
  #    # If @actor can create accounts for the given customer, create it
  #    if @actor.can? :create, Account, @customer
  #      Account.create attributes
  #    end
  #    # It is also possible to make code more descripting for the same as above
  #    if @actor.can? :create, Account, :parent => @customer     # or, ...
  #    if @actor.can? :create, Account, :for => @customer
  #    
  module Actor
    extend ActiveSupport::Concern

    def can?(action, subject, *args)
      options = args.extract_options!
      options[:parent] ||= args.first || options.delete(:for)
      options[:by] = self
      Trust::Authorization.authorized?(action, subject, options)
    end
  end
end
