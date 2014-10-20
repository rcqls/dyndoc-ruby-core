# stuff specific to dyndoc
## Not supposed to be used by the user

require(rb4R)

init.dynArray <- function() {
  local({
    # envir and not list to immediate sync in  "[[<-.dynArray"
		Dyndoc.Vec<-list(vars=new.env())
		class(Dyndoc.Vec)<-"dynArray"
	},globalenv())
}

#<- "[.dynArray" <- "$.dynArray" 
"[.dynArray"  <- function(obj,key) {
  if(inherits(key,"formula")) key<-as.character(key)[[2]]
  .rb(paste("Dyndoc::Vector[\"",key,"\"].sync(:r)",sep=""))
  obj$vars[[key]]
}

# <- "[<-.dynArray" <- "$<-.dynArray" 
"[<-.dynArray" <-function(obj,key,value) {
  if(inherits(key,"formula")) key<-as.character(key)[[2]]
  obj$vars[[key]] <- value
  #if(sync) { # Easily convertible to Julia!  
    # Clever: no need to convert ruby object in R object (done in the ruby part!)
    ##cat("sync",key,"\n")
    .rb(paste("Dyndoc::Vector[\"",key,"\"].sync(:r)",sep=""))
    #cat("sync",key,"\n")
  #}
  obj   
}

init.dynArray()