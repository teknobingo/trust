require 'test_helper'


class Trust::ControllerTest < ActiveSupport::TestCase
  setup do
    class Controller < ActionController::Base
      trusted
    end
    class DerivedController < Controller
    end
  end
  context 'class method' do
    should 'instantiate properties' do
      assert_kind_of Trust::Controller::Properties, Controller.properties
    end
    should 'trusted set filers' do
      options = {:hello => :there}
      Controller.expects(:before_filter).with(:set_user, options)
      Controller.expects(:before_filter).with(:load_resource, options)
      Controller.expects(:before_filter).with(:access_control, options)
      Controller.trusted options
    end
    should 'delegate to resource' do
      Controller.properties.expects(:belongs_to)
      Controller.properties.expects(:actions)
      Controller.properties.expects(:model_name)
      Controller.belongs_to
      Controller.actions
      Controller.model_name
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
        Trust::Authorization.expects(:authorize!).with(:manage,:instance,:parent)
        @controller.can? :manage
        resource.expects(:instance).returns(nil)
        resource.expects(:klass).returns(:klass)
        resource.expects(:parent).returns(:parent)
        Trust::Authorization.expects(:authorize!).with(:manage,:klass,:parent)
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
