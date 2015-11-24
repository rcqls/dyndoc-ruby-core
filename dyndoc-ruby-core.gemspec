
require 'rubygems/package_task'

pkg_name='dyndoc-ruby-core'
pkg_version='1.0.0'

pkg_files=FileList[
    'lib/dyndoc-core.rb',
    'lib/dyndoc/**/*.rb',
    'dyndoc/**/*',
    'share/julia/**/*',
    'share/R/**/*',
    'share/syntax/**/*',
    'dyndoc/**/.*' #IMPORTANT file starting with . are by default ignored!
]

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "R and Ruby in text document"
    s.name = pkg_name
    s.version = pkg_version
    s.licenses = ['MIT', 'GPL-2']
    s.requirements << 'none'
    s.add_dependency("configliere","~>0.4",">=0.4.18")
    #s.add_dependency("specific_install","~>0.2",">=0.2.10")
    s.require_path = 'lib'
    s.files = pkg_files.to_a
    s.description = <<-EOF
  Provide templating in text document.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end
