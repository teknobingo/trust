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

class AccountsControllerTest < ActionController::TestCase
  context 'with all permissions' do
    setup do
      login_as(:system_admin)
      @client = Client.create
      @account = Account.create(:client_id => @client.id) #accounts(:one)
    end

    should "get index" do
      get :index, client_id: @client
      assert_response :success
      assert_not_nil assigns(:accounts)
    end

    should "get new" do
      get :new, client_id: @client
      assert_response :success
    end

    should "create account" do
      assert_difference('Account.count') do
        post :create, client_id: @client, account: { name: @account.name }
      end

      assert_redirected_to client_account_path(@client,assigns(:account))
    end

    should "show account" do
      get :show, client_id: @client, id: @account
      assert_response :success
    end

    should "get edit" do
      get :edit, client_id: @client, id: @account
      assert_response :success
    end

    should "update account" do
      put :update, client_id: @client, id: @account, account: { name: @account.name }
      assert_redirected_to client_account_path(@client, assigns(:account))
    end

    should "destroy account" do
      assert_difference('Account.count', -1) do
        delete :destroy, client_id: @client, id: @account
      end

      assert_redirected_to client_accounts_path
    end
  end
  
  context 'with limited permissions' do
    setup do
      login_as(:accountant)
      @client = Client.create
      @account = @client.accounts.create
      flunk unless @account
    end
    
    should 'deny access on index' do
      assert_raises Trust::AccessDenied do
        get :index, client_id: @client
      end
    end
    should 'deny access on new' do
      assert_raises Trust::AccessDenied do
        get :new, client_id: @client
      end
    end
    should 'deny access on show' do
      assert_raises Trust::AccessDenied do
        get :show, client_id: @client, id: @account
      end
    end
    should 'deny access on destroy' do
      assert_raises Trust::AccessDenied do
        delete :destroy, client_id: @client, id: @account
      end
    end
    context 'but having ownership' do
      should 'allow updates' do
        put :update, client_id: @client, id: @account, account: { name: @account.name }
        assert_redirected_to client_account_path(@client, assigns(:account))
      end
    end
    context 'having no ownership' do
      should 'deny access' do
        login_as(:guest)
        assert_raises Trust::AccessDenied do
          put :update, client_id: @client, id: @account, account: { name: @account.name }
        end
      end
    end
    
  end
  
end
