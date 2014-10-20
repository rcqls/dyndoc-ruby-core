# Objectif du Scanner:
#   1) Gestion du parsing en mode dtag
#     .) Imbrication des blocs :dtag  {%...%}
#     .) Bloc texte est splitté en une alternance de blocs :main et de blocs :dtag {%...%}
#     .) Sortie de process en une structure: 
# ex: [[:main,"..."] [:if, [:args,"...",[...]"],[:main,"..."],:else,[:main,"..."]] 
#     .) NEW: un bloc peut être inséré dans un argument :args 
#     TODO: 1) desescaper le délimiteur dans :args
#   2) Gestion du parsing des appels fonctions @{...}@
#     TODO
#   3) TODO: imbrication des modes #{} :{} et :R{} à gérer
# RMK: 1) a-t-on besoin d'autant de mode? A réfléchir mais c'est en fonction des priorités d'exécution.
#   2) Il y a 4 grands modes d'utilisation:
#     a) Mode imbriqué blocks dtag : {% ...%} 
#       rmk: exécution d'un block intérieur après le bloc :main précédent du block principal!
#     b) Mode séquentiel Part tags : %() utiles dans pour le multi-output
#     c) Mode séquentiel Utilisateur : [#...]
#     d) Mode imbriqué dans blocks texte : #[r,R,Rb]{}, :[R,r]{} , @{}@
#       rmk: exécution des blocks intérieurs avant le block principal 

require 'strscan'

if RUBY_VERSION < "1.9"
  
  class String
    alias :byteslice :"[]"
  end

end

module Dyndoc
  class Scanner
    
    @@type={}

    @@close={"("=>")","["=>"]","{"=>"}"}
    @@open={"}"=>"{",")"=>"(","]"=>"["}

    #IMPORTANT: start and close delimiters are unique and not useable inside text!
    #RMK: this differs from the actual CallManager

    attr_reader :scan

    def initialize(type,start=nil,stop=nil,mode=nil,escape=nil)
      @tag_type=type
      @tag=@@type[type]
      @start=@tag[:start] unless start
      @start=/#{@start}/ if @start.is_a? String
      @stop=@tag[:stop] unless stop
      @stop=/#{@stop}/ if @stop.is_a? String
      @mode=@tag[:mode] unless mode
      @escape={:start=>@tag[:escape_start],:stop=>@tag[:escape_stop]} unless escape
      #mode corresponds to @start[@mode[:start],@mode[:length]] and @stop[@mode[:stop],@mode[:length]]
      init_strange
      @scan=StringScanner.new("")
    end 

    ######################################
    # stack is a sequence of delimiters
    # clean_stack selects only the associated open and closed delimiters!
    #####################################
    def clean_stack(stack)
      open_stack,keep=[],{}
      stack.each do |elt|
        if elt[1]==1
          open_stack << elt 
        else
          if open_stack.empty?
            ##too many closed delimiters
          else
            keep[elt]=true
            keep[open_stack.pop]=true
          end
        end
      end
=begin
      if Dyndoc.cfg_dir[:debug]
        tmp=stack.select{|elt| !keep[elt]}.select{|e| @tag_type==:call and e[2] and e[1]==1 and e[2]!='{'}
        begin p @txt;p tmp  end unless tmp.empty?
      end
=end
      stack.select{|elt| keep[elt]}
    end

    def token_stack
      @scan.string=@txt
      @scan.pos=0
      stack,s=[],0
      mode=-2 #stop
      begin
        if mode!=-1
          p1=@scan.check_until(@start)
          if p1
            s1=@scan.pre_match.size
            m1=@scan.matched
          end
        end
        if mode!=1
          p2=@scan.check_until(@stop)
          if p2 
            s2=@scan.pre_match.size
            m2=@scan.matched
          end
        end
        if p1 and p2
          mode=(s1<s2 ? 1 : -1)
        elsif p2 and !p1
          mode=-1
        elsif !p2 and p1
          mode=-3 #error
        elsif !p2 and !p1
          mode=-2 #stop
        end
        if mode==1
          stack << [s1,mode,m1] unless @escape[:start] and @escape[:start].include? m1
          @scan.scan_until(@start)
        elsif mode==-1
          s=s2
          stack << [s2,mode,m2] unless @escape[:stop] and @escape[:stop].include? m2
          @scan.scan_until(@stop)
        end
        s=@scan.pos
      end while mode>-2
      return clean_stack(stack)
    end

    def init_atom
      if @tag[:atom]
        @txt.gsub!(@tag[:atom][:match]){|w| 
          m=@tag[:atom][:match].match(w)
          res=""
          (1...m.size).each{|i| 
            res << (@tag[:atom][:replace][i] ? @tag[:atom][:replace][i] : m[i])
          }
          res
        }
      end
    end

    def tokenize(txt)
      @txt=txt
      init_atom
      stack=token_stack
