require 'test_helper'

class Judge::PermissionsTest < ActiveSupport::TestCase
  setup do
    @base = Judge::Permissions
  end
  context 'class_attributes' do
    should 'have default values' do
      assert_equal @base.permissions, {}
      assert_equal @base.action_aliases, {
        read: [:index, :show],
        create: [:create, :new],
        update: [:update, :edit]
        }
    end
  end

  context 'class method' do
    setup do
      class TestAuth < Judge::Permissions
      end
    end
    context 'can' do
      should 'set permissions correctly' do
        TestAuth.role :tester do
          TestAuth.can :hi
          TestAuth.can :wink
        end
        # verfy that permissions are structured correctly
        expected = {:tester => [[:hi, {}],[:wink, {}]]}
        assert_equal expected, TestAuth.permissions
        expected = {}
        # Verify that parent class is not affected
        assert_equal expected, @base.permissions, "#{@base.name} was modified"
        # Verify that aliases are expanded
        expected = {:tester => [[:hi, {}],[:wink, {}],[:create, {}],[:new, {}]]}
        TestAuth.role :tester do
          TestAuth.can :create
        end
        assert_equal expected, TestAuth.permissions
        # Verify support for multiple roles
        expected = {:tester => [[:hi, {}],[:wink, {}],[:create, {}],[:new, {}]], :manager => [[:hi, {}]]}
        TestAuth.role :manager do
          TestAuth.can :hi
        end
        assert_equal expected, TestAuth.permissions
      end
      should 'raise exception if not executed within a role block' do
        assert_raises Judge::NoBlockError do
          TestAuth.can :bu
        end
      end
    end
    context 'expand_aliases' do
      should 'expand one alias' do
        assert_equal [:update, :edit], @base.send(:expand_aliases, :update)
      end
      should 'expand multiple aliases' do
        assert_equal [:update, :edit, :create, :new], @base.send(:expand_aliases, [:update, :create])
      end
      should 'return action if there are no aliases' do
        assert_equal [:hi], @base.send(:expand_aliases, :hi)
      end
    end
    context 'role' do
      should 'require block' do
        assert_raises ArgumentError do
          TestAuth.role
        end
      end
    end
  end
  
  context 'instance method' do
    setup do
      @object = @base.new(:user, :wink, :klass, :object, :parent)
    end
    context 'authorized?' do
      setup do
        def authorized?
          @object.send(:authorized?)
        end
      end
      should 'by default be false' do
        @user = stub(:role_symbols => [])
        @object.stubs(:user).returns(@user)
        assert !authorized?
      end
      should 'require explicit permission' do
        @user = stub(:role_symbols => [:manager])
        @object.stubs(:user).returns(@user)
        @base.expects(:permissions).returns({:tester => []})
        assert !authorized?
        @base.expects(:permissions).returns({:manager => [[:hi, {}]]})
        assert !authorized?
        @base.expects(:permissions).returns({:manager => [[:wink, {}]]})
        assert authorized?
      end
      should 'handle multiple roles' do
        @user = stub(:role_symbols => [:tester, :manager])
        @object.stubs(:user).returns(@user)
        @base.stubs(:permissions).
          returns({:tester => [[:hi, {}],[:wink, {}]]}).then.
          returns({:manager => [[:hi, {}],[:wink, {}]]})
        assert authorized?        
        assert authorized?
      end
    end
    context 'eval_expr' do
      setup do
        def eval_expr(options)
          @object.send(:eval_expr, options)
        end
      end
      should 'raise exception if condition not supported' do
        assert_raises Judge::UnsupportedCondition do
          eval_expr(:unsupported => true)
        end
      end
      should 'support multiple conditions' do
        assert !eval_expr(:if => true, :unless => true)
        assert !eval_expr(:if => false, :unless => true)
        assert !eval_expr(:if => true, :unless => true)
        assert eval_expr(:if => true, :unless => false)
      end
      should 'support the following conditions' do
        assert eval_expr(:if => true)
        assert !eval_expr(:unless => true)
      end
      should 'support symbol expression' do
        @object.expects(:hello).returns(true)
        assert eval_expr(:if => :hello)
      end
      should 'support proc expression' do
        assert eval_expr(:if => Proc.new { true })
        assert eval_expr(:if => lambda { true })
      end
    end
  end
end