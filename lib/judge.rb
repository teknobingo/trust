require 'judge/exceptions'
require 'judge/inheritable_attribute'
module Judge
#  autoload :InheritableAttribute, 'judge/inheritable_attribute'
  autoload :Authorization,        'judge/authorization'
  autoload :Base,                 'judge/base'
end
require 'judge/action_controller'
class ActionController::Base
  include Judge::ActionController
end
