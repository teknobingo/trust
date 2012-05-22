require 'test_helper'

class Trust::ActiveRecordTest < ActiveSupport::TestCase
  context 'can?' do
    setup do
      @user = User.new
      @account = Account.new
    end
    should 'support calls to athorized? on class level' do
      Trust::Authorization.expects(:authorized?).with(:manage,User,@account)
      User.can? :manage, @account
    end
    should 'support calls to athorized? on instance' do
      Trust::Authorization.expects(:authorized?).with(:manage,@user,@account)
      @user.can? :manage, @account
    end
  end
end
