require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
    s.platform          = Gem::Platform::RUBY
    s.name              = "rubyamf"
    s.version           = "0.1"
    s.author            = "Tony Hillerson"
    s.email             = "tony.hillerson+rubyamf_gem@gmail.com"
    s.summary           = "A gem for serializing and deserializing AMF messages."
    s.files             = FileList['lib/*.rb', 'test/*'].to_a
    s.require_path      = "lib"
    # s.autorequire       = "ip_admin"
    s.test_files        = Dir.glob('tests/*.rb')
    s.has_rdoc          = true
    s.extra_rdoc_files  = ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end

