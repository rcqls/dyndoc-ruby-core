 
module Dyndoc
  module Ruby
  class TemplateManager
    
    @@cmd=["title",""]+@@cmd

    def do_title(tex,blck,filter)
=begin
      mode=""
      mode=filter.apply(splitter.key[i].strip).downcase if splitter.key[i]
      ## apply R filtering
      txt=filter.apply(b[1...-1].join("\n"))
      ## _TITLE_ is redefined!
      eval_TITLE(txt,filter,mode)
=end
    end

    def do_list(tex,blck,filter)

    end
    
  end
  end
end
