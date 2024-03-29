module Dyndoc

	def Dyndoc.stdout
		old_stdout,$stdout=$stdout,STDOUT
		yield
		$stdout=old_stdout
	end

	def Dyndoc.warn(*txt) # 1 component => puts, more components => puts + p + p + ....
		Dyndoc.stdout  do
			if txt.length==1
				puts txt[0]
			else
				puts txt[0]
				txt[1..-1].each do |e| p e end
			end
		end
	end

	module Utils
		def Utils.cfg_file_exist?(tmpl)
	      name=File.join(File.dirname(tmpl),File.basename(tmpl,".*"))
	      ([".cfg_dyn",".dyn_cfg"].map{|ext| name+ext}.select{|f| File.exist? f})[0]
	    end

	    def Utils.lib_file_exist?(tmpl)
	      name=File.join(File.dirname(tmpl),File.basename(tmpl,".*"))
	      (["_lib.dyn",".dyn_lib"].map{|ext| name+ext}.select{|f| File.exist? f})[0]
	    end

	    def Utils.out_rsrc_exist?(tmpl)
	      name=File.join(File.dirname(tmpl),File.basename(tmpl,".*"))
	      ## if not a directory it is the zipped version! TODO! 
	      ([".dyn_out",".dyn_rsrc"].map{|ext| name+ext}.select{|f| File.exist? f})[0]
	    end

	    def Utils.mkdir_out_rsrc(tmpl)
	    	require 'fileutils'
	    	#p File.join(File.dirname(tmpl),File.basename(tmpl,".*")+".dyn_out")
	    	FileUtils.mkdir_p File.join(File.dirname(tmpl),File.basename(tmpl,".*")+".dyn_out")
	    end

    end

    def Utils.dyndoc_globvar(key,value=nil)
		if value
            if [:remove,:rm,:del,:delete].include?  value
                Dyndoc.tmpl_mngr.filterGlobal.envir.remove(key)
            else
			     Dyndoc.tmpl_mngr.filterGlobal.envir[key]= value
            end
		else
			Dyndoc.tmpl_mngr.filterGlobal.envir[key]
		end
	end

	def Utils.is_windows?
		RUBY_PLATFORM =~ /(win|msys|mingw)/
	end

end