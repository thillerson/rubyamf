# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'amf'

task :default => 'spec:run'

PROJ.name = 'amf'
PROJ.authors = 'Tony Hillerson'
PROJ.email = 'tony.hillerson@effectiveui.com'
PROJ.url = 'FIXME (project homepage)'
PROJ.version = AMF::VERSION
PROJ.rubyforge.name = 'amf'

PROJ.spec.opts << '--color'

# EOF
