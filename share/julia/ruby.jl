

module Ruby

	librb=dlopen("libruby") 

	export start,stop,run,alive

	global ruby_alive=false

	function start()
		ccall(dlsym(librb,:ruby_init),Void,())
		ccall(dlsym(librb,:ruby_init_loadpath),Void,())
		ruby_alive=true
	end

	function stop()
		ccall(dlsym(librb,:ruby_finalize),Void,())
		ruby_alive=false
	end

	function run(code::String)
		state=1 #not modified then
		##println(code)
		res=ccall(dlsym(librb,:rb_eval_string_protect),Ptr{Uint64},(Ptr{Uint8},Ptr{Uint32}),bytestring(code),&state)
	 	return nothing
	end

	function alive(b::Bool)
		global ruby_alive=b
	end

	function alive()
		ruby_alive
	end

end