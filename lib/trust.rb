require 'trust/exceptions'
require 'trust/inheritable_attribute'
module Trust
  autoload :Permissions,        'trust/permissions'
  autoload :Controller,         'trust/controller'
  autoload :Authorization,      'trust/authorization'
  autoload :ActiveRecord,       'trust/active_record'
end
require 'trust/controller'
class ActionController::Base
  include Trust::Controller
end
class ActiveRecord::Base
  include Trust::ActiveRecord
end
