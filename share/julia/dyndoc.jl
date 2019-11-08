module Dyndoc2Sandbox
	import Main.Ruby.run,Main.Ruby.alive
	import Main.Dyndoc.DynVector,Main.Dyndoc.DynArray,Main.Dyndoc.getindex,Main.Dyndoc.setindex!,Main.Dyndoc.show,Main.Dyndoc.Vector,Main.Dyndoc.sync,Main.Dyndoc.getkey
	using InteractiveUtils
end


function replace_dyndoc2sandbox(txt)
	replace(replace(txt,"Main.Dyndoc2Sandbox." => ""),"Main.Dyndoc2Sandbox" => "Main")
end

function echo_repl_julia(res)
#	buf = IOBuffer();
#	td = TextDisplay(buf);
#	display(td, res);
#	takebuf_string(buf)
#println(typeof(res))
	replace_dyndoc2sandbox(repr("text/plain",res))
end

## Rmk: The process is based on what is done in weave.jl (src/run.jl)
getstdout() = stdout #Base.STDOUT
function capture_output_expr(expr)
    #oldSTDOUT = STDOUT
    oldSTDOUT = getstdout()
    out = nothing
    obj = nothing
    rw, wr = redirect_stdout()
    reader = @async read(rw, String) # @async readstring(rw)
    try
        obj = Core.eval(Dyndoc2Sandbox, expr)
        obj != nothing && display(obj)
	#catch E
    #    throw_errors && throw(E)
    #    display(E)
    #    @warn("ERROR: $(typeof(E)) occurred, including output in Weaved document")
    
    finally
        redirect_stdout(oldSTDOUT)
        close(wr)
        out = fetch(reader) #wait(reader)
        close(rw)
    end
    return (obj, out)
end

function capture_output_julia(cmd::AbstractString)
	add,cmd0=true,AbstractString[]
	res=Any[] #Dict{AbstractString,Any}()
	#println(cmd)
	#cmd=replace(cmd,r"\$","\$")

	for l=split(cmd,"\n")
		#println("l => ",l)
		push!(cmd0,l)
		pcmd0=Base.parse_input_line(join(cmd0,"\n"))
		#print(join(cmd0,"\n")*":");println(pcmd0)
		add = typeof(pcmd0)==Expr && pcmd0.head == :incomplete
		if !add
			#print("ici:")
			#println(Base.eval(pcmd0))
			result,error,out = "","",""
			try
				result,out=capture_output_expr(pcmd0)
			catch e
				#io = IOBuffer()
				#print(io, "ERROR: ")
				#Base.error_show(io, e)
				error = "ERROR: $(sprint(showerror,e))"
				#close(io)
			end
			println(l)
			push!(res,(join(cmd0,"\n"), echo_repl_julia(result),replace_dyndoc2sandbox(out),replace_dyndoc2sandbox(error),""))
			cmd0=AbstractString[]
		end
		#println(res)
	end
	res
end
