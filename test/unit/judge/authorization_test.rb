require 'test_helper'

class Judge::AuthorizationTest < ActiveSupport::TestCase
  context 'user' do
    should 'be set in thread' do
      Judge::Authorization.user = 1
      assert_equal 1, Thread.current["current_user"]
    end
    should 'be retrieved from thread' do
      Thread.current["current_user"] = 2
      assert_equal 2, Judge::Authorization.user
    end
  end
  
  context 'authorizing_class' do
    setup do
      class ::TestBase < ActiveRecord::Base
      end
      class ::TestDescendant < TestBase
      end
      def authorizing_class(klass)
        Judge::Authorization.send(:authorizing_class, klass)
      end
    end
    should 'return associated Authorization class if it exists' do
      class ::Authorization::TestBase < Judge::Base
      end
      assert_equal ::Authorization::TestBase, authorizing_class(::TestBase)
    end
    should 'return Authorization::Default if no assocated Authorization class' do
      assert_equal ::Authorization::Default, authorizing_class(::TestDescendant)
    end
    should 'return parent Authorization if specified and none exist for the class' do
      class ::Authorization::TestBase < Judge::Base
      end
      assert_equal ::Authorization::TestBase, authorizing_class(::TestDescendant)
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
      Judge::Authorization.expects(:user).returns(:user)
      TestAuthorizing.any_instance.expects(:authorized?).returns(true)
      Judge::Authorization.expects(:authorizing_class).with(String).returns(TestAuthorizing)
    end
    should 'instanciate authorizing class and set correct parameters for object' do
      Validator.expects(:values).with(:user, :action, String, 'object_or_class', :parent)
      assert Judge::Authorization.authorized?('action', 'object_or_class', :parent)
    end
    should 'instanciate authorizing class and set correct parameters for class' do
      Validator.expects(:values).with(:user, :action, String, nil, :parent)
      assert Judge::Authorization.authorized?('action', String, :parent)
    end
  end

  context 'authorize!' do
    should 'call access_denied! unless authorized?' do
      Judge::Authorization.expects(:access_denied!).once
      Judge::Authorization.expects(:authorized?).with(1, 2, 3).returns(false)
      Judge::Authorization.authorize!(1,2,3)
    end
    should 'call access_denied! if authorized?' do
      Judge::Authorization.expects(:access_denied!).never
      Judge::Authorization.expects(:authorized?).with(1, 2, 3).returns(true)
      Judge::Authorization.authorize!(1,2,3)
    end    
  end
  
  context 'access_denied!' do
    should 'raise exception' do
      assert_raises Judge::AccessDenied do
        Judge::Authorization.access_denied!
      end
    end
  end
  
end