#p txt
#p stack
      stack2=[]
      root=block={:inside=>[]} #init bloc
      while !stack.empty?
        elt=stack.shift
        #puts "stack2";p stack2
        if elt[1]==1
          #new bloc
          parent=block
          block={:type=>elt[2][0...-1],:start=>elt[0],:inside=>[]} 
          stack2 << [block,parent]
        elsif elt[1]==-1
          block,parent=stack2.pop
          block[:stop]=elt[0]+elt[2].size-1
          if parent[:start]
            block[:start] -= parent[:start]
            block[:stop] -=  parent[:start]
          end
          parent[:inside] << block
          block=parent
        end
      end
      return (@token={:txt=> @txt,:inside=> (root[:inside])})
    end

## Extract a structure with a root block which is a text block and the child blocks which are dtag blocks. 
    @@strange="_[_?_]_"

    def init_strange(strange=@@strange)
      @strange=strange 
      @re_strange=/#{Regexp.escape(@strange)}/
      @re_strange2=/(#{Regexp.escape(@strange)})/
    end

    def extract(res=nil,txt=nil,type=nil)
      if res
        start=0
        txt2=""
        ind=0
        res2=res.map{|r|
          txt2 << txt[start...(r[:start])]
          txt2 << @@strange
          ind += 1
          r2={}
          start=r[:stop]+1
          if r[:inside].empty?
            r2[:txt]=txt[(r[:start])..(r[:stop])]
            r2[:type]=r[:type]
            r2
          else
            tmp=extract(r[:inside],txt[(r[:start])..(r[:stop])],r[:type])
            tmp
          end
        }
        txt2 << txt[start..-1]
        {:txt=>txt2,:type=>type,:inside=> res2}
      else
        res=@token[:inside].dup
        return extract(res,@token[:txt])
      end
    end

    def rebuild_after_filter(res,filter=nil)
      txt=""
      start=0
#p res
      parts=res[:txt].split(@re_strange,-1)
##puts "parts";p parts
##puts "inside";p res[:inside]
      res[:inside].map do |e|
        txt << parts.shift

        txt2= (e[:inside] ? rebuild_after_filter(e,filter) : e[:txt] )
#puts "txt2";p txt2; p [res[:type],e[:type]]
        #IMPORTANT: process has to have as the second argument e[:type] corresponding to the inside_type and as the third argument res[:type] corresponding to the out_type
##Dyndoc.warn "scan",txt2,e[:type],res[:type],(filter ? filter.process(txt2,e[:type],res[:type]) : txt2)
        txt2=((filter and !(txt2=~/\[HTML\]/)) ? filter.process(txt2,e[:type],res[:type]) : txt2)
##p txt2
        txt << txt2
      end
#puts "txt";p txt
      txt << parts.shift unless parts.empty?
      txt
    end

  end

  class CallScanner < Scanner

    @@type[:call]={
          :start=>/\\?(?:\#|\#\#|@|#F|#R|#r|\:R|\:r|#Rb|#rb|\:|\:Rb|\:rb|\:jl|#jl)?\{/,
          :stop=>     /\\?\}/,
          :mode=>{:start=>-1,:stop=>0,:length=>1},
          :escape_start=>['\{'], #doivent être parsable dans start
          :escape_stop=>['\}'], #doivent être parsable dans stop
        }

    def initialize(type=:call,start=nil,stop=nil,mode=nil,escape=nil)
      super
      @type_stop_filter="#!"
    end
  end

  class DevTagScanner < Scanner
    
=begin TO_REMOVE
      @@type[:dtag] = {
          :start=>'\{%(\w*)',
          :stop=>  '%\}',
          :keyword=>['%',''],
          :block=> '[\]|]',
          :mode=>{:start=>0,:stop=>-1,:length=>1}
        }
=end
      @@type[:dtag] = {
          :start=>'\{[\#\@]([\w\:\|-]*[<>]?[=?!><]?(\.\w*)?)\]',
          :stop=>  '\[[\#\@]([\w\:\|-]*[<>]?[=?!><]?)\}',
          :atom=>{:match=>/(\{[\#\@][\w\:\|]*)([\#\@]\})/,:replace=>{2=>"][#}"}},
          :block=> '\]', #no longer | 
          :keyword=>['\[[\#\@]','\]'],
          :mode=>{:start=>0,:stop=>-1,:length=>1}
        }
      
    def get_tag_blck
      @@tagblck_set
    end


    def initialize(type=:dtag,start=nil,stop=nil,mode=nil,escape=nil)
      super
      init_tag(@tag_type) if [:dtag].include? @tag_type
    end

    @@tagblck_set=[:<<,:<,:do,:>>,:>,:">!",:out,:nl,:"\\n",:"r<",:"R<",:"rb<",:"m<",:"M<",:"jl<",:"r>>",:"R>>",:rverb,:"rb>>",:rbverb,:"jl>>",:jlverb,:rout,:"r>",:"R>",:"rb>",:"m>",:"M>",:"jl>",:"_<",:"_>",:"__>",:"html>",:"tex>",:"txtl>",:"ttm>",:"md>",:tag,:"??",:"?",:yield,:"=",:"-",:+,:"%"]
    #Rmk: when a symbol is included in another one, you have to place it before! Ex: :>> before :> and also :<< before :<
    @@tag_blck=[] #to cancel soon!!

    TXT_DTAG=[:txt,:code,:>,:<,:<<]

    @@dtag={
=begin TO_REMOVE
      :dtag => {
        :instr=>["input","require","hide","if","unless","loop","case","var","set","def","func","do","out","call","r","rverb","rb"],
        :alias=>{
          :vars=>:var
        },
        :empty_keyword=>[""],
        :keyword=>{
          :if=> [:else,:elsif,:if,:unless]+@@tagblck_set,
          :unless=> [:else,:elsif,:if,:unless]+@@tagblck_set,
          :loop=>[:break]+@@tagblck_set,
          :case=>[:when,:else]+@@tagblck_set,
          :var=>[:","],
          :def=>[:","]+@@tagblck_set,
          :do=>@@tagblck_set,
          :out=>@@tagblck_set,
          :call=>[:","],
          :input=>[:","]
        },
	:named_tag=>{}, #for compatibility with dtag2 but empty!
        :mode_arg=>:find,
        :arg=>[:if,:unless,:elsif,:case,:def,:func,:call,:input,:when,:break,:set],
        :blck=>{
          :instr=>[:if,:unless,:case,:loop],
          :keyword=>{
            :if=>[:if,:unless,:elsif,:else],
            :unless=>[:if,:unless,:elsif,:else],
            :case=>[:when,:else],
            :loop=>[:loop,:break]
          }
        },
	:style=>"@@@" #to avoid to be parsed!
      },
=end
      :dtag => {
        :instr=>["newBlck","input","require","hide","format","txt",">","<","<<",">>","code","verb","if","unless","for","loop","case","var","set","def","func","meth","new","super","do","out","blck","blckAnyTag","saved","b>","call","R","r","m","M","jl","renv","rverb","rbverb","jlverb","rout","rb","eval","ifndef","tags","keys","opt","document","yield","get","part"],
        :alias=>{
          :vars=>:var,
          :dyn=>:eval,
	        :rmk=>:hide,
          :static => :saved,
          :comment=>:hide,
          :>> => [:blck,:>], 
          #:"b>" => [:blck, :>],
          :"rb>" => [:blck, :"rb>"],
          :"R>" =>  [:blck, :"R>"],
          :"jl>" => [:blck, :"jl>"],
          :"jl>>" => [:blck, :"jl>>"],
          :"rb<" => [:blck, :"rb<"],
          :"R<" =>  [:blck, :"R<"],
          :"jl<" => [:blck, :"jl<"],
          :"r>>" => [:blck, :"r>>"],
          :"R>>" => [:blck, :"r>>"],
          :"*<" =>  [:blck, :"*<"],
          :"*>" =>  [:blck, :"*>"],
          :"_>" =>  [:blck, :"_>"],
          :"tex>" =>  [:blck, :"tex>"],
          :"html>" =>  [:blck, :"html>"],
          :"txtl>" =>  [:blck, :"txtl>"],
          :"md>" =>  [:blck, :"md>"],
          :"ttm>" =>  [:blck, :"ttm>"]
        },
        :empty_keyword=>["?","empty"],
        :keyword=>{
	        :document => [:main,:content,:class,:optclass,:require,:helpers,:preamble,:postamble,:style,:package,:title,:path,:first,:last,:texinputs]+@@tag_blck,
          :if=> [:else,:elsif,:if,:unless]+@@tag_blck,
          :unless=> [:else,:elsif,:if,:unless]+@@tag_blck,
	        :for=>@@tag_blck,
          :loop=>[:break]+@@tag_blck,
          :case=>[:when,:else]+@@tag_blck,
          :var=>[:","],
          :set=>@@tag_blck,
          :def=>[:",",:binding]+@@tag_blck,
          :meth=>[:","]+@@tag_blck,
          :new=>[:",",:of,:in,:blck]+@@tag_blck,
          :super=>[:",",:parent,:blck]+@@tag_blck,
          :do=>@@tag_blck,
          :out=>@@tag_blck,
          :blck=>@@tag_blck,
          :saved=>@@tag_blck,
          :call=>  [:",",:blck]+@@tag_blck,
	        :style=> [:of,:",",:blck,:default]+@@tag_blck,
          :input=>[:","],
          :r=>[:in],
          :rverb=>[:in,:mode]+@@tag_blck,
          :rbverb=>[:mode]+@@tag_blck,
          :jlverb=>[:mode]+@@tag_blck,
	        :rout=>[:in,:mode]+@@tag_blck,
          :eval=>[:to],
          :ifndef=>[:<<],
          :tags=>[:when]+@@tag_blck,
      	  :keys=> @@tag_blck,
      	  :part=>@@tag_blck,
      	  :get=>[:blck]
        },
      	:keyword_reg=>{ #to overpass :keyword
      	  :new=> '[%.\w,><?=+:-]+',
      	  :call=> '[%.\w,><?=+:-]+(?:\@|\$)?',
      	  :style=>'[%.\w,><?=+:-]+',
          :newBlck=>'[%.\w,><?=+:-]+',
          :blckAnyTag=>'[%.\w,><?=+:-]+',
      	},
      	:with_tagblck =>[:document,:if,:unless,:for,:loop,:case,:set,:def,:meth,:new,:super,:do,:out,:blck,:saved,:call,:style,:rverb,:rbverb,:jlverb,:rout,:tags,:keys,:part],
      	:named_tag=>{
      #=begin
      	  :> => {:tag=>'(_TAG_)(?:[^\]]+)?',:rest=>/^>([^\]]*)$/},
      	  :>> => {:tag=>'(_TAG_)(?:[^\]]+)?',:rest=>/^>>([^\]]*)$/},
      	  :"r>" => {:tag=>'(_TAG_)(?:[^\]]+)?',:rest=>/^r>([^\]]*)$/},
      	  :"rb>" => {:tag=>'(_TAG_)(?:[^\]]+)?',:rest=>/^rb>([^\]]*)$/},
      	  :"=" => {:tag=>'(_TAG_)(?:[^\]]+)?',:rest=>/^=([^\]]*)$/}
      #=end
      	},
        :mode_arg=>:next_block,
        :tag_code=>[:code,:<,:>,:<<,:txt], #used for arg mode!
        :arg=>[:if,:unless,:elsif,:for,:case,:def,:func,:meth,:new,:super,:call,:input,:when,:break,:set,:style,:keys,:"?",:"rb<",:"r<",:"R<",:"m<",:"M<",:"jl<"],
        :blck=>{
          :instr=>[:document,:if,:unless,:case,:loop,:set,:tag,:keys,:rverb,:rbverb,:jlverb,:for],
          :keyword=>{
            :document=>[:content,:main,:class,:optclass,:preamble,:postamble,:style,:package,:title,:require,:helpers,:path,:texinputs,:first,:last],
            :set=>[:set],
            :if=>[:if,:unless,:elsif,:else],
            :unless=>[:if,:unless,:elsif,:else],
            :case=>[:when,:else],
            :loop=>[:loop,:break],
            :tags=>[:when],
      	    :rverb=>[:rverb,:in,:mode],
            :rbverb=>[:rbverb,:mode],
            :jlverb=>[:jlverb,:mode],
      	    :rout=>[:rout,:in,:mode]
          }
        },
        :style=>"@" #specify that the scanner recognize a style instead a call when blck[:type].include? "@"
      }
    }

    attr_accessor :dtag
     
    def init_tag(type=:dtag)
      @dtag=@@dtag[type]
      @tag_instr=@dtag[:instr]+@dtag[:alias].keys.map{|e| e.to_s}
      @tag_alias=@dtag[:alias]
      @tag_keyword=@dtag[:keyword]
      @tag_keyword_reg=@dtag[:keyword_reg]
      @tag_arg=@dtag[:arg]
      @tag_code=(@dtag[:tag_code] ? @dtag[:tag_code] : [] )
      @tag_style=@dtag[:style]
      @tag_blck=@dtag[:blck]
      ## deal with fixed blck tags
      @named_tags=[]
      @@keystagblck=@@tagblck_set.map{|e| complete_tag(e)}.compact.join("|") #only once!
      @@named_tags_blck=@named_tags
    end

    def merge_tag(dtag)
      if dtag
      	@tag_instr += dtag[:instr] if dtag[:instr]
      	@tag_instr += dtag[:alias].keys.map{|e| e.to_s} if dtag[:alias]
      	@tag_alias.merge!(dtag[:alias]) if dtag[:alias]
      	@tag_keyword.merge!(dtag[:keyword]) if dtag[:keyword]
      	@tag_keyword_reg.merge!(dtag[:keyword_reg]) if dtag[:keyword_reg]
      	@tag_arg += dtag[:arg] if dtag[:arg]
      	if dtag[:blck]
      	  @tag_blck[:instr] += dtag[:blck][:instr] if dtag[:blck][:instr]
      	  @tag_blck[:keyword].merge!(dtag[:blck][:keyword]) if dtag[:blck][:keyword]
      	end
      end
    end

