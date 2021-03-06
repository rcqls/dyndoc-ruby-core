#cmd="a=1\n(a)\nfor i in 1:3\nprintln(i)\nend"

# # Unused! See capture_julia
# function capture_cmd(cmd::AbstractString)
# 	add,cmd0=true,AbstractString[]
# 	res=Any[] #Dict{AbstractString,Any}()
# 	for l=split(cmd,"\n")
# 		#println("l => ",l)
# 		push!(cmd0,l)
# 		pcmd0=Base.parse_input_line(join(cmd0,"\n"))
# 		#print(join(cmd0,"\n")*":");println(pcmd0)
# 		add = typeof(pcmd0)==Expr && pcmd0.head == :continue
# 		if !add
# 			#print("ici:")
# 			#println(Base.eval(pcmd0))
# 			push!(res,(join(cmd0,"\n"),eval(pcmd0)))
# 			cmd0=AbstractString[]
# 		end
# 		#println(res)
# 	end
# 	res
# end

module DyndocSandbox
	import Main.Ruby.start,Main.Ruby.stop,Main.Ruby.run,Main.Ruby.alive
	import Main.Dyndoc.DynVector,Main.Dyndoc.DynArray,Main.Dyndoc.getindex,Main.Dyndoc.setindex!,Main.Dyndoc.show,Main.Dyndoc.Vector,Main.Dyndoc.sync,Main.Dyndoc.getkey

    # Replace OUTPUT_STREAM references so we can capture output.
    OUTPUT_STREAM = IOBuffer()
    print(x) = Base.print(OUTPUT_STREAM, x)
    println(x) = Base.println(OUTPUT_STREAM, x)

    # Output
    MIME_OUTPUT = Array(Tuple, 0)
    emit(mime, data) = push!(MIME_OUTPUT, (mime, data))
end

function get_stdout_iobuffer()
	#seek(DyndocSandbox.OUTPUT_STREAM, 0)
	#jl4rb_out =
	takebuf_string(DyndocSandbox.OUTPUT_STREAM)
	#truncate(DyndocSandbox.OUTPUT_STREAM, 0)
	#jl4rb_out
end

function get_stderr_iobuffer()
	#jl4rb_out = takebuf_string(STDERR.buffer)
	#jl4rb_out
	## THIS FAILS WHEN DYNDOC DAEMONIZED SO AUTOMATIC EMPTY RESULT for now
	## MAYBE TO DELETE SOON!
	""
end

# export weave
# module DyndocSandbox
#     # Copied from Gadfly.jl/src/weave.jl
#     # Replace OUTPUT_STREAM references so we can capture output.
#     OUTPUT_STREAM = IOString()
#     print(x) = Base.print(OUTPUT_STREAM, x)
#     println(x) = Base.println(OUTPUT_STREAM, x)

#     function eval(expr)
#     	result = try
#             Base.eval(DyndocSandbox, expr)
#             seek(DyndocSandbox.OUTPUT_STREAM, 0)
#         	output = takebuf_string(DyndocSandbox.OUTPUT_STREAM)
#         	truncate(DyndocSandbox.OUTPUT_STREAM, 0)
#         	output
#         catch e
#             io = IOBuffer()
#             print(io, "ERROR: ")
#             Base.error_show(io, e)
#             tmp = bytestring(io)
#             close(io)
#             tmp
#         end
#         result
#     end
# end


function capture_julia(cmd::AbstractString)
	add,cmd0=true,AbstractString[]
	res=Any[] #Dict{AbstractString,Any}()
	#println(cmd)
	#cmd=replace(cmd,r"\$","\$")
	# for standard redirection
	##OUT: (outRead, outWrite) = redirect_stdout()
	for l=split(cmd,"\n")
		#println("l => ",l)
		push!(cmd0,l)
		pcmd0=Base.parse_input_line(join(cmd0,"\n"))
		#print(join(cmd0,"\n")*":");println(pcmd0)
		add = typeof(pcmd0)==Expr && pcmd0.head == :incomplete
		if !add
			#print("ici:")
			#println(Base.eval(pcmd0))
			result,error = "",""
			try
				result=eval(DyndocSandbox, pcmd0)
			catch e
          #io = IOBuffer()
          #print(io, "ERROR: ")
          #Base.error_show(io, e)
          error = "Error: $(string(e))"
          #close(io)
      end

			##OUT: data_out = readavailable(outRead)

			##OUT: push!(res,(join(cmd0,"\n"),echo_repl_julia(result),get_stdout_iobuffer(),data_out,error,get_stderr_iobuffer()))
			push!(res,(join(cmd0,"\n"),echo_repl_julia(result),get_stdout_iobuffer(),error,get_stderr_iobuffer()))
			cmd0=AbstractString[]
		end
		#println(res)
	end
	##OUT: close(outWrite);close(outRead)
	res
end


module Dyndoc2Sandbox
	import Main.Ruby.run,Main.Ruby.alive
	import Main.Dyndoc.DynVector,Main.Dyndoc.DynArray,Main.Dyndoc.getindex,Main.Dyndoc.setindex!,Main.Dyndoc.show,Main.Dyndoc.Vector,Main.Dyndoc.sync,Main.Dyndoc.getkey
end

function echo_repl_julia(res)
	buf = IOBuffer();
	td = TextDisplay(buf);
	display(td, res);
	takebuf_string(buf)
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
        obj = eval(Dyndoc2Sandbox, expr)
        obj != nothing && display(obj)
	catch E
        throw_errors && throw(E)
        display(E)
        @warn("ERROR: $(typeof(E)) occurred, including output in Weaved document")
    
    finally
        redirect_stdout(oldSTDOUT)
        close(wr)
        out = wait(reader)
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
          error = "Error: $(string(e))"
          #close(io)
      end

			push!(res,(join(cmd0,"\n"),echo_repl_julia(result),out,error,""))
			cmd0=AbstractString[]
		end
		#println(res)
	end
	res
end
