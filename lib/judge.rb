require 'judge/exceptions'
require 'judge/inheritable_attribute'
module Judge
  autoload :Permissions,        'judge/permissions'
  autoload :Controller,         'judge/controller'
  autoload :Authorization,      'judge/authorization'
  autoload :ActiveRecord,       'judge/active_record'
end
require 'judge/controller'
class ActionController::Base
  include Judge::Controller
end
class ActiveRecord::Base
  include Judge::ActiveRecord
end
