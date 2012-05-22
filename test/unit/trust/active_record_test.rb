require 'test_helper'

class Trust::ActiveRecordTest < ActiveSupport::TestCase
  context 'can?' do
    setup do
      @user = User.new
      @account = Account.new
      @savings_account = SavingsAccount.new
      @credits_account = Account::Credit.new
    end
    should 'support calls to athorized? on class level' do
      Trust::Authorization.expects(:authorized?).with(:manage,User,@account)
      User.can? :manage, @account
    end
    should 'support calls to athorized? on instance' do
      Trust::Authorization.expects(:authorized?).with(:manage,@user,@account)
      @user.can? :manage, @account
    end
    context 'inherited classes' do
      should 'support calls to athorized? on class level' do
        Trust::Authorization.expects(:authorized?).with(:manage,User,@savings_account)
        User.can? :manage, @savings_account
      end
      should 'support calls to athorized? on instance' do
        Trust::Authorization.expects(:authorized?).with(:manage,@user,@savings_account)
        @user.can? :manage, @savings_account
      end
    end
    context 'namespaced classes' do
      should 'support calls to athorized? on class level' do
        Trust::Authorization.expects(:authorized?).with(:manage,User,@credits_account)
        User.can? :manage, @credits_account
      end
      should 'support calls to athorized? on instance' do
        Trust::Authorization.expects(:authorized?).with(:manage,@user,@credits_account)
        @user.can? :manage, @credits_account
      end
    end
  end
end
