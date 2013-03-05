# Copyright (c) 2012 Bingo Entreprenøren AS
# Copyright (c) 2012 Teknobingo Scandinavia AS
# Copyright (c) 2012 Knut I. Stenmark
# Copyright (c) 2012 Patrick Hanevold
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'trust/exceptions'
require 'trust/inheritable_attribute'
module Trust
  autoload :Permissions,        'trust/permissions'
  autoload :Controller,         'trust/controller'
  autoload :Authorization,      'trust/authorization'
  autoload :ActiveModel,        'trust/active_model'
  autoload :Actor,              'trust/actor'
end
require 'trust/controller'
class ActionController::Base
  include Trust::Controller
end
if defined?(ActiveRecord)
  class ActiveRecord::Base
    include Trust::ActiveModel
  end
end

begin; require 'mongoid'; rescue LoadError; end
if defined? ::Mongoid
  module Mongoid
    module Document
      include Trust::ActiveModel
      def Document.included(base)
        base.send(:extend,Trust::ActiveModel::ClassMethods)
      end
    end
  end
end
