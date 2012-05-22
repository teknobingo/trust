module Judge
  module ActiveRecord
    extend ActiveSupport::Concern
    
    included do
      include JudgeInctanceMethods
    end
    
    module CLassMethods
      def can?(action, parent = nil)
        Judge::Authorization.authorized?(action, self, parent)
      end
    end
    
    module JudgeInctanceMethods
      def can?(action, parent = nil)
        Judge::Authorization.authorized?(action, self, parent)
      end      
    end
  end
end