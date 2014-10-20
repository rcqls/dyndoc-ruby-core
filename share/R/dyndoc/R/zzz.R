
.First.lib <- function(lib,pkg) {
  local({
    if(!exists(".filter.capture")) .filter.capture <-list(NULL,function(x) paste("\\textcolor{blue}{",x,"}",sep=""))
  },.GlobalEnv)
}

