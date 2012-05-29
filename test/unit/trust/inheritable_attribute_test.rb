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

class Trust::InheritableAttributeTest < ActiveSupport::TestCase
  setup do
    class Cat
      include Trust::InheritableAttribute
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
  context 'inheritance' do
    should 'deep copy inheritable attributes' do
      Cat.new.drinks << ['Corona', { :booze => [ 'Liquor', 'Spirit'] }]
      class Sylvester < Cat
        self.drinks.last << 'Wiskey'
      end
      assert_equal ['Becks', ['Corona', { :booze => [ 'Liquor', 'Spirit'] }]], Cat.drinks
      assert_equal ['Becks', ['Corona', { :booze => [ 'Liquor', 'Spirit'] }, 'Wiskey']], Sylvester.drinks
    end
  end
end
