require 'test_helper'

class Trust::ActiveRecordTest < ActiveSupport::TestCase
  context 'permits?' do
    setup do
      @user = User.new
      @account = Account.new
    end
    should 'support calls to athorized? on class level' do
      Trust::Authorization.expects(:authorized?).with(:manage,Account,:foo)
      Account.permits? :manage, :foo
    end
    should 'support calls to athorized? on instance' do
      Trust::Authorization.expects(:authorized?).with(:manage,@account,:foo)
      @account.permits? :manage, :foo
    end
  end
end
