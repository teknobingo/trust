require 'test_helper'

class Judge::Controller::PropertiesTest < ActiveSupport::TestCase
  setup do
    class Controller
      def self.properties
        # traditional new, but controversiol code
        @properties ||= Judge::Controller::Properties.new(self)
      end
    end
    class ChildController < Controller
    end
  end

  context 'instantiating' do
    should 'make a fresh object'
  end
  
end