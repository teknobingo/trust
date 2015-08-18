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

class Trust::ControllerTest < ActiveSupport::TestCase
  class Controller < ActionController::Base
    trustee
  end
  class DerivedController < Controller
  end
  
  setup do
    @filter_keyword = Trust.rails_generation < 4 ? :before_filter : :before_action
  end
  
  context 'class method' do
    should 'instantiate properties' do
      assert_kind_of Trust::Controller::Properties, Controller.properties
    end
    should 'trustee set filers' do
      options = {:hello => :there}
      Controller.expects(@filter_keyword).with(:set_user, options)
      Controller.expects(@filter_keyword).with(:load_resource, options)
      Controller.expects(@filter_keyword).with(:access_control, options)
      Controller.trustee options
    end
    should 'delegate to resource' do
      Controller.properties.expects(:belongs_to)
      Controller.properties.expects(:actions)
      Controller.properties.expects(:model)
      Controller.belongs_to
      Controller.actions
      Controller.model
    end

    context 'callbacks' do
      should 'be set_user, load_resource, access_control' do
        %w(set_user load_resource access_control).map(&:to_sym).each do |callback|
          assert Controller.respond_to?(callback), "'#{callback}' not included"
          Controller.expects(:_filter_setting).with(callback, 'gurba')
          Controller.send(callback, 'gurba')
        end
      end
    end
    
    context '_filter_setting' do
      should 'setup correct instance method callback' do
        Controller.expects(:"skip_#{@filter_keyword}").with(:access_control).times(3)
        Controller.expects(@filter_keyword).with(:access_control,{})
        Controller.access_control
        Controller.expects(@filter_keyword).with(:access_control,{:only => :index})
        Controller.access_control :only => :index
        Controller.expects(@filter_keyword).never
        Controller.access_control :off
      end
      should 'only set filters that are not off' do
        options = {:hello => :there, :set_user => :off}
        Controller.expects(@filter_keyword).with(:set_user).never
        Controller.expects(@filter_keyword).with(:load_resource, options)
        Controller.expects(@filter_keyword).with(:access_control, options)
        Controller.trustee options
        options = {:hello => :there, :load_resource => :off}
        Controller.expects(@filter_keyword).with(:set_user, options)
        Controller.expects(@filter_keyword).with(:load_resource).never
        Controller.expects(@filter_keyword).with(:access_control, options)
        Controller.trustee options
        options = {:hello => :there, :access_control => :off}
        Controller.expects(@filter_keyword).with(:set_user, options)
        Controller.expects(@filter_keyword).with(:load_resource, options)
        Controller.expects(@filter_keyword).with(:access_control).never
        Controller.trustee options
      end
    end
    
  end
  context 'instance methods' do
    setup do
      @controller = Controller.new
    end
    should 'set user' do
      user = stub('user')
      @controller.expects(:current_user).returns(user)
      Trust::Authorization.expects(:user=).with(user)
      @controller.set_user
    end
    context 'load_resource' do
      setup do
        @authorization = stub('authorization')
        @controller.stubs(:authorization).returns(@authorization)
        @controller.stubs(:params).returns({})
        @controller.stubs(:request).returns(stub('request', params: {}))
      end
      should 'preload authorizations upon new actions' do
        @controller.expects(:action_name).returns('new')
        @authorization.expects(:preload)
        @controller.resource.expects(:load).returns(:the_instance)
        @authorization.expects(:instance_loaded).with(:the_instance)
        @controller.load_resource
      end
      should 'just load existing resources' do
        @controller.expects(:action_name).returns('index')
        @controller.resource.expects(:load).returns(:the_instance)
        @controller.load_resource
      end
    end
    should 'expose resource as helper' do
      assert @controller.class._helper_methods.include?(:resource)
    end
    should 'initialize authorization object properly' do
      @controller.instance_variable_set :@authorization, nil
      @controller.expects(:resource).returns(:the_resource)
      @controller.expects(:action_name).returns('index')
      Trust::Authorization.expects(:new).with('index', :the_resource).returns(:an_authorization)
      assert_equal :an_authorization, @controller.authorization
      assert_equal :an_authorization, @controller.instance_variable_get( :@authorization)
    end
    should 'provide access control' do
      @controller.stubs(:authorization).returns(stub('authorization'))
      @controller.authorization.expects(:authorize!)
      @controller.access_control
    end
    context 'can?' do
      should 'call authorized?' do
        user = User.new
        account = Account.new
        resource = stub('Resource')
        resource.expects(:parent).returns(nil)
        @controller.expects(:resource).returns(resource)
        Trust::Authorization.expects(:authorized?).with(:manage,account,nil).returns(true)
        @controller.can? :manage, account
      end
      should 'should have default parameters' do
        resource = stub('Resource')
        relation = stub('Relation')
        @controller.expects(:resource).returns(resource).at_least_once
        relation.expects(:new).returns(:some_relation_instance)
        resource.expects(:relation).returns(relation)
        resource.expects(:instance).returns(:instance)
        resource.expects(:parent).returns(:parent)
        Trust::Authorization.expects(:authorized?).with(:manage,:instance,:parent)
        @controller.can? :manage
        resource.expects(:instance).returns(nil)
        resource.expects(:parent).returns(:parent)
        Trust::Authorization.expects(:authorized?).with(:manage,:some_relation_instance,:parent)
        @controller.can? :manage
      end
      should 'be exposed as helper' do
        assert @controller.class._helper_methods.include?(:can?)
      end
    end
  end
  context 'derived controller' do
    should 'instantiate its properties' do
      DerivedController.instance_variable_set('@properties',nil)
      Trust::Controller::Properties.expects(:instantiate).with(DerivedController)
      DerivedController.properties
    end
    should 'instantiate its own properties' do
      assert_not_equal Controller.properties, DerivedController.properties
    end
    should 'delegate to its own resource' do
      DerivedController.properties.expects(:belongs_to)
      DerivedController.properties.expects(:actions)
      DerivedController.properties.expects(:model)
      DerivedController.belongs_to
      DerivedController.actions
      DerivedController.model
    end
  end
end
