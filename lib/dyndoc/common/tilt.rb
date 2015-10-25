require 'tilt' #this allows the use of any other template 
require 'tilt/template' #for creating the dyndoc one
require 'redcloth'


module Tilt
  
  class DynDocTemplate < Template

    def DynDocTemplate.init(libs=nil)
      unless $curDyn
        require 'dyndoc/V3/init/dyn'
        CqlsDoc.init_dyn
        CqlsDoc.set_curDyn(:V3)
        $curDyn.init(false)
        $curDyn.tmpl_doc.init_doc
        if libs
          @@libs=libs
          $curDyn.tmpl_doc.require_dyndoc_libs(libs)
        end 
        "options(bitmapType='cairo')".to_R
        $curDyn.tmpl.format_output="html"
        $curDyn.tmpl.dyndoc_mode=:web # No command line
        #p [$curDyn.tmpl.dyndocMode,$curDyn.tmpl.fmtOutput]
      end
    end

    # def init_dyndoc
    #   unless @tmpl_mngr
    #     Dyndoc.cfg_dyn['dyndoc_session']=:interactive
    #     @tmpl_mngr = Dyndoc::Ruby::TemplateManager.new({})
    #     ##is it really well-suited for interactive mode???
    #     @tmpl_mngr.init_doc({:format_output=> "html"})
    #     puts "InteractiveServer initialized!\n"
    #   end
    # end
    
    def self.engine_initialized?
      defined? ::DynDoc
    end

    def initialize_engine
    	DynDocTemplate.init
    end

    def prepare; end


    def prepare_output
		  return $curDyn.tmpl_doc.make_content(data)
    end
 
    def evaluate(scope, locals, &block)
 
#=begin
      #puts "locals";p locals
      ## first!!!!
      if locals.keys.include? :init_doc and locals[:init_doc]
          $curDyn.tmpl_doc.init_doc
          $curDyn.tmpl_doc.require_dyndoc_libs(@@libs) if @@libs
          "options(bitmapType='cairo')".to_R
          $curDyn.tmpl.format_output="html"
          $curDyn.tmpl.dyndoc_mode=:web # No command line
        #p [$curDyn.tmpl.dyndocMode,$curDyn.tmpl.fmtOutput]
          locals.delete :init_doc
      end
    	locals.each do |tag, value|
          if tag==:path
            CqlsDoc.setRootDoc($curDyn[:rootDoc],value)
          elsif tag==:libs
            @@libs=libs
          else
        	 $curDyn.tmpl.filterGlobal.envir[tag]=value
          end
      end
#=end
      $curDyn.tmpl.filterGlobal.envir["yield"]=block.call if block
    	@output=prepare_output
    	#puts @output
    	#@output
    end

  end

  class DynTtmTemplate < DynDocTemplate

    def self.engine_initialized?
      defined? ::DynTtm
    end

    def prepare_output
=begin
      ttm_preamble = <<-PREAMBLE
          \def\hyperlink#1#2{\special{html:<a href="\##1">}#2\special{html:</a>}}
            % Incorrect link name in \TeX\ because # can't be passed properly to a special.
          \def\hypertarget#1#2{\special{html:<a name="#1">}#2\special{html:</a>}}
          \long\def\ttmdump#1{#1} % Do nothing. The following are not done for TtM.
          \ttmdump{%
          \def\title#1{\bgroup\leftskip 0 pt plus1fill \rightskip 0 pt plus1fill
          \pretolerance=100000 \lefthyphenmin=20 \righthyphenmin=20
          \noindent #1 \par\egroup}% Centers a possibly multi-line title.
           \let\author=\title % Actually smaller font than title in \LaTeX.
           \input epsf     % PD package defines \epsfbox for figure inclusion
            % Macro for http reference inclusion, per hypertex.
           \def\href#1#2{\special{html:<a href="#1">}#2\special{html:</a>}}
           \def\urlend#1{#1\endgroup}
           \def\url{\begingroup \tt 
            \catcode`\_=13 % Don't know why this works.
            \catcode`\~=11 \catcode`\#=11 \catcode`\^=11 
            \catcode`\$=11 \catcode`\&=11 \catcode`\%=11
          \urlend}% \url for plain \TeX.
          PREAMBLE
=end
	    CqlsDoc::Converter.ttm($curDyn.tmpl_doc.make_content(data),"-e2 -r -y1 -L").gsub(/<mtable[^>]*>/,"<mtable>").gsub("\\ngtr","<mtext>&ngtr;</mtext>").gsub("\\nless","<mtext>&nless;</mtext>").gsub("&#232;","<mtext>&egrave;</mtext>")
    end

  end


  class DynTxtlTemplate < DynDocTemplate

    def self.engine_initialized?
      defined? ::DynTxtl
    end

    def prepare_output
       RedCloth.new($curDyn.tmpl_doc.make_content(data)).to_html
    end

  end

  class DynHtmlTemplate < DynDocTemplate

    def self.engine_initialized?
      defined? ::DynHtml
    end

  end



end

## register them!
Tilt.register Tilt::DynTxtlTemplate,  '_txtl.dyn'
Tilt.register Tilt::DynTtmTemplate,   '_ttm.dyn'
Tilt.register Tilt::DynHtmlTemplate,  '_html.dyn'
Tilt.register Tilt::DynDocTemplate,   '.dyn'
#puts "dyn registered in tilt!"