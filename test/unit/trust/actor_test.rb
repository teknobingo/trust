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

require 'test_helper'

class Trust::ActorTest < ActiveSupport::TestCase
  class User
    include ::Trust::Actor
  end
  
  context 'can?' do
    setup do
      @user = User.new
      @account = Account.new
    end
    should 'support calls to authorized? on instance' do
      Trust::Authorization.expects(:authorized?).with(:manage,@account, :by => @user, :parent => nil)
      @user.can? :manage, @account
      Trust::Authorization.expects(:authorized?).with(:manage,@account, :by => @user, :parent => :foo)
      @user.can? :manage, @account, :foo
      Trust::Authorization.expects(:authorized?).with(:manage,@account, :by => @user, :parent => :foo)
      @user.can? :manage, @account, :parent => :foo
      Trust::Authorization.expects(:authorized?).with(:manage,@account, :by => @user, :parent => :foo)
      @user.can? :manage, @account, :for => :foo
    end
  end
end