## Types of result block:
##  1) :main
##  2) :args
##  3) :instr (:if, :case, ...)
## Types of parsed block: 
##  1) :text -> main block alternating text and dtag blocks
##  2) :dtag -> {% ...%}

    def find_args(inside)
      ## Instruction delimiter
      delim=@block[@scan.pos,1]
      #p delim
      @scan.pos += delim.bytesize #.length
      st=@scan.pos
      delim=@@close[delim] if @@close[delim]
      #p delim
      ## Arguments
      begin
        @scan.scan_until(/#{Regexp.escape(delim)}/)
      end while @block[@scan.pos-2,1]=='\\'
      sp=@scan.pos - delim.bytesize - 1 #.length - 1
      args=@block.byteslice(st..sp) #@block[st..sp]
      inside2=[]
      (1..(args.split(@re_strange,-1).length-1)).each{ inside2 << inside.shift }
      return [:args,{:txt=>args,:inside=>inside2}]
    end

    def find_text(from,key,inside)
#p ["key=",key]
      res,to=nil,nil
      pre=(@next_pre ? @next_pre : nil )
      @next_pre=nil
      if @scan[1].nil? or @scan[1].empty? or @is_arg
#p ["key=",key,@tag_selected]
      	if @tag_selected
      	  @next_pre=key[2...-1].scan(@dtag[:named_tag][@tag_selected.to_sym][:rest])[0][0]
      	  @next_pre=nil if @next_pre.empty?
      	end
        @scan.scan_until(/#{Regexp.escape(key)}/)
        to=@scan.pre_match.bytesize #.length
        ##Dyndoc.warn "TOOOOOOOOOOO",[@scan.pre_match,to]
        res=@block.byteslice(from...to) #@block[from...to]
      else
#p ["pre_match=",@scan.pre_match,"to=",@scan.pre_match.bytesize]
        to=@scan.pre_match.bytesize #.length
        ##Dyndoc.warn "TOOOOOOOOOOO2222",[@scan.pre_match,to]
        delim2=@scan[1] 
        delim2=@@open[delim2] if @@open[delim2]
#p ["delim2=",delim2,/#{Regexp.escape(delim2)}/]
#p @block[from...-1]
        @scan.exist?(/#{Regexp.escape(delim2)}/)
        to_tmp=@scan.pre_match.bytesize #.length
#p ["to_tmp=",to_tmp]
        ## pre=@block[from...to_tmp].strip unless pre
#p [:pre,pre]
        pre=@block.byteslice(from...to_tmp).strip unless pre
#p ["pre=",pre]
        from=to_tmp+1
#p ["key:",key,@scan.matched,from,@block[from-1,1]]
        @scan.scan_until(/#{@tag[:block]}\s*#{Regexp.escape(key)}/)
=begin
        @scan.scan_until(/[\]|]\s*#{key}/)
=end
#p ["matched=",@scan.matched]
#p @scan.pre_match
#to=@scan.pre_match.length
        res=@block.byteslice(from...to) #does not work for ruby2 => @block[from...to]
        pre=nil if pre.empty?
#p ["res=",from,to,res,@block.byteslice(from...to)]
      end
    inside2=[]
    (1..(res.split(@re_strange,-1).length-1)).each{ inside2 << inside.shift }
    return [:text,{:name=>pre,:txt=>res,:inside=>inside2}] if pre
    return [(@is_arg ? :args : :text),{:txt=>res,:inside=>inside2}]
    end


    def complete_tag(key,add=true)
      #Regexp.escape(key.to_s)+((@dtag[:named_tag][key]) ? @dtag[:named_tag][key] : "")
      if @dtag[:named_tag][key]
      	if add
      	  @named_tags << key 
      	  return nil 
      	else
      	  @dtag[:named_tag][key][:tag].sub("_TAG_",Regexp.escape( key.to_s ))
      	end
            else 
      	return Regexp.escape(key.to_s)
      end
    end

    def check_until_for_named_tags
      #if res
      @named_tags.each_index{|i|
    	if @scan[3+i]
    	  @tag_selected=@scan[3+i].to_sym
    #puts "here we go: #{@tag_selected}"
    	  break
    	end
      }
      #end
      #return res
    end

## ATTENTION: Ne pas faire de recurrence dans convert_block à cause de @scan! qui est en unique exemplaire!
    def convert_block(blck)
#puts "split_block";p blck
      @block= blck[:txt]
      inside=blck[:inside]
      style=blck[:type].include? @tag_style
      pre_res=[]
      res=[]
=begin
      ## Mode -> unused now!
      mode=@block[0,@mode[:length]]
      mode2=(@@close[mode] ? @@close[mode] : mode)
=end
      @scan.string=@block
      @scan.pos=0
      ## Instruction
      #@scan.scan_until(/(?:#{@tag_instr.join("|")})/)
      @scan.scan_until(@start)
      instr=@scan[1] #@scan.matched
#p [:instr,instr]
      # next block is a arg block?
      @is_arg=false
      if @tag_instr.include? instr
        instr=instr.to_sym
        instr=@tag_alias[instr] if @tag_alias.include? instr
        if instr.is_a? Array
          res += instr
          instr=instr[0]
        else 
          res << instr
        end
        if (@tag_arg+@tag_code).include? instr
          case @dtag[:mode_arg]
          when :find
            res << find_args(inside)
          when :next_block
            @is_arg=true
          end
        end 
      else
	      instr2=(style ?  :style : :call)
        #pour un éventuel ajout de > ou < à la fin
        if [">","<"].include? instr[-1,1] 
          instr2,instr=(instr2.to_s+instr[-1,1]).to_sym,instr[0...-1]
        end
        res << instr2 << [:args, {:txt=>instr,:inside=>[]}]
        instr=instr2
      end
      ## Text block
      ## find keywords
      from=true
#p "todoooo"
      while from
        from=@scan.pos
#p @tag_keyword[instr]
#p /(#{@tag[:block]}?)\s*(#{@tag[:keyword][0]}(?:#{keytags=(@tag_keyword[instr] ? @tag_keyword[instr] : [] ).map{|e| Regexp.escape(e.to_s)}.join("|")})#{@dtag[:empty_keyword][0]}#{@tag[:keyword][1]})/
        tag_keyword=nil
        if @dtag[:empty_keyword][0].empty?
          #no empty tag!
          tag_keyword=@tag_keyword[instr] if @tag_keyword[instr]
        else
          tag_keyword=(@tag_keyword[instr] ? @tag_keyword[instr] : [] )
        end  
	      keytags=nil
	      @named_tags,@tag_selected=[],nil
	      if tag_keyword
#p tag_keyword
	        if @tag_keyword_reg and @tag_keyword_reg[instr]
	          tag_keyword=@tag_keyword_reg[instr]
	          blocktag_reg=/(#{@tag[:block]}?)\s*(#{@tag[:keyword][0]}#{tag_keyword}#{@dtag[:empty_keyword][0]}#{@tag[:keyword][1]})/
	          tag_reg=/#{tag_keyword}/
	        else
	          keytags=tag_keyword.map{|e| complete_tag(e)}.compact.join("|")
#puts "keytags(1)";p keytags
#puts "INSTR="; p instr
	          if @dtag[:with_tagblck].include? instr
	            keytags += "|" unless keytags.empty?
	            keytags += @@keystagblck
	            @named_tags += @@named_tags_blck
	          end
##puts "keytags(2)";p keytags
	          tag_reg=/(?:#{keytags})/
	          unless @named_tags.empty?
	            keytags += "|"+(@named_tags.map{|tag| complete_tag(tag,nil)}.join("|"))
	          end
            ##Dyndoc.warn "keytags",keytags
	          blocktag_reg=/(#{@tag[:block]}?)\s*(#{@tag[:keyword][0]}(?:#{keytags})#{@dtag[:empty_keyword][0]}#{@tag[:keyword][1]})/
	        end
##Dyndoc.warn "to scan", @scan.string[@scan.pos..-1]
##Dyndoc.warn "tag_reg",[blocktag_reg,tag_reg]
	      end
        if (tag_keyword and (@scan.check_until(blocktag_reg))) #or (!@named_tags.empty? and check_until_for_named_tags)
	        check_until_for_named_tags unless @named_tags.empty?
          key=@scan[2]
##Dyndoc.warn "keyword",[key,@scan[0],@scan[1],@scan[2]]
##Dyndoc.warn "pre_math,tag_selected",[@scan.pre_match,@tag_selected] if key=="[#tag]"
          res << find_text(from,key,inside)
          @is_arg=false if @is_arg
##Dyndoc.warn "key(AV)",[key,tag_reg] if key=="[#tag]"
	        if @tag_selected
#puts "tag_selected";p @tag_selected
	          res << (key=@tag_selected)
	        else
	    #key=tag_reg.match(key)[0]
	          key= key.scan(tag_reg)[0]
##Dyndoc.warn "key(AP)",key if key=="tag"
	          res << (key=key.to_sym) if key and !key.empty?
	        end
	    #res << (key=key[1..-1].to_sym)
      #p @tag_arg
          if @tag_arg.include? key #without @tag_code inside a block 
            case @dtag[:mode_arg]
            when :find 
              res << find_args(inside) 
              from=@scan.pos
            when :next_block
              @is_arg=true
            end
          end
        else 
          #Last text block!
#p /(#{@tag[:block]}?)\s*(#{@tag[:stop]})/
          @scan.check_until(/(#{@tag[:block]}?)\s*(#{@tag[:stop]})/)
#puts "last"; p @scan[2];p @scan[0]; p @scan[1]
#p @scan.pre_match
          res << find_text(from,@scan[2],inside)
#p res
          from=false
        end
#puts "from2";p from
      end
#puts "res";p res
      return res
    end

    def parse_block(blck)
      res=convert_block(blck)
#puts "res";p res 
      ##Stop scan when :txt instruction to avoid parsing!
      if TXT_DTAG.include? res[0]
        res2=[res[0],rebuild_after_filter(res[1][1])]
        # NO MORE POSSIBLE! res2 << res[1][1][:name] if res[1][1][:name]
#p res2
        return res2
      end 
      res2=[]
      res.each{|e|
#p e
        if e.is_a? Array
          case e[0]
            when :args
              res2 << parse_args(e[1])
            when :text
              res2 += parse_text(e[1])
          end
        else
          res2 << e
        end 
      }
#p res2
      #make :blck block if necessary
      res2=ajust_with_blck(res2)
#puts "res2";p res2
      return res2
    end

    def ajust_with_blck(res)
      return res unless @tag_blck[:keyword].include? res[0]
      instr=@tag_blck[:keyword][res[0]]
      res_blck,blck=[],nil
      begin
        b=res.shift
        if instr.include? b
          #create the :blck block
          res_blck << b
          #is there an :args block?
          res_blck << res.shift if @tag_arg.include? b
          #if no first tag_blck then put the default :out tag 
          blck=[:blck]
          blck << :out unless @@tagblck_set.include? res[0]
        else
          if blck
            blck << b
          else
            #needed for example :case block
            res_blck << b 
          end 
          #is the end of blck?
          if res.empty? or (instr.include? res[0])
            res_blck << blck if blck
            blck=nil
          end
        end
      end until res.empty?
      res_blck
    end

    def parse_args(blck)
      res=[:args]
#puts ":args";p blck[:txt]
      parts=blck[:txt].split(@re_strange,-1)
#p parts
#p blck[:inside]
      blck[:inside].map do |e|
        res << [:main,parts.shift]
        res << parse_block(e)
      end
      res << [:main,parts.shift]
      res
    end

    def parsed_block_with_modifier(res_block)
      res=nil
      instr=res_block[0,1].to_s
      if !["<","<<",">"].include? instr and [">","<"].include?(modif=instr[-1,1])
        res=modif.to_sym
        res_block[0,1]=instr[0...-1].to_sym
      end
      res
    end

    def parse_text(blck)
#puts "blck";p blck
      res=[]
      blck[:txt].split(@re_strange2,-1).each{|e|
        if e==@strange

          b=blck[:inside].shift
          res_b=parse_block(b)
          if (res_modif=parsed_block_with_modifier(res_b))
            res << res_modif 
          end
#puts "parse_text: res_b";p res_b         
          res << res_b
        else
          res << [:main,e] 
        end
      }
      res=[[:named,blck[:name]]+res] if blck[:name]
      res
    end

    def rebuild_after_parse(res)
        txt=""
        start=0
        parts=res[:txt].split(@re_strange,-1)
        res[:inside].map do |e|
          txt << parts.shift
          txt << (e[:inside] ? rebuild_after_parse(e) : e[:txt])
        end
        txt << parts.shift
        txt
    end

    def process(txt)
      tokenize(txt)
      parse_text(extract)
    end

    def pretty_print(res,tab=0)
      res.each{|b|
        if b.is_a? Array
          pretty_print(b,tab+1)
        else
          puts "  "*tab+b.inspect+"\n"
        end
      }
    end

  end

  class VarsScanner < Scanner

    @@type[:vars]={
          :start=>'<<([\w\@]*)\s*\[',
          :stop=>  '\]',
          :mode=>{:start=>-1,:stop=>0,:length=>1}
        }

    def initialize(type=:vars,start=nil,stop=nil,mode=nil,escape=nil)
      super
    end

    def make_vars(res)
      vars=[]
      start=0
      parts=res[:txt].split(@re_strange,-1).join("").strip
#puts "parts";p parts
#p res
#puts "inside";p res[:inside]
      res[:inside].map do |e|
        vars2= [e[:type][2..-1].strip,(e[:inside] ? make_vars(e) : e[:txt][(e[:type].bytesize+1)...-1] )] #instead of length
        vars << vars2
      end
#puts "vars";p vars
      vars
    end

    def build_dyn_vars(res)
#puts "res";p res
      is_arr=res.map{|k,v| k}.join("").empty?
      cpt=-1
      res2=[]
      res.each{|k,v|
#p k;p v
        key2=(k.empty? ? (is_arr ? "" : "key")+(cpt+=1).to_s : k)
        res0=((v.is_a? Array) ? build_dyn_vars(v) : [["",v]])
#puts "res0";p res0
        res2+=res0.map{|k0,v0| [key2+(k0.empty? ? "" : "." )+k0,v0]}
#puts "res2";p res2
      }
#puts "res2";p res2
      res2
    end

     def build_rb_vars(res)
#puts "res";p res
      is_arr=res.map{|k,v| k}.join("").empty?
      cpt=0
      res2=(is_arr ? [] : {})
      res.each{|k,v|
#p k;p v
        v2=((v.is_a? Array) ? build_rb_vars(v) : v)
        if is_arr
          res2 << v2
        else
          key2=(is_arr ? (cpt+=1) : (k.empty? ? "key"+(cpt+=1).to_s : k).to_sym)
          res2[key2]=v2
        end
      }
#puts "res2";p res2
      res2
    end


    def build_vars(txt,type=:dyn)
#puts "txt";p txt
      return nil unless txt[0,2]=="<<"
      res=tokenize(txt)
      return nil if res[:inside].empty?
      res=make_vars(extract)
      case type
      when :dyn
#puts "res in build_vars";p res
        build_dyn_vars(res)
      when :rb
        build_rb_vars(res)
      when :r
      end
    end

    
  end
end

