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
        @properties ||= Trust::Controller::Properties.new(self)
      end
    end
    class PeopleController < Controller
    end
    class ::Person
    end
  end

  context 'instantiating' do
    should 'make a fresh object' do
      controller = stub('controller', :superclass => false)
      Trust::Controller::Properties.expects(:new).with(controller).once
      assert !Trust::Controller::Properties.instantiate(controller).instance_variable_get(:@controller)
    end

    should 'clone controllers permissions' do
      controller = stub('controller', :superclass => stub('superclass', :properties => Trust::Controller::Properties.new(true)))
      assert Trust::Controller::Properties.instantiate(controller).instance_variable_get(:@controller)
    end
  end
  
  context 'information' do
    should 'resolve class from model_name' do
      Trust::Controller::Properties.any_instance.stubs(:model_name).returns(:people)
      assert_equal Person, PeopleController.properties.model_class
    end
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
