

module Dyndoc


using Main.Ruby

import Base.setindex!,Base.getindex,Base.IO,Base.show #,Base.showarray
import Main.Ruby.start,Main.Ruby.stop,Main.Ruby.run,Main.Ruby.alive

export DynVector,DynArray,getindex,setindex!,show,Vector,sync,getkey

# this is just a wrapper of Vector type with update of all connected vectors
# when change on the vector occurs


mutable struct DynVector
	ary::Vector
	key::String

	#DynVector(a::Vector,k::String)=(x=new();x.ary=a;x.key=k;x)
end

function getindex(dynvect::DynVector,i::Integer)
	#if Ruby.alive() Ruby.run("Dyndoc::Vector[\""*dynvect.key*"\"].sync_to(:jl)") end
	dynvect.ary[i]
end

function setindex!(dynvect::DynVector,value,i::Integer)
	dynvect.ary[i]=value
	## println("inisde vect:",Ruby.alive())
	if Ruby.alive()
		Ruby.run("Dyndoc::Vector[\""*dynvect.key*"\"].sync(:jl)")
	end
end

show(io::IO,dynvect::DynVector)=show(io,dynvect.ary)

# gather all the julia vectors connected to dyndoc.

mutable struct DynArray
	vars::Dict
	DynArray()=(x=new();x.vars=Dict();x)
end

global const Vec=DynArray()

function getindex(dynary::DynArray,key::String)
	#println("getindex(" * key * ")->todo")
	#if Ruby.alive()
		#println("getindex(" * key * ")->to sync")
		#Ruby.run("Dyndoc::Vector[\""*key*"\"].sync_to(:jl)")
	#end
	#println("getindex(" * key * ")->done")
	dynary.vars[key]
end
getindex(dynary::DynArray,key::Symbol)=getindex(dynary,string(key))

function setindex!(dynary::DynArray,value,key::String)
	#println("key:" * key)
	#println(keys(dynary.vars))
	if(haskey(dynary.vars,key))
		#println("haskey" * key)
		dynary.vars[key].ary=value
	else
		dynary.vars[key]=DynVector(value,key)
	end

	## println("inside array:",Ruby.alive())

	if Ruby.alive()
		Ruby.run("Dyndoc::Vector[\""*key*"\"].sync(:jl)")
	end
end
setindex!(dynary::DynArray,value,key::Symbol)=setindex!(dynary,value,string(key))


sync(dynary::DynArray,key::String)= if Ruby.alive() Ruby.run("Dyndoc::Vector[\""*key*"\"].sync(:jl)") end

show(io::IO,dynary::DynArray)=show(io,dynary.vars)

# NO MORE KEY WITH THE FORM "<name>@<ruby id object>"
# function getkey(dynary::DynArray,k::Symbol)
# 	for k2 in keys(dynary.vars)
# 	 	if split(k2,"@")[1] == string(k)
# 	 		return k2
# 	 	end
# 	end
# 	return "#undef"
# end
# getindex(dynary::DynArray,key::Symbol)=getindex(dynary,getkey(dynary,key))
# setindex!(dynary::DynArray,value,key::Symbol)=setindex!(dynary,value,getkey(dynary,key))

end
