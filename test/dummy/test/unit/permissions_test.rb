require 'test_helper'

class PermissionsTest < ActiveSupport::TestCase
  setup do
    def login_as(role)
      Trust::Authorization.user = @user = User.find_or_create_by_name(role)
    end
  end
  context 'Client' do
    should 'be managed by system admins' do
      login_as(:system_admin)
      assert Client.permits?(:create)
      assert Client.new.permits?(:create)
    end
    should 'be audited by system admins' do
      login_as(:system_admin)
      assert Client.permits?(:audit)
      assert Client.new.permits?(:audit)
    end
    should 'be managed by accauntants' do
      login_as(:accountant)
      assert Client.permits?(:create)
      assert Client.new.permits?(:create)
    end
    should 'not be managed by guests' do
      login_as(:guest)
      assert !Client.permits?(:create)
      assert !Client.new.permits?(:create)
    end
  end
  context 'Account' do
    should 'be managed by system admins' do
      login_as(:system_admin)
      assert Account.permits?(:create)
      assert Account.new.permits?(:create)
    end
    should 'be audited by system admins' do
      login_as(:system_admin)
      assert Account.permits?(:audit)
      assert Account.new.permits?(:audit)
    end
    should 'not be managed by accauntants' do
      login_as(:accountant)
      assert !Account.permits?(:destroy)
      assert !Account.new.permits?(:destroy)
      assert !Account.permits?(:create)
      assert !Account.new.permits?(:create)
    end
    should 'be created by accauntants associated to clients' do
      login_as(:accountant)
      parent = Client.new
      parent.expects(:accountant).returns(@user.name).twice
      assert Account.permits?(:create,parent)
      assert Account.new.permits?(:create,parent)
    end
    should 'not be created by accauntants unless associated to clients' do
      login_as(:accountant)
      parent = Client.new
      parent.expects(:accountant).returns(stub('bogus', :accountant => :bogus)).times(4)
      assert !Account.permits?(:create,stub('bogus', :accountant => :bogus))
      assert !Account.new.permits?(:create,stub('bogus', :accountant => :bogus))
      assert !Account.permits?(:create,parent)
      assert !Account.new.permits?(:create,parent)
    end
    should 'be created by department managers if parent is superspecial' do
      login_as(:department_manager)
      parent = Client.new
      parent.expects(:accountant).returns(:superspecial).twice
      assert Account.permits?(:create,parent)
      assert Account.new.permits?(:create,parent)
    end
    should 'be created by accauntants if parent is superspecial' do
      login_as(:accountant)
      parent = Client.new
      parent.expects(:accountant).returns(:superspecial).times(4)
      assert Account.permits?(:create,parent)
      assert Account.new.permits?(:create,parent)
    end
    should 'not be created by department managers unless parent is superspecial' do
      login_as(:department_manager)
      parent = Client.new
      parent.expects(:accountant).returns(:not_so_superspecial).twice
      assert !Account.permits?(:create,parent)
      assert !Account.new.permits?(:create,parent)
    end
    should 'not be created by accauntants unless parent is superspecial' do
      login_as(:accountant)
      parent = Client.new
      parent.expects(:accountant).returns(:not_so_superspecial).times(4)
      assert !Account.permits?(:create,parent)
      assert !Account.new.permits?(:create,parent)
    end
    should 'not be created by guests if parent' do
      login_as(:guest)
      assert !Account.permits?(:create)
      assert !Account.new.permits?(:create)
    end
  end
  context 'Account::Credit' do
    should 'be managed by system admins' do
      login_as(:system_admin)
      assert Account::Credit.permits?(:create)
      assert Account::Credit.new.permits?(:create)
    end
    should 'be audited by system admins' do
      login_as(:system_admin)
      assert Account::Credit.permits?(:audit)
      assert Account::Credit.new.permits?(:audit)
    end
    should 'be created by guests if guest is wife' do
      login_as(:guest)
      User.any_instance.stubs(:role_symbols).returns([:guest])
      User.any_instance.stubs(:name).returns('wife')
      assert Account::Credit.permits?(:create)
      assert Account::Credit.new.permits?(:create)
    end
    should 'not be created by guests unless guest is wife' do
      login_as(:guest)
      User.any_instance.stubs(:role_symbols).returns([:guest])
      User.any_instance.stubs(:name).returns('mistress')
      assert !Account::Credit.permits?(:create)
      assert !Account::Credit.new.permits?(:create)
    end
  end
end
