require 'judge/exceptions'
require 'judge/inheritable_attribute'
module Judge
  autoload :Permissions,        'judge/permissions'
  autoload :Controller,         'judge/controller'
  autoload :Authorization,      'judge/authorization'
end
require 'judge/controller'
class ActionController::Base
  include Judge::Controller
end
