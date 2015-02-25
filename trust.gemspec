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
  s.authors     = ["Patrick Hanevold", "Knut I Stenmark"]
  s.email       = ["patrick.hanevold@gmail.com", "knut.stenmark@gmail.com"]
  s.homepage    = "https://github.com/teknobingo/trust"
  s.summary     = "Trust is a framework for authorization control in RubyOnRails"
  s.description = <<THE_END
Trust is a resource oriented framework for authorization control. It has a loose coupling from the models, and features a native
Ruby implementation language. Support for inheritance and namespaced models as well as nested routes. Even permissions scheme supports inheritance.
THE_END

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.0.0"
  s.add_dependency "activesupport", ">= 4.0.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mocha"
end
