
capture.output.cqls<-function(code) {
	res2<-try.cqls(res<-capture.output(code),TRUE)
	if(inherits(res2,"try-error")) {
	  res2
	} else res
}

capture.output.protected<-function(code) {
	res2<-try(res<-capture.output(code),TRUE)
	if(inherits(res2,"try-error")) {
	  res2
	} else res
}

try.cqls<-function (expr, silent = FALSE)
{
    tryCatch(expr, error = function(e) {
        call <- conditionCall(e)
        if (!is.null(call)) {
            if (identical(call[[1]], quote(doTryCatch)))
                call <- sys.call(-4)
            dcall <- deparse(call)[1]
	    if( (substr(dcall,1,7)=="try.cqls(") || dcall=="eval.with.vis(expr, pf, baseenv())" || dcall=="eval(expr, envir, enclos)" ) prefix <- 
"Erreur : "
            else prefix <- paste("Erreur dans", dcall, ": ")
            LONG <- 75
            msg <- conditionMessage(e)
            sm <- strsplit(msg, "\n")[[1]]
            if (14 + nchar(dcall, type = "w") + nchar(sm[1],
                type = "w") > LONG)
                prefix <- paste(prefix, "\n  ", sep = "")
        }
        else prefix <- "Erreur : "
        msg <- paste(prefix, conditionMessage(e), "\n", sep = "")
        .Internal(seterrmessage(msg[1]))
        if (!silent && identical(getOption("show.error.messages"),
            TRUE)) {
            cat(msg, file = stderr())
            .Internal(printDeferredWarnings())
        }
        invisible(structure(msg, class = "try-error"))
    })
}

init.filter.capture<-function(in.filter,out.filter) {
        if(!missing(in.filter)) .filter.capture[[1]]<<-in.filter
        if(!missing(out.filter)) .filter.capture[[2]]<<-out.filter
        #print(.filter.capture)
        return(invisible())
}

filter.capture.output<-function (...,filter=.filter.capture) {
        args <- substitute(list(...))[-1]
        file <- textConnection("res.val","w",local=TRUE)
        sink(file)
        pf <- parent.frame()
        evalVis <- function(expr) .Internal(eval.with.vis(expr, pf, baseenv()))
        expr <- args[[1]]
        if (mode(expr) == "expression")
          tmp <- lapply(expr, evalVis)
        else if (mode(expr) == "call")
          tmp <- list(evalVis(expr))
        else if (mode(expr) == "name")
          tmp <- list(evalVis(expr))
        else stop("bad argument")
        for (item in tmp) {if(item$visible)  res<-item$value}
        print(res)
        sink()
        close(file)
        if(!is.null(filter[[1]])) {
          res.in<-if(is.function(filter[[1]])) sapply(res,filter[[1]]) else filter[[1]]
          tmp<-strsplit(paste(res.val,collapse=" [LiNe]")," ")[[1]]
          tmp2<-(regexpr('^\\[.*\\]$',tmp)!=1 & tmp!="" )
          new<-tmp[tmp2]
          new[res.in]<-sapply(new[res.in],filter[[2]])
          tmp[tmp2]<-new
          return(paste(strsplit(paste(tmp,collapse=" "), " \\[LiNe\\]" )[[1]],collapse="\n"))
        } else return(res.val)
}
