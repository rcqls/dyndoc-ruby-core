require "dyndoc/common/utils"
require "dyndoc/base/utils"
require "dyndoc/base/tmpl"
require "dyndoc/base/tags"
require "dyndoc/base/filters"
require "dyndoc/base/envir"
require "dyndoc/base/scanner"
require "dyndoc/plugins/tex"
require "dyndoc/base/utils/convert"
require "dyndoc/base/helpers"
require "configliere"

Settings.use :env_var, :config_block

require 'dyndoc/init/home'
Settings.define 'path.dyn_home', :env_var => 'DYN_HOME', :description => "dyndoc home path", :default => Dyndoc.home

Settings.define 'cfg_dyn.etc_path_subdir', :type => Array, :default => ["path","core"]

Settings.define 'cfg_dyn.pre_tmpl', :type => Array, :default => []
Settings.define 'cfg_dyn.post_tmpl', :type => Array, :default => []
Settings.define 'cfg_dyn.part_tag', :type => Array, :default => []
Settings.define 'cfg_dyn.out_tag', :type => Array, :default => []
Settings.define 'cfg_dyn.doc_list', :type => Array, :default => []
Settings.define 'cfg_dyn.tag_tmpl', :type => Array, :default => []
Settings.define 'cfg_dyn.keys_tmpl', :type => Array, :default => []
Settings.define 'cfg_dyn.user_input', :type => Array, :default => []
Settings.define 'cfg_dyn.cmd_doc', :type => Array, :default => [:make_content,:save]
Settings.define 'cfg_dyn.cmd_pandoc_options', :type => Array, :default => []
Settings.define 'cfg_dyn.options.pdflatex_nb_pass', :type => Integer, :default => 1
Settings.define 'cfg_dyn.options.pdflatex_echo', :type => :boolean, :default => false

Settings.define 'cfg_dyn.dyndoc_session', :type => Symbol, :default => :normal #or :interactive

Settings.define 'cfg_dyn.dyndoc_mode', :type => Symbol, :default => :normal
Settings.define 'cfg_dyn.docker_mode', :type => :boolean, :default => false
Settings.define 'cfg_dyn.working_dir', :type => String, :default => ""
Settings.define 'cfg_dyn.root_doc', :type => String, :default => ""
Settings.define 'cfg_dyn.nbChar_error', :type => Integer, :default => 300
Settings.define 'cfg_dyn.langs', :type => Array, :default => ["R"]

Settings.define 'cfg_dyn.devel_mode', :type=> Symbol, :default=> :none
Settings.define 'cfg_dyn.ruby_debug', :type=> Symbol, :default=> :none

Settings.define 'cfg_dyn.model_doc', :default => "default"
Settings.define 'cfg_dyn.format_doc', :default => :tex

Settings.finally do |c|
	c['cfg_dyn.langs'].map!{|e| e.to_sym}
end

Settings.resolve!
require 'dyndoc/init/config'
Dyndoc.init_dyndoc_library_path
Dyndoc.init_rootDoc

CqlsDoc=Dyndoc #for compatibity