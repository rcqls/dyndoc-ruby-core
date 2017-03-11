

module Ruby

	librb=Libdl.dlopen(("JULIA_RUBYLIB_PATH" in keys(ENV)) ? ENV["JULIA_RUBYLIB_PATH"] : "/usr/lib/libruby")

	export start,stop,run,alive

	global ruby_alive=false

	function start()
		ccall(Libdl.dlsym(librb,:ruby_init),Void,())
		ccall(Libdl.dlsym(librb,:ruby_init_loadpath),Void,())
		ruby_alive=true
	end

	function stop()
		ccall(Libdl.dlsym(librb,:ruby_finalize),Void,())
		ruby_alive=false
	end

	function run(code::AbstractString)
		state=1 #not modified then
		##println(code)
		res=ccall(Libdl.dlsym(librb,:rb_eval_string_protect),Ptr{UInt64},(Ptr{UInt8},Ptr{UInt32}),string(code),&state)
	 	return nothing
	end

	function alive(b::Bool)
		global ruby_alive=b
	end

	function alive()
		ruby_alive
	end

end
