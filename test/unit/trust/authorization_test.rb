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

class TestBase < ActiveRecord::Base
end
class TestDescendant < TestBase
end
class TestParentLess < ActiveRecord::Base
end

class Permissions::TestBase < Trust::Permissions
end

class Trust::AuthorizationTest < ActiveSupport::TestCase
  context 'user' do
    should 'be set in thread' do
      Trust::Authorization.user = 1
      assert_equal 1, Thread.current["current_user"]
    end
    should 'be retrieved from thread' do
      Thread.current["current_user"] = 2
      assert_equal 2, Trust::Authorization.user
    end
  end
  
  context 'authorizing_class' do
    setup do
      def authorizing_class(klass)
        Trust::Authorization.send(:authorizing_class, klass)
      end
    end
    should 'return associated Authorization class if it exists' do
      assert_equal ::Permissions::TestBase, authorizing_class(::TestBase)
    end
    should 'return Authorization::Default if no assocated Authorization class' do
      assert_equal ::Permissions::Default, authorizing_class(::TestParentLess)
    end
    should 'return parent Authorization if specified and none exist for the class' do
      assert_equal ::Permissions::TestBase, authorizing_class(::TestDescendant)
    end
  end
  
  context 'authorize?' do
    setup do
      class Validator
      end
      class TestAuthorizing # overrides authorizing_class
        def initialize(user, action, klass, object, parent)
          Validator.values user, action, klass, object, parent
        end
      end
      TestAuthorizing.any_instance.stubs(:authorized?).returns(true)
      Trust::Authorization.expects(:authorizing_class).with(String).returns(TestAuthorizing)
    end
    should 'instanciate authorizing class and set correct parameters for object' do
      Trust::Authorization.expects(:user).returns(:user)
      Validator.expects(:values).with(:user, :action, String, 'object_or_class', :parent)
      assert Trust::Authorization.authorized?('action', 'object_or_class', :parent)
    end
    should 'instanciate authorizing class and set correct parameters for class' do
      Trust::Authorization.expects(:user).returns(:user)
      Validator.expects(:values).with(:user, :action, String, nil, :parent)
      assert Trust::Authorization.authorized?('action', String, :parent)
    end
    should 'allow actor to override user with actor' do
      Validator.expects(:values).with('TheActor', :action, String, nil, :parent)
      assert Trust::Authorization.authorized?('action', String, :parent, :by => 'TheActor')      
      Trust::Authorization.expects(:authorizing_class).with(String).returns(TestAuthorizing)
      Validator.expects(:values).with('TheActor', :action, String, nil, nil)
      assert Trust::Authorization.authorized?('action', String, :by => 'TheActor')      
    end
    should 'support option for :parent' do
      Trust::Authorization.expects(:user).returns(:user)
      Validator.expects(:values).with(:user, :action, String, nil, 'parent')
      assert Trust::Authorization.authorized?('action', String, :parent => 'parent')
    end
    should 'support option alias for :parent, namely :for' do
      Trust::Authorization.expects(:user).returns(:user)
      Validator.expects(:values).with(:user, :action, String, nil, 'parent')
      assert Trust::Authorization.authorized?('action', String, :for => 'parent')
    end
  end

  context 'authorize!' do
    should 'call access_denied! unless authorized?' do
      Trust::Authorization.expects(:access_denied!).once
      Trust::Authorization.expects(:authorized?).with(1, 2, 3, {}).returns(false)
      Trust::Authorization.authorize!(1,2,3)
    end
    should 'call access_denied! if authorized?' do
      Trust::Authorization.expects(:access_denied!).never
      Trust::Authorization.expects(:authorized?).with(1, 2, 3, {}).returns(true)
      Trust::Authorization.authorize!(1,2,3)
    end    
  end
  
  context 'access_denied!' do
    should 'raise exception' do
      assert_raises Trust::AccessDenied do
        Trust::Authorization.access_denied!
      end
    end
  end
  
end
