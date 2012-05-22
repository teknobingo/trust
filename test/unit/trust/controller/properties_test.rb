require 'test_helper'

class Trust::Controller::PropertiesTest < ActiveSupport::TestCase
  setup do
    class Controller
      def self.properties
        # traditional new, but controversiol code
        @properties ||= Trust::Controller::Properties.new(self)
      end
    end
    class ChildController < Controller
    end
  end

  context 'instantiating' do
    should 'make a fresh object'
  end

  context 'actions' do
    should 'accumulate add actions' do
      properties = Trust::Controller::Properties.new(self)
      properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe})
      assert_equal [:new, :create, :yes], properties.new_actions
      assert_equal [:show, :edit, :update, :destroy, :no], properties.member_actions
      assert_equal [:index, :maybe], properties.collection_actions
    end
    should 'overide actions on new, member and collection' do
      properties = Trust::Controller::Properties.new(self)
      properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe}, :new => :really, :member => :do, :collection => :override)
      assert_equal [:really], properties.new_actions
      assert_equal [:do], properties.member_actions
      assert_equal [:override], properties.collection_actions
    end
    should 'mask with only' do
      properties = Trust::Controller::Properties.new(self)
      properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe}, :only => [:yes,:no,:maybe])
      assert_equal [:yes], properties.new_actions
      assert_equal [:no], properties.member_actions
      assert_equal [:maybe], properties.collection_actions
    end
    should 'filter with except' do
      properties = Trust::Controller::Properties.new(self)
      properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe}, :except => [:yes, :no, :maybe])
      assert_equal [:new, :create], properties.new_actions
      assert_equal [:show, :edit, :update, :destroy], properties.member_actions
      assert_equal [:index], properties.collection_actions
    end
  end

end
