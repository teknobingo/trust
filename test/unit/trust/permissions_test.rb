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

  class Fund < Trust::Permissions
  end  
  
  setup do
    @base = Fund
    @action_aliases = Trust::Permissions.action_aliases
    Trust::Permissions.action_aliases[:update] = [:update, :edit]
  end
  teardown do
    Trust::Permissions.action_aliases = @action_aliases
  end
  context 'class_attributes' do
    should 'have default values' do
      assert_equal @base.permissions, {}
      assert_equal @base.member_permissions, {}
      assert_equal @base.action_aliases, {
        # read: [:index, :show],
        # create: [:create, :new],
        update: [:update, :edit],
        # manage: [:index, :show, :create, :new, :update, :edit, :destroy]
        }
    end
  end

  class TestAuth < Trust::Permissions
  end

  class TestMemberAuth < Trust::Permissions
  end
  
  class TestRoleCan < Trust::Permissions
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
        expected = {:tester=>[[:hi, {}], [:wink, {}], [:create, {}]]}
        TestAuth.role :tester do
          TestAuth.can :create
        end
        assert_equal expected, TestAuth.permissions
        # Verify support for multiple roles
        expected = {:tester => [[:hi, {}],[:wink, {}],[:create, {}]], :manager => [[:hi, {}]]}
        TestAuth.role :manager do
          TestAuth.can :hi
        end
        assert_equal expected, TestAuth.permissions
      end
    end
    context 'can with member_role block' do
      should 'set permissions correctly' do
        TestMemberAuth.member_role :tester do
          TestMemberAuth.can :hi
          TestMemberAuth.can :wink
        end
        # verfy that permissions are structured correctly
        expected = {:tester => [[:hi, {}],[:wink, {}]]}
        assert_equal expected, TestMemberAuth.member_permissions
      end
    end
    context 'can assigning role wihtout block' do
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
        assert_equal [:update, :edit, :create], @base.send(:expand_aliases, [:update, :create])
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
      @subject = @base.new(:user, :wink, @base, :subject, :parent)
    end
    context 'authorized?' do
      setup do
        def authorized?
          @subject.send(:authorized?)
        end
      end
      should 'return params_handler' do
        @user = stub(:role_symbols => [:manager])
        @base.expects(:permissions).returns({:manager => [ [:wink, {permit: [:a, :b]}] ]})
        @subject.stubs(:user).returns(@user)
        assert_equal ({require: :trust_permissions_test_fund, permit: [:a, :b]}), authorized?
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
      end
      should 'delegate to members_role if required' do
        @user = stub(:role_symbols => [:gurba])
        @subject.stubs(:user).returns(@user)
        @base.stubs(:permissions).returns({})
        assert !authorized?        
        @base.stubs(:member_permissions).returns({:manager => [[:hi, {}],[:wink, {}]]})
        assert !authorized?
        @base.any_instance.stubs(:members_role).returns(:manager)
        assert authorized?
        @base.stubs(:member_permissions).returns({})
        assert !authorized?
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
        assert_equal ({}), eval_expr(:if => true, :unless => false)
      end
      should 'support the following conditions' do
        assert eval_expr(:if => true)
        assert !eval_expr(:unless => true)
      end
      should 'support symbol expression' do
        @subject.expects(:hello).returns(true)
        assert_equal ({}), eval_expr(:if => :hello)
      end
      should 'support proc expression' do
        assert_equal ({}), eval_expr(:if => Proc.new { true })
        assert_equal ({}), eval_expr(:if => lambda { true })
        assert_equal ({}), eval_expr(:unless => lambda { false })
      end
      context 'preloaded' do
        should 'parse well known expressions' do
          assert_equal ({require: :x, permit: [:name, :address]}), eval_expr(require: :x, permit: [:name, :address])
        end
        should 'support preload? method' do
          @subject.instance_variable_set(:@preload, true)
          assert !eval_expr(require: :x, permit: [:name, :address], unless: :preload?)
          assert ({require: :x, permit: [:name, :address]}), eval_expr(require: :x, permit: [:name, :address], if: :preload?)
        end
      end
    end
    context 'preloading' do
      should 'set preload attribute' do
        @var = nil
        @subject.expects(:authorized?).with() {  @var = @subject.preload?  }
        assert !@var
        @subject.preload
        assert @var
      end
      should 'allow instance writer to subject' do
        @subject.subject = :new_subject
        assert_equal :new_subject, @subject.subject
      end
    end
    context 'route key' do
      should 'convert class to names appropriately' do
        assert_equal :trust_permissions_test_account, @subject.send(:route_key, Account)
      end
    end
  end
  
  class Account < Trust::Permissions
    role :tester do
      can :test_user,  :if => Proc.new { user.name == 'mcgormic' }
      can :test_action,  :if => lambda { action == :test_action }
      can :test_klass,   :if => lambda { klass == Account }
      can :test_subject, :if => lambda { subject == :subject }
      can :test_parent,  :if => lambda { parent == :parent }
      can :test_failure, :if => lambda { failure == :failure }
    end
  end
  
  context 'accessing accessors in Permission instance' do
    setup do
      @user = stub(:name => 'mcgormic', :role_symbols => [:tester])
    end
    should 'expose accessors' do
      %w(user action klass subject parent).each do |attr|
        @perm = Account.new(@user, :"test_#{attr}", Account, :subject, :parent)
        assert @perm.authorized?, "test_#{attr} failed"
      end
      assert_raises NameError do
        @perm = Account.new(@user, :test_failure, :klass, :subject, :parent)
        assert @perm.authorized?
      end
    end
  end


  class TestBaseAuth < Trust::Permissions
  end
  class TestBaseAuth2 < Trust::Permissions
  end
  class TestInheritedAuth < TestBaseAuth
  end
  class TestOverride < TestBaseAuth2
  end
  class TestCannnotArgumentError < Trust::Permissions
  end
  class TestBaseAuth3 < Trust::Permissions
    role :tester, :friend do
      can :hi, :if => :ho
      can :wink
    end
  end
  class TestCannot < TestBaseAuth3
    role :tester, cannot(:wink)
    role :friend do
      cannot :hi
    end
  end
  class TestBaseAuth4 < Trust::Permissions
    role :tester, :friend do
      can :hi, :if => :ho
      can :wink
    end
  end
  class TestEnforce < TestBaseAuth4
    role :tester, can(:wink, :enforce => true, :if => :yo)
    role :friend do
      can :hi, :enforce => true, :if => :sure
    end
  end

  context 'inheritance' do
    should 'clone deeply' do
      TestBaseAuth.role :tester do
        TestBaseAuth.can :hi, :if => :ho
        TestBaseAuth.can :wink
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
      TestBaseAuth2.role :tester do
        TestBaseAuth2.can :hi, :if => :ho
        TestBaseAuth2.can :wink
      end

      TestOverride.role :tester do
        TestOverride.can :hi, :if => :ha
      end
      expect = {:tester => [[:hi, {:if=>:ho}], [:wink, {}], [:hi, {:if=>:ha}]]}
      assert_equal expect, TestOverride.permissions
    end
    
    context 'with cannot' do
      should  'not accept options' do
        assert_raises ArgumentError do
          TestCannnotArgumentError.cannot :do, :options => true
        end
      end
      should 'revoke permissions' do
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}]], :friend => [[:hi, {:if => :ho}],[:wink, {}]]}
        assert_equal expect, TestBaseAuth3.permissions
        expect = {:tester => [[:hi, {:if => :ho}]], :friend => [[:wink, {}]]}
        assert_equal expect, TestCannot.permissions
      end
    end
    context 'with enforce' do
      should 'override previous cans' do
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}]], :friend => [[:hi, {:if => :ho}],[:wink, {}]]}
        assert_equal expect, TestBaseAuth4.permissions
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {:if => :yo}]], :friend => [[:wink, {}],[:hi, {:if => :sure}]]}
        assert_equal expect, TestEnforce.permissions
        # Parent permissions should not be affected
        expect = {:tester => [[:hi, {:if => :ho}],[:wink, {}]], :friend => [[:hi, {:if => :ho}],[:wink, {}]]}
        assert_equal expect, TestBaseAuth4.permissions
      end
    end
  end
  
  
  class TestPermit < Trust::Permissions
    require :entity
    permit :aha, :joho
    role :tester do
      can :wink, require: :special, permit: [:no, :way]
      can :blink, require: :somewhat_special
      can :wave, permit: [:hands]
    end
  end
  
  class TestInheritedPermit < TestPermit
  end
  
  context 'params handler storage' do
    setup do
      @ta = TestPermit.new(:user, :wink, TestPermit, :subject, :parent)
      @user = stub(:role_symbols => [:tester])
    end
    context 'of require' do
      should 'default unless specified' do
        TestPermit.entity_required = nil
        ph = @ta.send(:params_handler_default, {})
        assert_equal :trust_permissions_test_test_permit, ph[:require]
        TestPermit.entity_required = :entity
      end
      should 'store default' do
        assert_equal :entity, @ta.entity_required
      end
      should 'inherit default' do
        ta = TestInheritedPermit.new(:user, :wink, TestInheritedPermit, :subject, :parent)
        assert_equal :entity, ta.entity_required
      end
      should 'override on action' do
        ta = TestInheritedPermit.new(@user, :wave, TestInheritedPermit, :subject, :parent)
        expected = {require: :entity, permit: [:hands]}
        assert_equal expected, ta.authorized?
      end
    end
    context 'of permit' do
      should 'store default' do
        assert_equal [:aha, :joho], @ta.entity_attributes
      end
      should 'inherit default' do
        ta = TestInheritedPermit.new(:user, :wink, TestInheritedPermit, :subject, :parent)
        assert_equal [:aha, :joho], ta.entity_attributes
      end
      should 'override on action' do
        ta = TestInheritedPermit.new(@user, :blink, TestInheritedPermit, :subject, :parent)
        expected = {require: :somewhat_special, permit: [:aha, :joho]}
        assert_equal expected, ta.authorized?
      end
    end
    should 'override on action' do
      ta = TestInheritedPermit.new(@user, :wink, TestInheritedPermit, :subject, :parent)
      expected = {require: :special, permit: [:no, :way]}
      assert_equal expected, ta.authorized?
    end
  end
  
end
