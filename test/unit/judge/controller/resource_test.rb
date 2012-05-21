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
  
  context 'Resource' do
    setup do
      @res = Judge::Controller::Resource::InstanceInfo.new('name_spaced_resource/my_entities', {:name_spaced_resource_my_entity => 'cool'})
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
  
  context 'Irregular Resource' do
    setup do
      @res = Judge::Controller::Resource::InstanceInfo.new('name_spaced_resource/people', {:name_spaced_resource_person => 'cool' })
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
  
  context 'Inheritable resource' do
    should 'detect params for children' do
      @res = Judge::Controller::Resource::InstanceInfo.new('parents', {:child => 'cool' })
      assert_equal 'cool', @res.params
    end
    
    should 'detect params for grandchilds' do
      @res = Judge::Controller::Resource::InstanceInfo.new('parents', {:grand_child => 'cool' })
      assert_equal 'cool', @res.params
    end
    should 'detect params for base' do
      @res = Judge::Controller::Resource::InstanceInfo.new('parents', {:parent => 'cool' })
      assert_equal 'cool', @res.params
    end
    should 'resolve class' do
      @res = Judge::Controller::Resource::InstanceInfo.new('parents', {:grand_child => 'cool' })
      assert_equal Parent, @res.klass
      assert_equal GrandChild, @res.real_class
      @res = Judge::Controller::Resource::InstanceInfo.new('parents', {:parent => 'cool' })
      assert_equal Parent, @res.klass
      assert_equal Parent, @res.real_class
    end
  end
  
  context 'Associated resource' do
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
  
  context 'Associated resource with inheritance' do
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
