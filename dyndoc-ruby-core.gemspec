
require 'rubygems/package_task'

PKG_NAME='dyndoc-ruby-core'
PKG_VERSION='1.0.0'

PKG_FILES=FileList[
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
    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.licenses = ['MIT', 'GPL-2']
    s.requirements << 'none'
    #s.add_dependency("configliere","~>0.4",">=0.4.18")
    #s.add_dependency("specific_install","~>0.2",">=0.2.10")
    s.require_path = 'lib'
    s.files = PKG_FILES.to_a
    s.description = <<-EOF
  Provide templating in text document.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end
