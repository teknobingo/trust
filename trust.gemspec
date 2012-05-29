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

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "trust/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "trust"
  s.version     = Trust::VERSION
  s.authors     = ["Patrick Hanevold"]
  s.email       = ["patrick.hanevold@gmail.com"]
  s.homepage    = "https://github.com/teknobingo/trust"
  s.summary     = "Trust is a framework for authorization control"
  s.description = <<THE_END
Well, we used DeclarativeAuthorization[http://github.com/stffn/declarative_authorization] for a while, but got stuck when it comes to name-spaces and inheritance.
So, we investigated in the possibilities of using CanCan[http://github.com/ryanb/cancan] and CanTango[http://github.com/kristianmandrup/cantango],
and found that CanCan could be slow, because all authorizations has to be loaded on every request.
CanTango has tackled this problem by implementing cashing, but the framework is still evolving and seems fairly complex.
At the same time, CanTango is role focused and not resource focused.
THE_END

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.3"

  s.add_development_dependency "sqlite3"
end
