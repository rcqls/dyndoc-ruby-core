toto <-list(vars=list())
class(toto)<-'TOTO'
"[[<-.TOTO" <- function(obj,key,value) {
	obj$vars[[key]] <- value
	cat("inside []<-\n")
	obj
}

"[[.TOTO" <- function(obj,key) {
	cat("inside []\n")
	obj$vars[[key]]
}

toto[["titi"]] <- "TUTU"