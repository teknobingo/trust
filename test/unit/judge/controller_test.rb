require 'test_helper'


class Judge::ControllerTest < ActiveSupport::TestCase
  setup do
    class Controller < ActionController::Base
      judged
    end
  end
  context 'class method' do
    should 'instantiate properties' do
      assert_kind_of Judge::Controller::Properties, Controller.properties
    end
    should 'judged set filers' do
      options = {:hello => :there}
      Controller.expects(:before_filter).with(:set_user, options)
      Controller.expects(:before_filter).with(:load_resource, options)
      Controller.expects(:before_filter).with(:access_control, options)
      Controller.judged options
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
      Judge::Authorization.expects(:user=).with(user)
      @controller.set_user
    end
    should 'load resource' do
      @controller.expects(:resource).returns(stub(:load => true))
      @controller.load_resource
    end
    should 'provide access control' do
      resource = stub('resource')
      instance = stub('resouce instance')
      klass    = stub('resouce klass')
      parent = stub('resource parent')

      resource.expects(:instance).returns(instance)
      resource.expects(:parent).returns(parent)
      @controller.expects(:resource).returns(resource).twice
      Judge::Authorization.expects(:authorize!).with(nil,instance,parent)
      @controller.access_control

      resource.expects(:instance).returns(nil)
      resource.expects(:parent).returns(parent)
      resource.expects(:klass).returns(klass)
      @controller.expects(:resource).returns(resource).times(3)
      Judge::Authorization.expects(:authorize!).with(nil,klass,parent)
      @controller.access_control
    end
    context 'can?' do
      should_eventually 'call authorized?' do
      end
      should_eventually 'should have default parameters' do
      end
      should_eventually 'be exposed as helper' do
      end
    end
  end
end
