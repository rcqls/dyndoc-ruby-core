require 'dyndoc/base/helpers/core'

#Dyndoc.warn "path helpers",File.join(File.dirname(__FILE__),"helpers/**/*.rb").gsub('\\','/')
#Dyndoc.warn "helpers",Dir[File.join(File.dirname(__FILE__),"helpers/**/*.rb").gsub('\\','/')]

Dir[File.join(File.dirname(__FILE__),"helpers/**/*.rb").gsub('\\','/')].each{|lib|
  require lib unless File.basename(lib,".rb")=="core"
}

