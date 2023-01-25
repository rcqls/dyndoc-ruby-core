
BEGINVERB="\\begin{Verbatim}[frame=leftline,fontfamily=tt,fontshape=n,numbers=left]"
ENDVERB="\\end{Verbatim}"

module Dyndoc

  @@mode=:tex

  module Ruby
  class TemplateManager
    
    def echo_verb(txt,verbatim=true,env="Global")
      txtout=Dyndoc::RServer.echo(txt,env)
      header= verbatim and txtout.length>0
      out=""
      out << BEGINVERB << "\n" if header
      out << txtout
      out << ENDVERB << "\n" if header
      out
    end

    def make_outR(tex,b,i,splitter,filter,header=true)
      normal= splitter.key[i].nil?
      if !normal
        filename=filter.apply(splitter.key[i]).strip 
        normal =  ["#","%"].include? filename[0,1]
      end
      if normal
        txt=filter.apply(b[1...-1].map{|l| l.strip}.join("\n"))
        txt=echo_verb(txt,header)
      else    
        filename=File.expand_path(filename)
        if (!File.exist?(filename))
          require 'fileutils'
          tmp=File.dirname(filename)
          FileUtils.mkdir_p(tmp) unless File.exist? tmp
          f=File.open(filename,"w")
          txt=filter.apply(b[1...-1].join("\n"))
          txt=echo_verb(txt,header)
          f << txt
          f.close
        else 
          txt=File.read(filename)
        end 
      end
      tex << "%%" << b[0] << "\n" if @echo>0
      tex << txt unless @echo<0
      tex << "%%" << b[-1] << "\n" if @echo>0  
    end

    def eval_TEX_TITLE(filter)
      ## _BEGINDOC_ already declared in DefaultPre_tmpl.tex
      if  filter.envir.global["_BEGINDOC_"] and filter.envir.global["_BEGINDOC_"][:val][0].scan(/\\maketitle/).empty?
        filter.envir.global["_BEGINDOC_"][:val][0] << "\n" unless filter.envir.global["_BEGINDOC_"][:val][0].empty?
        filter.envir.global["_BEGINDOC_"][:val][0] << "\\maketitle"
      end
    end

    def append_to_begin_document(filter,content)
      ## _BEGINDOC_ already declared in DefaultPre_tmpl.tex
      if  filter.envir.global["_BEGINDOC_"]
        filter.envir.global["_BEGINDOC_"][:val][0] << "\n" unless filter.envir.global["_BEGINDOC_"][:val][0].empty?
        filter.envir.global["_BEGINDOC_"][:val][0] << content
      end
    end

  end
  end
end
