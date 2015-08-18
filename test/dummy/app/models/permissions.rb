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

module Permissions
  Trust::Permissions.action_aliases = {
    update: [:update, :edit],
    }
  class Default < Trust::Permissions
    role :system_admin do
      can :index, :show, :create, :new, :update, :edit, :destroy
      can :audit
    end
    
    def self.all
      [:system_admin, :accountant, :department_manager, :guest]
    end
    
    def creator?
      subject.created_by == user
    end
  end

  class Client < Default
    role :accountant, can(:index, :show, :create, :new, :update, :edit, :destroy)
    role all, can(:index, :show)
  end

  class MongoClient < Client
  end
  
  class Account < Default
    require :account
    permit :name, :client_id
    role :accountant do
      can :new, :create, if: :associated_with_client?
      can :update, if: :creator?, permit: :name
    end
    role :department_manager, :accountant do
      can :new, :create, :if => lambda { parent && parent.accountant == :superspecial }
    end
    
    def associated_with_client?
      parent && parent.is_a?(::Client) && parent.accountant == user.name
    end
  end

  class MongoAccount < Default
    role :accountant do
      can :new, :create, :if => :associated_with_client?
      can :update, :if => :creator?
    end
    role :department_manager, :accountant do
      can :new, :create, :if => lambda { parent && parent.accountant == :superspecial }
    end
    
    def associated_with_client?
      parent && parent.is_a?(::MongoClient) && parent.accountant == user.name
    end
  end

  class Account::Credit < Account
    role :guest do
      can :new, :create, :if => lambda { user.name == 'wife'}
    end 
  end

  class User < Default
    permit :name
  end

end
