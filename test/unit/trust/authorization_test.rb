require 'test_helper'

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
      class ::TestBase < ActiveRecord::Base
      end
      class ::TestDescendant < TestBase
      end
      def authorizing_class(klass)
        Trust::Authorization.send(:authorizing_class, klass)
      end
    end
    should 'return associated Authorization class if it exists' do
      class ::Permissions::TestBase < Trust::Permissions
      end
      assert_equal ::Permissions::TestBase, authorizing_class(::TestBase)
    end
    should 'return Authorization::Default if no assocated Authorization class' do
      assert_equal ::Permissions::Default, authorizing_class(::TestDescendant)
    end
    should 'return parent Authorization if specified and none exist for the class' do
      class ::Permissions::TestBase < Trust::Permissions
      end
      assert_equal ::Permissions::TestBase, authorizing_class(::TestDescendant)
    end
  end
  
  context 'authorize?' do
    setup do
      class Validator
      end
      class TestAuthorizing
        def initialize(user, action, klass, object, parent)
          Validator.values user, action, klass, object, parent
        end
      end
      Trust::Authorization.expects(:user).returns(:user)
      TestAuthorizing.any_instance.expects(:authorized?).returns(true)
      Trust::Authorization.expects(:authorizing_class).with(String).returns(TestAuthorizing)
    end
    should 'instanciate authorizing class and set correct parameters for object' do
      Validator.expects(:values).with(:user, :action, String, 'object_or_class', :parent)
      assert Trust::Authorization.authorized?('action', 'object_or_class', :parent)
    end
    should 'instanciate authorizing class and set correct parameters for class' do
      Validator.expects(:values).with(:user, :action, String, nil, :parent)
      assert Trust::Authorization.authorized?('action', String, :parent)
    end
  end

  context 'authorize!' do
    should 'call access_denied! unless authorized?' do
      Trust::Authorization.expects(:access_denied!).once
      Trust::Authorization.expects(:authorized?).with(1, 2, 3).returns(false)
      Trust::Authorization.authorize!(1,2,3)
    end
    should 'call access_denied! if authorized?' do
      Trust::Authorization.expects(:access_denied!).never
      Trust::Authorization.expects(:authorized?).with(1, 2, 3).returns(true)
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
