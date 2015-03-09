# The goal is to tranform an MINGW naming file into a MSYS2 naming file

DyndocMsys2.root_path <- function(pa=NULL) {
  rp <- Sys.getenv("DYNDOC_MSYS2_ROOT")
  if(rp=="") {
    rp <- strsplit(Sys.getenv("WD"),'\\\\')[[1]]
    rp[1]<-substring(rp[1],1,1)
    rp <- c("",rp)
  }
  if(!is.null(pa)) rp <- c(rp,pa)
  paste(rp,collapse="/")
}



DyndocMsys2.global_msys2_path<-function(pa){
  if((substring(pa,1,1) %in% c("C","c","D","d","E","e","Z","z")) && substring(pa,2,2)==":")  {
    # global mingw path
    sep <- if(substring(pa,3,3)=="\\") '\\\\' else '/'
    paste(c("",substring(pa,1,1),strsplit(substring(pa,4),sep)[[1]]),collapse="/")
  } else {
    NULL
  }
}

DyndocMsys2.global_mingw_path<-function(pa){
  if((substring(pa,1,1) %in% c("C","c","D","d","E","e","Z","z")) && substring(pa,2,2)==":")  {
    # global mingw path
    sep <- if(substring(pa,3,3)=="\\") '\\\\' else '/'
    paste(substring(pa,1,1),paste(c("",strsplit(substring(pa,4),sep)[[1]]),collapse="/"),sep=":")
  } else {
    NULL
  }
}

DyndocMsys2.global_path <- function(pa) {
  root_pa <- DyndocMsys2.root_path()
  if(substring(pa,1,1)=="/") {
    # supposed to be from inside root of msys2 system (i.e. /<nodrive-rep>/...)
    paste(c(root_pa,substring(pa,2)),collapse="/")
  } else {
    DyndocMsys2.global_mingw_path(pa)
  }
}

DyndocMsys2.home_path <- function(pa=NULL) paste(c(DyndocMsys2.root_path(),"home",Sys.getenv("USERNAME"),pa),collapse="/")

tempdir <- function() DyndocMsys2.global_mingw_path(base:::tempdir())

tempfile <- function(...) DyndocMsys2.global_mingw_path(base:::tempfile(...))

system.file <- function(...) DyndocMsys2.global_mingw_path(base:::system.file(...))

save(tempdir,tempfile,system.file,list=ls(pat="DyndocMsys2*"),file="file_tools.RData")
