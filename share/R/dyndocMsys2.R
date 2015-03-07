.dyndocMsys2 <- new.env()

source("tools/dynMsys2.R",local=.dyndocMsys2)

attach(.dyndocMsys2,name="dyndoc.msys2",pos=length(search())-1)