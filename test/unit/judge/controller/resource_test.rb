require 'test_helper'


class Judge::Controller::ResourceTest < ActiveSupport::TestCase


  setup do
    module ::NameSpacedResource

      class MyEntity
      end

      class Person
      end
    end

    class ::Parent
    end
    class ::Child < Parent; end
    class ::Baluba < Parent; end
    class ::GrandChild < Child; end
  end


  context 'Info classes' do
    context 'Instance' do
      setup do
        @res = Judge::Controller::Resource::ResourceInfo.new('name_spaced_resource/my_entities', {:name_spaced_resource_my_entity => 'cool'})
      end

      should 'resolve name' do
        assert_equal :name_spaced_resource_my_entity, @res.name
      end
      should 'resolve plural name' do
        assert_equal :name_spaced_resource_my_entities, @res.plural_name
      end
      should 'resolve path' do
        assert_equal 'name_spaced_resource/my_entities', @res.path
      end
      should 'resolve class' do
        assert_equal NameSpacedResource::MyEntity, @res.klass
      end

      should 'resolve parameter' do
        assert_equal 'cool', @res.params
      end
    end

    context 'Irregular Instance' do
      setup do
        @res = Judge::Controller::Resource::ResourceInfo.new('name_spaced_resource/people', {:name_spaced_resource_person => 'cool' })
      end

      should 'resolve name' do
        assert_equal :name_spaced_resource_person, @res.name
      end
      should 'resolve plural name' do
        assert_equal :name_spaced_resource_people, @res.plural_name
      end
      should 'resolve path' do
        assert_equal 'name_spaced_resource/people', @res.path
      end
      should 'resolve class' do
        assert_equal NameSpacedResource::Person, @res.klass
      end
      should 'resolve parameter' do
        assert_equal 'cool', @res.params
      end
    end

    context 'Inheritable instance' do
      should 'detect params for children' do
        @res = Judge::Controller::Resource::ResourceInfo.new('parents', {:child => 'cool' })
        assert_equal 'cool', @res.params
      end

      should 'detect params for grandchilds' do
        @res = Judge::Controller::Resource::ResourceInfo.new('parents', {:grand_child => 'cool' })
        assert_equal 'cool', @res.params
      end
      should 'detect params for base' do
        @res = Judge::Controller::Resource::ResourceInfo.new('parents', {:parent => 'cool' })
        assert_equal 'cool', @res.params
      end
      should 'resolve class' do
        @res = Judge::Controller::Resource::ResourceInfo.new('parents', {:grand_child => 'cool' })
        assert_equal Parent, @res.klass
        assert_equal GrandChild, @res.real_class
        @res = Judge::Controller::Resource::ResourceInfo.new('parents', {:parent => 'cool' })
        assert_equal Parent, @res.klass
        assert_equal Parent, @res.real_class
      end
    end

    context 'Parent resource' do
      setup do
        @request = Object.new
        @resources = [NameSpacedResource::Person, :child]
      end
      context 'when found' do
        should 'return object for namespaced resource' do
          @request.stubs(:symbolized_path_parameters).returns({:name_spaced_resource_person_id => 2 })
          NameSpacedResource::Person.expects(:find).with(2).returns(@object = NameSpacedResource::Person.new)
          @res = Judge::Controller::Resource::ParentInfo.new(@resources, {}, @request)
          assert_equal @object, @res.object
        end
        should 'return object for regular resource' do
          @request.stubs(:symbolized_path_parameters).returns({:child_id => 2 })
          Child.expects(:find).with(2).returns(@object = Child.new)
          @res = Judge::Controller::Resource::ParentInfo.new(@resources, {}, @request)
          assert_equal @object, @res.object
        end
        context 'the attributes' do
          setup do
            @request.stubs(:symbolized_path_parameters).returns({:child_id => 2 })
            Child.expects(:find).with(2).returns(@object = Child.new)
            @res = Judge::Controller::Resource::ParentInfo.new(@resources, {:child => 'tie'}, @request)
          end
          should 'return class for object' do
            assert_equal @object, @res.object
            assert @res.object?        
          end
          should 'respond to object?' do
            assert @res.object?        
          end
          should 'return name for class' do
            assert_equal :child, @res.name
          end
          should 'return parameters' do
            assert_equal 'tie', @res.params
          end
        end
      end
      should 'return nil for object if not found' do
        @request.stubs(:symbolized_path_parameters).returns({:child_id => 2 })
        Child.expects(:find).with(2).returns(nil)
        @res = Judge::Controller::Resource::ParentInfo.new(@resources, {}, @request)
        assert_nil @res.object
        assert !@res.object?
      end
      should 'return nil for object if not specified' do
        @request.stubs(:symbolized_path_parameters).returns({})
        @res = Judge::Controller::Resource::ParentInfo.new(@resources, {}, @request)
        assert_nil @res.object
        assert !@res.object?
      end
      should 'return nil for klass when not found' do
        @request.stubs(:symbolized_path_parameters).returns({})
        @res = Judge::Controller::Resource::ParentInfo.new(@resources, {}, @request)
        assert_nil @res.klass
      end
    end

    context 'Parent resource with inheritance' do
      setup do
        @request = Object.new
        @resources = [:parent]
        @request.stubs(:symbolized_path_parameters).returns({:child_id => 2 })
        Parent.expects(:find).with(2).returns(@object = Child.new)
        @res = Judge::Controller::Resource::ParentInfo.new(@resources, {}, @request)
      end
      should 'resolve descendants' do
        assert_equal @object, @res.object
      end
      should 'have correct name' do
        assert_equal :child, @res.name
      end
      should 'have correct class' do
        assert_equal Parent, @res.klass
      end
      should 'have real class' do
        assert_equal Child, @res.real_class
      end
    end
  end
  
  
  context 'Resource' do
    setup do
      @controller = stub('Controller')
      @properties = Judge::Controller::Properties.new(@controller)
      @properties.model_name :child
      @properties.belongs_to :parent
      @resource_info = stub('ResourceInfo')
      @parent_info = stub(:object => 6, :name => :parent)
      @resource_info.expects(:relation).with(@parent_info).returns(Child)
      @resource_info.stubs(:name).returns(:child)
      Judge::Controller::Resource.any_instance.expects(:extract_resource_info).with('child', {}).returns(@resource_info)
      Judge::Controller::Resource.any_instance.expects(:extract_parent_info).with([:parent], {}, @request).returns(@parent_info)
    end
    should 'instantiate properly' do      
      @resource = Judge::Controller::Resource.new(@controller, @properties, 'new',{}, @request)      
    end
    should 'discover variable names' do
      @resource = Judge::Controller::Resource.new(@controller, @properties, 'new',{}, @request)
      assert_equal :child, @resource.send(:instance_name)
      assert_equal :parent, @resource.send(:parent_name)
    end
    should 'load as expected' do
      @resource = Judge::Controller::Resource.new(@controller, @properties, 'new',{}, @request)      
      @resource_info.stubs(:params).returns({})
      @controller.expects(:respond_to?).with(:build).returns(false)
      @resource.load
      assert_equal 6, @controller.instance_variable_get(:@parent)
      assert_equal 6, @resource.parent
      assert @controller.instance_variable_get(:@child).is_a?(Child)
      assert @resource.instance.is_a?(Child)
    end
  end
  
end
