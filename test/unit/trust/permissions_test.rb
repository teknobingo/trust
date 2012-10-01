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
        update: [:update, :edit],
        manage: [:index, :show, :create, :new, :update, :edit, :destroy]
        }
    end
  end

  context 'class method' do
    context 'can' do
      should 'work without using block' do
        assert_equal ({:can => [[:hi, {}]]}), @base.can(:hi)
        assert_equal ({:can => [[:hi, {}], [:wink, {}]]}), @base.can(:hi, :wink)
        assert_equal ({:can => [[:hi, {:if => true}], [:wink, {:if => true}]]}), @base.can(:hi, :wink, :if => true)
        @base.class_variable_set(:@@can_expressions, 0)
      end
    end
    context 'can with role block' do
      setup do
        class TestAuth < Trust::Permissions
        end
      end
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
    end
    context 'can assigning role wihtout block' do
      setup do
        class TestRoleCan < Trust::Permissions
        end
      end
      should 'set permissions correctly' do
        TestRoleCan.role :tester, :manager, TestRoleCan.can(:hi, :wink, :if => true)
        expected = {:tester => [[:hi, {:if => true}],[:wink, {:if => true}]], :manager => [[:hi, {:if => true}],[:wink, {:if => true}]]}
        assert_equal expected, TestRoleCan.permissions
        TestRoleCan.role :support, TestRoleCan.can(:update)
        expected[:support] = [[:update, {}], [:edit, {}]]
        assert_equal expected, TestRoleCan.permissions
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
    should 'raise exception if not assigned to a role' do
      flunk if TestRoleCan.class_variable_get(:@@can_expressions) != 0
      TestRoleCan.can :bu
      assert_equal 1, TestRoleCan.class_variable_get(:@@can_expressions)
      assert_raises Trust::RoleAssigmnentMissing do
        TestRoleCan.role :buh do
        end
      end
      TestRoleCan.can :bu
      TestRoleCan.can :bu
      assert_equal 2, TestRoleCan.class_variable_get(:@@can_expressions)
      assert_raises Trust::RoleAssigmnentMissing do
        TestRoleCan.role :buh
      end
    end
  end
  
  context 'instance method' do
    setup do
      @subject = @base.new(:user, :wink, :klass, :subject, :parent)
    end
    context 'authorized?' do
      setup do
        def authorized?
          @subject.send(:authorized?)
        end
      end
      should 'by default be false' do
        @user = stub(:role_symbols => [])
        @subject.stubs(:user).returns(@user)
        assert !authorized?
      end
      should 'require explicit permission' do
        @user = stub(:role_symbols => [:manager])
        @subject.stubs(:user).returns(@user)
        @base.expects(:permissions).returns({:tester => []})
        assert !authorized?
        @base.expects(:permissions).returns({:manager => [[:hi, {}]]})
        assert !authorized?
        @base.expects(:permissions).returns({:manager => [[:wink, {}]]})
        assert authorized?
      end
      should 'handle multiple roles' do
        @user = stub(:role_symbols => [:tester, :manager])
        @subject.stubs(:user).returns(@user)
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
          @subject.send(:eval_expr, options)
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
        @subject.expects(:hello).returns(true)
        assert eval_expr(:if => :hello)
      end
      should 'support proc expression' do
        assert eval_expr(:if => Proc.new { true })
        assert eval_expr(:if => lambda { true })
        assert eval_expr(:unless => lambda { false })
      end
    end
  end
  
  context 'accessing accessors in Permission instance' do
    setup do
      class Account < Trust::Permissions
        role :tester do
          can :test_user,  :if => Proc.new { user.name == 'mcgormic' }
          can :test_action,  :if => lambda { action == :test_action }
          can :test_klass,   :if => lambda { klass == :klass }
          can :test_subject, :if => lambda { subject == :subject }
          can :test_parent,  :if => lambda { parent == :parent }
          can :test_failure, :if => lambda { failure == :failure }
        end
      end
      @user = stub(:name => 'mcgormic', :role_symbols => [:tester])
    end
    should 'expose accessors' do
      %w(user action klass subject parent).each do |attr|
        @perm = Account.new(@user, :"test_#{attr}", :klass, :subject, :parent)
        assert @perm.authorized?, "test_#{attr} failed"
      end
      assert_raises NameError do
        @perm = Account.new(@user, :test_failure, :klass, :subject, :parent)
        assert @perm.authorized?
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
    
    context 'with cannot' do
      should  'not accept options' do
        class TestCannnotArgumentError < Trust::Permissions
        end
        assert_raises ArgumentError do
          TestCannnotArgumentError.cannot :do, :options => true
        end
      end
      should 'revoke permissions' do
        class TestBaseAuth3 < Trust::Permissions
          role :tester, :friend do
            can :hi, :if => :ho
            can :wink
          end
        end
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}]], :friend => [[:hi, {:if => :ho}],[:wink, {}]]}
        assert_equal expect, TestBaseAuth3.permissions
        class TestCannot < TestBaseAuth3
          role :tester, cannot(:wink)
          role :friend do
            cannot :hi
          end
        end
        expect = {:tester => [[:hi, {:if => :ho}]], :friend => [[:wink, {}]]}
        assert_equal expect, TestCannot.permissions
      end
    end
    context 'with enforce' do
      should 'override previous cans' do
        class TestBaseAuth4 < Trust::Permissions
          role :tester, :friend do
            can :hi, :if => :ho
            can :wink
          end
        end
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}]], :friend => [[:hi, {:if => :ho}],[:wink, {}]]}
        assert_equal expect, TestBaseAuth4.permissions
        class TestEnforce < TestBaseAuth4
          role :tester, can(:wink, :enforce => true, :if => :yo)
          role :friend do
            can :hi, :enforce => true, :if => :sure
          end
        end
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {:if => :yo}]], :friend => [[:wink, {}],[:hi, {:if => :sure}]]}
        assert_equal expect, TestEnforce.permissions
        # Parent permissions should not be affected
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}]], :friend => [[:hi, {:if => :ho}],[:wink, {}]]}
        assert_equal expect, TestBaseAuth4.permissions
      end
    end
  end
end
