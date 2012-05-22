module Trust
  module InheritableAttribute
    extend ActiveSupport::Concern

    module ClassMethods
      # Source: https://github.com/apotonick/hooks/blob/master/lib/hooks/inheritable_attribute.rb
      # Creates an inheritable attribute with accessors in the singleton class. Derived classes inherit the
      # attributes. This is especially helpful with arrays or hashes that are extended in the inheritance
      # chain. Note that you have to initialize the inheritable attribute.
      #
      # Example:
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
            @#{name} ||= Marshal.load(Marshal.dump(value.clone)) # only do this once.
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
