module Dyndoc

  class UserTag

 ## peaces of do_CMD !!!!
    @@argsSep="|"
    @@tags=["debug","vars","var","txt","main","end","eol","rstrip","r","rout","rb","ruby","block","call","hide","set","if","unless","else","elsif","load","input","require","binding","envir","parent","before","after","do","close","filter"] 
    ## tag and call are of the form :  @@tagSearch[0]+@@prefix+'MACRO ou CALL'+@@tagSearch[1]
    @@prefix={:tag=>"#",:call=>"@"}
    @@tagSearch=["[","]"]
    @@tagModifiers="[#{Regexp.escape('!+/|:')}]?"
    
     def UserTag.tag_convert(txt,new=["[","#","@","]"],old=["[","","@","]"])
      res=txt.dup
      old2=old.map{|e| Regexp.escape(e)} ##escape in order to be matched!
      ## tag
      pat=@@tags.join("|")
      res.gsub!(/#{old2[0]}#{old2[1]}((?i:#{pat}))#{old2[3]}/) {|e| new[0]+new[1]+$1+new[3]}
      ## call
      res.gsub!(/#{old2[0]+old2[2]}([^#{old2[0]}]*)#{old2[3]}/) {|e|  new[0]+new[2]+$1+new[3]}
      return res
    end

    def initialize(tmpl)
      @tmpl=tmpl 
    end

    def prefix(elt,type=:tag)
      @@prefix[type]+elt+@@tagModifiers+@@prefix[type]+"?"
    end


    def evalUserTags(tex,code,filter)
      pat="[#{@@prefix[:tag]}#{@@prefix[:call]}][a-z,A-Z][a-z,A-Z,0-9,_,\\-]*"+@@tagModifiers+"[#{@@prefix[:tag]}#{@@prefix[:call]}]?"
#p pat
      #No filter yet
#puts "TXT=";p b
      txt=(@@tagSearch[0]+@@prefix[:tag]+"TXT"+@@tagSearch[1]+code).split(/#{Regexp.escape(@@tagSearch[0])}((?i:#{pat}))#{Regexp.escape(@@tagSearch[1])}/)[1..-1]
#p txt
#puts "TXT2=";p txt
      txt << "\n" if txt.length==1 and txt[0]==@@prefix[:tag]+"TXT"
#puts "TXT3=";p txt
      until txt.empty?
        @type,code=txt.shift,txt.shift
#puts "@type";p @type;p code
        @type.downcase! unless @type[0,1]==@@prefix[:call]

## special treatment for [@call@] with no parameter or default value. Redirection to [#txt]; Notice that this have to be locate before the "if code", otherwise a single call is not executed!
        if @type[-1,1]==@@prefix[:call]
          tex << @tmpl.eval_CALL(@type[1...-1],[],filter)
          @type="txt"
        end
        
# special treatment for [#tag#] with no content
        if @type[-1,1]==@@prefix[:tag]
          @type=@type[1...-1]
          parseUserTags(tex,"",filter)
          @type="txt"
        end
        
        code="" unless code
        @type=(@type[0,1]==@@prefix[:tag] ? @type[1..-1] : @type)
        parseUserTags(tex,code,filter)
      end
    end

    def parseUserTags(tex,code,filter)
      @modifier=nil
      @type,@modifier=@type[0...-1],@type[-1,1] if @@tagModifiers.include? @type[-1,1]
      p "DYN PARSING ERROR: #{@type} undeclared" unless (@@tags.include? @type) or (@tmpl.calls.keys.include? @type[1..-1])
#p @type
#p @modifier

      #delegate for tags_tex
      if Dyndoc.mode==:tex and (@@tags_tex.include? @type)
        parseUserTexTags(tex,code,filter)
      else
      
      case @type
        when "debug"
          puts "calls:";p @tmpl.calls.keys.sort
          puts "local:";p filter.envir.local
          puts "global:";p filter.envir.global
        	when "vars","var"
        #puts "vars";p code
                  args=( @modifier ? Utils.split_code_by_sep(code,@modifier) :  Utils.split_code(code) )
        #puts "args";p args
                  args.map!{|e| filter.apply(e)}
        #puts "args2";p args
        	  @tmpl.eval_VARS(args,filter) unless code.strip.empty?
        #p filter.envir.local
        #p filter.envir.global
        	when "txt","main","end","eol","do"
                  code=(code=="\n" ? [""] : code.split("\n",-1))
                  code=code[1..-1] if @type=="eol" and code.length>0
        #p code if @type=="end"
                  out=@tmpl.eval_TXT(code,filter,false)
                  filter.outType=nil
        #p out if @type=="end"
                  tex << "\n" if @modifier=="+"
        	  tex<< out  if out ##<< "\n" ##because this does not affect latex code but other doc???
        	when "filter"
                  bloc=filter.apply(code)
        	  tex << filter.apply(bloc)
        	when "rstrip"
        	  nb=( code.strip.empty? ? 1 : code.strip.to_i )
        	  tex.rstrip!
                when "r"
        #p code.strip
                  inst=code.strip
                  inst=Utils.split_code_by_sep(code.strip,@modifier).join("\n") if @modifier
                  filter.outType=":r"
        	  @tmpl.eval_RCODE(filter.apply(inst),filter) unless code.strip.empty?
                  filter.outType=nil
        	when "rout" #in fact equivalent to rtex preserved only for compatibility
                  filter.outType=":r"
        	  tex << RServer.echo(filter.apply(code.strip))
                  filter.outType=nil
        	when "rb","ruby"
        #p code.strip
                  inst=code.strip
                  inst=Utils.split_code_by_sep(code.strip,@modifier).join("\n") if @modifier
                  filter.outType=":rb"
        	  @tmpl.eval_RbCODE(filter.apply(inst),filter) unless code.strip.empty?
                  filter.outType=nil
        	when "set"
                  inst=Utils.split_code(code)
        	  key,b=nil,[]
        	  inst.each{ |v|
                    k,o,t=v.scan(/([\s,#{FilterManager.letters}]*)(!?\+?\??)=(.*)/).flatten
                    if k
                      if key
                        @tmpl.eval_SET(key,b.join("\n"),filter)
                        b=[]
                      end
                      key=k.strip+o
                      b << t
                  else
                      b << v if key
                    end
                  }
                  @tmpl.eval_SET(key,b.join("\n"),filter)  if key
                when "load","require"
                  tmpl=Utils.split_code(code).map{|e| e.strip}
        ##code.strip.split("\n").map{|e| e.split(@@argsSep)}.flatten.map{|e| e.strip}
                  @tmpl.eval_LOAD(tmpl,filter)
                when "input"
        	  unless code.strip.empty?
        	    tmpl,*args=Utils.split_code(code)
        ##code.strip.split("\n").map{|e| e.split(@@argsSep)}.flatten.map{|e| e.strip}
        ##p tmpl;p args
                    tmpl=filter.apply(tmpl.strip)
        	    tex << @tmpl.eval_INPUT(filter.apply(tmpl.strip),args,filter)
        	  end
        	when "block"
        	  unless code.strip.empty?
        	    bloc,*b=Utils.split_code(code)
        	    @tmpl.eval_FUNC(bloc,b)
        	  end
                when "if","unless","elsif","else"
                  inst=Utils.split_code(code)
        ##code.split("\n").map{|e| e.split(@@argsSep)}.flatten
                  if @type=="else"
                    @cond = !@cond
                  else
                    @cond=eval(filter.apply(inst[0]),@tmpl.rbEnvir)
                    @cond = !@cond if @type=="unless"
                    inst=inst[1..-1]
                  end
                  if @cond
                    out=@tmpl.eval_TXT(inst,filter)
        	   tex<< out  if out
        	  end
        	when "binding"
        	  unless code.strip.empty?
        	    env,*args=Utils.split_code(code)
        ##code.strip.split("\n").map{|e| e.split(@@argsSep)}.flatten.map{|e| e.strip}
        	    @tmpl.eval_BINDING(filter.apply(env.strip),args,filter)
        	  end
        	when "parent"
        	  unless code.strip.empty?
        	    @tmpl.eval_PARENT(filter.apply(code.strip),filter)
        	  end
        	when "close"
        	   nb=( code.strip.empty? ? 1 : code.strip.to_i )
        	   nb.times{filter.envir.local=filter.envir.local[:prev] if filter.envir.local[:prev]}
        	when "envir","after","before"
        	  unless code.strip.empty?
        	    env=filter.apply(code.strip)
        ## save before envir
        	    @envirs[env+"|before"]=filter.envir.local if @type=="after"
        	    env+="|before" if @type=="before"
        	    @tmpl.eval_ENVIR(env,filter)
        	  end
        	when "hide"
        ##nothing to do!!!
        	else
        	  inst=Utils.split_code(code).map{|e| e.strip}
        ##code.strip.split("\n").map{|e| e.split(@@argsSep)}.flatten.map{|e| e.strip}
        	  if @type=="call"
        #p "CAAAAAAAAAALLLLLLL"
        	    call,*args=inst
        	    call=filter.apply(call)
        	  else
        	   call,args=@type[1..-1],inst
        	  end
                  CallFilter.parseArgs(call,args)
        #puts "#call";p call;p filter.envir.local
                  call += "!" if @modifier=="!"
        	  tex << @tmpl.eval_CALL(call,args,filter) #unless code.strip.empty?
        	end
        end
    end

  end
end