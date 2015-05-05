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

class Trust::Controller::PropertiesTest < ActiveSupport::TestCase
  setup do
    class Controller
      def self.properties
        # traditional new, but controversiol code
        @properties ||= Trust::Controller::Properties.instantiate(self)
      end
      def self.controller_path
        'controller'
      end
    end
    class PeopleController < Controller
      def self.controller_path
        'people'
      end
    end
    class ::Person
    end
  end

  context 'instantiating' do
    should 'make a fresh object' do
      Trust::Controller::Properties.expects(:new).with(PeopleController, nil).once
      assert !Trust::Controller::Properties.instantiate(PeopleController).instance_variable_get(:@controller)
    end

    should 'clone controllers properties' do
      new_actions = [:new, :create, :confirm]
      parent = Trust::Controller::Properties.new(Controller, nil)
      parent.new_actions = new_actions
      child = Trust::Controller::Properties.new(PeopleController, parent)
      assert_equal PeopleController, child.instance_variable_get(:@controller)
      assert_equal new_actions, child.new_actions
      child.new_actions = [:confirm]
      assert_equal new_actions, parent.new_actions
      assert_equal [:confirm], child.new_actions
    end
  end
  
  context 'information' do
    should 'resolve class from model' do
      assert_equal Person, PeopleController.properties.model_class
    end
  end

  context 'actions' do
    setup do
       @properties = Trust::Controller::Properties.instantiate(Controller)
    end
    should 'accumulate add actions' do
      @properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe})
      assert_equal [:new, :create, :yes], @properties.new_actions
      assert_equal [:show, :edit, :update, :destroy, :no], @properties.member_actions
      assert_equal [:index, :maybe], @properties.collection_actions
    end
    should 'overide actions on new, member and collection' do
      @properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe}, :new => :really, :member => :do, :collection => :override)
      assert_equal [:really], @properties.new_actions
      assert_equal [:do], @properties.member_actions
      assert_equal [:override], @properties.collection_actions
    end
    should 'mask with only' do
      @properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe}, :only => [:yes,:no,:maybe])
      assert_equal [:yes], @properties.new_actions
      assert_equal [:no], @properties.member_actions
      assert_equal [:maybe], @properties.collection_actions
    end
    should 'filter with except' do
      @properties.actions(:add => {:new => :yes, :member => :no, :collection => :maybe}, :except => [:yes, :no, :maybe])
      assert_equal [:new, :create], @properties.new_actions
      assert_equal [:show, :edit, :update, :destroy], @properties.member_actions
      assert_equal [:index], @properties.collection_actions
    end
    should 'discover new_action?' do
      assert @properties.new_action?( :new)
      assert @properties.new_action?( 'new')
      assert !@properties.new_action?( :show)
    end
    should 'discover collection_action?' do
      assert @properties.collection_action?( :index)
      assert @properties.collection_action?( 'index')
      assert !@properties.collection_action?( :show)
    end
    should 'discover member_action?' do
      assert @properties.member_action?( :show)
      assert @properties.member_action?( 'show')
      assert !@properties.member_action?( :index)
    end
  end
  
  context 'belongs_to' do
    setup do
      @properties = Trust::Controller::Properties.instantiate(Controller)
    end
    should 'affect has_associations?' do
      assert !@properties.has_associations?
    end
    should 'accept simple association' do
      @properties.belongs_to :heaven
      assert @properties.has_associations?
      expected = {:heaven => nil}
      assert_equal expected, @properties.associations
    end
    should 'accept multiple associations' do
      @properties.belongs_to :heaven, :hell
      assert @properties.has_associations?
      expected = {:heaven => nil, :hell => nil}
      assert_equal expected, @properties.associations
      @properties.belongs_to :earth
      expected = {:heaven => nil, :hell => nil, :earth => nil}
      assert_equal expected, @properties.associations      
    end
    should 'accept association as' do
      @properties.belongs_to :heaven, :as => :earth
      assert @properties.has_associations?
      expected = {:heaven => :earth}
      assert_equal expected, @properties.associations
    end
  end

end
