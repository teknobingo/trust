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

class TestBase < ActiveRecord::Base
end
class TestDescendant < TestBase
end
class TestParentLess < ActiveRecord::Base
end

class Permissions::TestBase < Trust::Permissions
end

class Trust::AuthorizationTest < ActiveSupport::TestCase

  class Resource < Trust::Controller::Resource
    def initialize
    end
    attr_accessor :params_handler
    def parent; :parent; end
    def instance; :instance; end
    def klass; TestBase; end
  end

  context 'class method' do
    context 'access_denied!' do
      should 'raise exception' do
        auth = Trust::Authorization.new(:index, TestBase)
        assert_raises Trust::AccessDenied do
          auth.access_denied!
        end
      end
    end
    context 'delegation' do
      setup do
        @obj = stub('authorization')
        Trust::Authorization.expects(:new).with(:action, :object_or_class, [:hello]).returns(@obj)
      end
      should 'include authorized?' do
        @obj.expects(:authorized?).returns(:good)
        assert_equal :good, Trust::Authorization.authorized?(:action, :object_or_class, [:hello])
      end
      should 'include authorize!' do
        @obj.expects(:authorize!).returns(:good)
        assert_equal :good, Trust::Authorization.authorize!(:action, :object_or_class, [:hello])
      end
    end
    context 'user' do
      should 'be set in thread' do
        Trust::Authorization.user = 1
        assert_equal 1, Thread.current["current_user"]
      end
      should 'be retrieved from thread' do
        Thread.current["current_user"] = 2
        assert_equal 2, Trust::Authorization.user
      end
    end
  end
  
  context 'initializtion' do
    setup do
      @parent = stub('parent')
      @user = stub('user')
      @resource = Resource.new
    end
    should 'be done properly when no resource is given' do
      @auth = Trust::Authorization.new('index', TestDescendant, parent: @parent, by: @user)
      assert_equal :index, @auth.action
      assert_equal TestDescendant, @auth.klass
      assert_nil @auth.object
      assert_equal @parent, @auth.parent
      assert_equal @user, @auth.actor
    end
    should 'be done properly when resource is given' do
      Trust::Authorization.user = 1
      @auth = Trust::Authorization.new('show', @resource, by: @user)
      assert_equal :show, @auth.action
      assert_equal TestBase, @auth.klass
      assert_equal :instance, @auth.object
      assert_equal :parent, @auth.parent
      assert_equal @user, @auth.actor
      @auth = Trust::Authorization.new('show', @resource)
      assert_equal 1, @auth.actor
    end    
  end
  
  context 'behaviour' do
    setup do
      @user = stub('user', role_symbols: [:admin])
      @resource = Resource.new
      @auth = Trust::Authorization.new('show', @resource, by: @user)
    end
    context 'authorize!' do
      should 'set params_handler on resource' do
        ph = {require: :klass, permit: [:name, :address]}
        @auth.resource.expects(:params_handler=).with(ph)
        @auth.expects(:permissions).returns(ph)
        @auth.authorize!
      end
      should 'raise exception unless authorized' do
        @auth.expects(:permissions).returns(false)
        assert_raises Trust::AccessDenied do
          @auth.authorize!
        end
      end
    end
    context 'authorized?' do
      should 'return the permissions as a boolean value' do
        @auth.expects(:permissions).returns(false)
        assert_equal false, @auth.authorized?
        @auth.expects(:permissions).returns(nil)
        assert_equal false, @auth.authorized?
        @auth.expects(:permissions).returns({})
        assert_equal true, @auth.authorized?
      end
    end
    context 'instance_loaded' do
      should 'set instance on authorizing class' do
        @auth.authorization.expects(:subject=).with(:cool)
        @auth.instance_loaded :cool        
      end
    end
    context 'preload' do
      should 'require resource to be accessible when instantiated' do
        @auth.instance_variable_set :@resource, nil
        assert_raises Trust::Authorization::ResourceNotLoaded do
          @auth.preload
        end
      end
      should 'delegate to permission if resource is set' do
        @auth.authorization.expects(:preload).returns(:good)
        @resource.expects(:params_handler=).with(:good)
        @auth.preload
      end
    end
    context 'permissions' do
      should 'return the values from the authorizing class' do
        @authorization = stub('authorizing_class')
        @auth.instance_variable_set(:@authorization,@authorization)
        @authorization.expects(:authorized?).returns(false)
        assert !@auth.permissions
        @authorization.expects(:authorized?).returns({})
        assert ({}), @auth.permissions
      end
    end
  end
  
  context 'authorizing_class' do
    setup do
      def authorizing_class(klass)
        Trust::Authorization.new(:index, klass).send(:authorizing_class)
      end
    end
    should 'return associated Authorization class if it exists' do
      assert_equal ::Permissions::TestBase, authorizing_class(::TestBase)
    end
    should 'return Authorization::Default if no assocated Authorization class' do
      assert_equal ::Permissions::Default, authorizing_class(::TestParentLess)
    end
    should 'return parent Authorization if specified and none exist for the class' do
      assert_equal ::Permissions::TestBase, authorizing_class(::TestDescendant)
    end
    should 'support customized base classes' do
      class ::TheBaseClass
      end
      class ::TheBaseDescendant < ::TheBaseClass
      end
      class ::Permissions::TheBaseClass < Trust::Permissions
      end
      assert_equal ::Permissions::TheBaseClass, authorizing_class(::TheBaseDescendant)
    end
  end
  
  

  # context 'authorize!' do
  #   setup do
  #     @resource = Resource.new
  #   end
  #   should 'call access_denied! unless permissions given' do
  #     Trust::Authorization.expects(:access_denied!).twice
  #     Trust::Authorization.expects(:check_permissions).with(:index, :instance, :parent, {}).returns(false)
  #     Trust::Authorization.authorize!(:index, @resource)
  #     @resource.expects(:instance).returns nil
  #     Trust::Authorization.expects(:check_permissions).with(:index, :klass, :parent, {}).returns(false)
  #     Trust::Authorization.authorize!(:index, @resource)
  #     assert_equal false, @resource.params_handler
  #   end
  #   should 'call access_denied! if authorized?' do
  #     Trust::Authorization.expects(:access_denied!).never
  #     Trust::Authorization.expects(:check_permissions).with(:show, :instance, :parent, {}).returns({})
  #     Trust::Authorization.authorize!(:show, @resource)
  #     assert_equal ({}), @resource.params_handler
  #   end    
  # end
  
end
