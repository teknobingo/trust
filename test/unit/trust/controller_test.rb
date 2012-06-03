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
  setup do
    class Controller < ActionController::Base
      trustee
    end
    class DerivedController < Controller
    end
  end
  context 'class method' do
    should 'instantiate properties' do
      assert_kind_of Trust::Controller::Properties, Controller.properties
    end
    should 'trustee set filers' do
      options = {:hello => :there}
      Controller.expects(:before_filter).with(:set_user, options)
      Controller.expects(:before_filter).with(:load_resource, options)
      Controller.expects(:before_filter).with(:access_control, options)
      Controller.trustee options
    end
    should 'delegate to resource' do
      Controller.properties.expects(:belongs_to)
      Controller.properties.expects(:actions)
      Controller.properties.expects(:model_name)
      Controller.belongs_to
      Controller.actions
      Controller.model_name
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
        Controller.expects(:skip_before_filter).with(:access_control).times(3)
        Controller.expects(:before_filter).with(:access_control,{})
        Controller.access_control
        Controller.expects(:before_filter).with(:access_control,{:only => :index})
        Controller.access_control :only => :index
        Controller.expects(:before_filter).never
        Controller.access_control :off
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
    should 'load resource' do
      @controller.expects(:resource).returns(stub(:load => true))
      @controller.load_resource
    end
    should 'expose resource as helper' do
      assert @controller.class._helper_methods.include?(:resource)
    end
    should 'provide access control' do
      resource = stub('resource')
      instance = stub('resource instance')
      klass    = stub('resource klass')
      parent   = stub('resource parent')

      resource.expects(:instance).returns(instance)
      resource.expects(:parent).returns(parent)
      @controller.expects(:resource).returns(resource).twice
      Trust::Authorization.expects(:authorize!).with(nil,instance,parent)
      @controller.access_control

      resource.expects(:instance).returns(nil)
      resource.expects(:parent).returns(parent)
      resource.expects(:klass).returns(klass)
      @controller.expects(:resource).returns(resource).times(3)
      Trust::Authorization.expects(:authorize!).with(nil,klass,parent)
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
        @controller.expects(:resource).returns(resource).at_least_once
        resource.expects(:instance).returns(:instance)
        resource.expects(:parent).returns(:parent)
        Trust::Authorization.expects(:authorized?).with(:manage,:instance,:parent)
        @controller.can? :manage
        resource.expects(:instance).returns(nil)
        resource.expects(:klass).returns(:klass)
        resource.expects(:parent).returns(:parent)
        Trust::Authorization.expects(:authorized?).with(:manage,:klass,:parent)
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
      DerivedController.properties.expects(:model_name)
      DerivedController.belongs_to
      DerivedController.actions
      DerivedController.model_name
    end
  end
end
