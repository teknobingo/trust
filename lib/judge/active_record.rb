module Judge
  module ActiveRecord
    extend ActiveSupport::Concern
    
    included do
      include ClassMethods
    end
    
    module ClassMethods
      def can?(action, parent = nil)
        Judge::Authorization.authorized?(action, self, parent)
      end
    end
  end
end