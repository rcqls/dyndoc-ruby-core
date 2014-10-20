 
module Dyndoc
 
  class UserTag

    @@tags_tex=["rtex","rverb","title","preamble","usepackage","postamble","begindoc","enddoc"]
    ## update @@tags
    @@tags += @@tags_tex
    @@tex_vars={"usepackage"=>"_USEPACKAGE_","preamble"=>"_PREAMBLE_","postamble"=>"_POSTAMBLE_","begindoc"=>"_BEGINDOC_","enddoc"=>"_ENDDOC_"}


    def parseUserTexTags(tex,code,filter)
      case @type
      when "rverb","rtex"
        @out_type="#r"
        header= @type=="rverb"
        tex << @tmpl.echo_verb(filter.apply(code.strip),header).lstrip
      when "title"
        mode= (@modifier=="!" ? "" : "+")
        @tmpl.eval_TITLE(filter.apply(code.strip),filter,mode)
      when "preamble","usepackage","postamble","begindoc","enddoc"
        mode= "+"
        if @modifier=="!"
          mode = ""
        end 
        @tmpl.eval_TEXVAR(@@tex_vars[@type],filter.apply(code.strip),filter,mode)
      end
    end
    
  end

end
