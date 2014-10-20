require 'dyndoc-core'
tmplMngr=Dyndoc::Ruby::TemplateManager.new
tmplMngr.init_doc({})
p tmplMngr.parse("{#document][#require]Tools/R/Fig[#main][#R<]print(rnorm(10))[#>]toto[#document}")