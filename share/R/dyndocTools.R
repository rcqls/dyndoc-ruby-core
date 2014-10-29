require(rb4R)


.dyndocEnvir <- new.env()

source("tools/dynArray.R",local=.dyndocEnvir)
source("tools/dynCapture.R",local=.dyndocEnvir)

attach(.dyndocEnvir)