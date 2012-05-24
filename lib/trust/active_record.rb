module Trust
  module ActiveRecord
    extend ActiveSupport::Concern
    
    included do
      include ClassMethods
    end
    
    module ClassMethods
      def permits?(action, parent = nil)
        Trust::Authorization.authorized?(action, self, parent)
      end
    end
  end
end
