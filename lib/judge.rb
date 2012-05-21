require 'judge/exceptions'
require 'judge/inheritable_attribute'
module Judge
  autoload :Controller,         'judge/controller'
  autoload :Authorization,      'judge/authorization'
  autoload :Base,               'judge/base'
end
require 'judge/action_controller'
class ActionController::Base
  include Judge::ActionController
end
