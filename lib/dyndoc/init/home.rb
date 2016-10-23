module Dyndoc
	def Dyndoc.home
		dyndoc_home = File.join(ENV['HOME'],'dyndoc')
		dyndoc_home =  File.read(File.join(ENV['HOME'],'.dyndoc_home')).strip if File.exists? File.join(ENV['HOME'],'.dyndoc_home')
		dyndoc_home = File.expand_path(dyndoc_home)
		#puts "dyndoc_home: "+ dyndoc_home
		dyndoc_home
	end

	def Dyndoc.home=(value)
		File.open(File.join(ENV['HOME'],'.dyndoc_home'),"w") do |f|
			f << value.strip
		end
	end
end
