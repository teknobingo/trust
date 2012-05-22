require 'test_helper'


class Judge::ControllerTest < ActiveSupport::TestCase
  context 'class method' do
    should_eventually 'instantiate properties' do
    end
    should_eventually 'judged set filers' do
    end
    should_eventually 'delegate to resource' do
    end
  end
  context 'instance methods' do
    should_eventually 'set user' do
    end
    should_eventually 'access resource' do
    end
    should_eventually 'load resource' do
    end
    should_eventually 'provide access control' do
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
