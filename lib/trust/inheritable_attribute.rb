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

module Trust
  # = Trust InheritableAttribute
  module InheritableAttribute

    def self.deep_copy( value) #:nodoc:
      if value.is_a? Hash
        Hash[*value.map{ |k,v| [self.deep_copy(k),self.deep_copy(v)] }.flatten(1)]
      elsif value.is_a? Array
        value.map{ |v| self.deep_copy(v) }
      elsif value.is_a? Symbol
        value
      else
        value.clone
      end
    end

    extend ActiveSupport::Concern

    module ClassMethods
      # Creates an inheritable attribute with accessors in the singleton class. 
      # 
      # Derived classes inherit the attributes. This is especially helpful with arrays or hashes that 
      # are extended in the inheritance chain. Note that you have to initialize the inheritable attribute.
      #
      # === Example
      #
      #   class Cat
      #     inheritable_attr :drinks
      #     self.drinks = ["Becks"]
      #
      #   class Garfield < Cat
      #     self.drinks << "Fireman's 4"
      #
      # and then, later
      #
      #   Cat.drinks      #=> ["Becks"]
      #   Garfield.drinks #=> ["Becks", "Fireman's 4"]
      def inheritable_attr(name, options = {})
        src = <<-end_src
          def #{name}=(v)
            @#{name} = v
          end

          def #{name}
            return @#{name} unless superclass.respond_to?(:#{name}) and value = superclass.#{name}
            @#{name} ||= ::Trust::InheritableAttribute::deep_copy(value) # only do this once.
          end
        end_src
        instance_eval src, __FILE__, __LINE__
        if !options.key?(:instance_writer) || options[:instance_writer]
          src = <<-end_src
            def #{name}=(v)
              self.class.#{name} = v
            end
          end_src
          class_eval src, __FILE__, __LINE__
        end
        if !options.key?(:instance_reader) || options[:instance_reader]
          src = <<-end_src
            def #{name}
              self.class.#{name}
            end
          end_src
          class_eval src, __FILE__, __LINE__
        end
      end
    end
  end  
end
