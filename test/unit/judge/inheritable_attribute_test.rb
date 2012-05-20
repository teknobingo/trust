require 'test_helper'

class Judge::InheritableAttributeTest < ActiveSupport::TestCase
  setup do
    class Cat
      include Judge::InheritableAttribute
      inheritable_attr :drinks
      inheritable_attr :food, :instance_writer => false, :instance_reader => false
      self.drinks = ["Becks"]
    end
  end
  should 'have only one element in Cat and have two elements in Garfield' do
    class Garfield < Cat
      self.drinks << "Fireman's 4"
    end
    assert_equal ["Becks"], Cat.drinks
    assert_equal ["Becks", "Fireman's 4"], Garfield.drinks
  end
  should 'have instance method' do
    assert_equal ["Becks"], Cat.new.drinks
    Cat.new.drinks << "Bud"
    assert_equal ["Becks", "Bud"], Cat.drinks
    assert_equal ["Becks", "Bud"], Cat.new.drinks
    assert_raises NoMethodError do
      Cat.new.food
    end
    assert_raises NoMethodError do
      Cat.new.food = 'x'
    end
  end
end