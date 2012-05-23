require 'test_helper'

class Trust::PermissionsTest < ActiveSupport::TestCase
  setup do
    class Fund < Trust::Permissions
    end
    @base = Fund
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
      class TestAuth < Trust::Permissions
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
        assert_raises Trust::NoBlockError do
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
        assert_raises Trust::UnsupportedCondition do
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

  context 'inheritance' do
    should 'clone deeply' do
      class TestBaseAuth < Trust::Permissions
      end
      TestBaseAuth.role :tester do
        TestBaseAuth.can :hi, :if => :ho
        TestBaseAuth.can :wink
      end

      class TestInheritedAuth < TestBaseAuth
      end
      TestInheritedAuth.role :tester do
        TestInheritedAuth.can :foo, :if => :foobar
        TestInheritedAuth.can :bar
      end
      expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}]]}
      assert_equal expect, TestBaseAuth.permissions
      expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}],[:foo, {:if => :foobar}],[:bar, {}]]}
      assert_equal expect, TestInheritedAuth.permissions
    end
    should 'accumulate inherited permissions' do
      class TestBaseAuth2 < Trust::Permissions
      end
      TestBaseAuth2.role :tester do
        TestBaseAuth2.can :hi, :if => :ho
        TestBaseAuth2.can :wink
      end

      class TestOverride < TestBaseAuth2
      end
      TestOverride.role :tester do
        TestOverride.can :hi, :if => :ha
      end
      expect = {:tester => [[:hi, {:if=>:ho}], [:wink, {}], [:hi, {:if=>:ha}]]}
      assert_equal expect, TestOverride.permissions
    end
  end
end
