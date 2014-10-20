def When(actor,dec)
  from=CqlsBeamer::Actor[actor.to_s]
  from=( from ? from.when : eval(actor.to_s) ).to_i
  dec.gsub(/(\d*)/){|e| (e.to_i+from-1).to_s unless e.empty?}
end

module CqlsBeamer

  def CqlsBeamer.defCpt
    @@defCpt
  end

  def CqlsBeamer.defCpt=(val)
    @@defCpt=val
  end

  def CqlsBeamer.when(quand,scene=CqlsBeamer::Scene.current)
    from,from2=quand.split(":")
    from=nil unless from2
    #puts "quand";p quand
    if from
      from,quand=( (from.empty? and scene) ? scene.cpt[0] : CqlsBeamer::Actor[from].when),from2 
      quand=quand.gsub!(/[0-9]+/){|e| e.to_i+from-1}
    end
    quand
  end

  def CqlsBeamer.where(where,scene=nil)
    #Dyndoc.warn "xy",where
    from,ou=where.split(":")
    ou,from=from,ou unless ou
    if from
      from,scene=from.split("$") unless scene
      from,scene=scene,from unless scene
    end
    ou.gsub!(/\([^\(]*\)/){|elt| eval(elt) }
    if from
      fromKey=from.strip
      actorFrom=CqlsBeamer::Actor[fromKey]
      from=eval("["+actorFrom.where+"]")
      #puts "xy";p ou
      ou ="0.0,0.0" if !ou #and ou.empty?
      if actorFrom.isR
        # R4rb.eval("ou<-xyPercent(c("+ou+"),'#{fromKey}')")   
        # ou=[] < :ou
        # Replacement of previous 2 lines failing now!
        ou = "xyPercent(c("+ou+"),'#{fromKey}')"
        ou = ou.to_R
        zoom=actorFrom.isR.dup
        dim=CqlsBeamer::Scene[scene].dim
        ou[0] /= dim[2].to_f
        ou[1] /= dim[3].to_f
      else
        ou=eval("["+ou+"]")
      end
      ou="#{from[0]+ou[0]*zoom[0]},#{from[1]+ou[1]*zoom[1]}"
    end
#puts "last in xy";p ou
    ou
  end

  class Scene
    attr_accessor :name, :scene, :dim, :txt, :unit, :fg, :bg, :rounded, :framed, :cpt
    #default values for actors in its scene
    attr_accessor :minipage, :align
  
    @@scenes={}
    @@curScene=nil

    def Scene.[]=(key,val)
      @@scenes[key]=val
    end

    def Scene.[](key)
      @@scenes[key]
    end

    def Scene.current
      @@curScene
    end

    def initialize(name,dim)
      @name=name
      @scene=Group.new
      @unit="cm"
      @dim=dim.map{|e| e.to_s}
      @txt=""
      #default values
      @align="left,top"
      @minipage=""
      Scene[name]=self
      @@curScene=self
    end

    def init
      @scene.init
      @txt=""
      @cpt[0]=1
    end

    def append(obj)
      @@curScene=self
      @scene.append(obj)
    end

    alias << append

    def first
      txt=""
      txt += "\\setbeamercolor{#{@name}color}{fg=#{fg},bg=#{@bg}}\n\\begin{beamercolorbox}[wd=#{dim[2]+@unit},ht=#{dim[3]+@unit},rounded=#{@rounded}]{#{@name}color}" if @framed
      txt+="\\pgfsetxvec{\\pgfpoint{#{dim[2]+@unit}}{0cm}}\n\\pgfsetyvec{\\pgfpoint{0cm}{#{dim[3]+@unit}}}\n\\begin{pgfpicture}{#{dim[0]+@unit}}{#{dim[1]+@unit}}{#{dim[2]+@unit}}{#{dim[3]+@unit}}\n"
      return txt
    end

    def last
      txt="\\end{pgfpicture}\n"
      txt += "\\end{beamercolorbox}" if @framed
      return txt
    end

    def output
      @scene.output(@txt)
      return @txt
    end
    
  end

  class Actor
    attr_accessor :what, :when, :where, :align, :mode, :minipage, :isR, :isRaw
    @@actors={}

    def Actor.[]=(key,val)
      @@actors[key]=val
    end

    def Actor.[](key)
      @@actors[key]
    end
    
    def initialize(qui,quoi,quand,ou,align="left,top",mode=:only) #align=(left-center-right,bottom-base-center-top)
      quoi=quoi.join("\n") if quoi.is_a? Array
      @what,@when,@where,@align,@mode=quoi,quand,ou,align,mode
      @minipage=""
      Actor[qui]=self
    end

    def output(txt,local={})
      local[:where]=@where unless local[:where]
      local[:when]=@when unless local[:when]
      local[:align]=@align unless local[:align]
      local[:what]=@what unless local[:what]
      local[:mode]=@mode unless local[:mode]
      local[:minipage]=@minipage unless local[:minipage]
      #Dyndoc.warn  :outputInRuby, local[:what]
      local[:what]='\begin{minipage}{'+local[:minipage]+'}'+local[:what]+'\end{minipage}' unless local[:minipage].empty?
      #Dyndoc.warn  :outputInRuby2, local[:what]
      if @isRaw or !local[:where]
        txt << "\\#{local[:mode]}<#{local[:when]}>{\n #{local[:what]}}\n"
      else
        txt << "\\#{local[:mode]}<#{local[:when]}>{\n\\pgfputat{\\pgfxy(#{local[:where]})}{\\pgfbox[#{local[:align]}]{#{local[:what]}}}}\n"
      end
    end
    
  end

  class Group
    attr_accessor :list
    
    def initialize
      @list=[]
    end

    def init
      @list=[]
    end

    def append(actor)
      @list << ( (actor.is_a? Array) ? [Actor[actor[0]],actor[1]] : Actor[actor] )
    end

    alias << append

    def insert(actor,i=-1)
      if i<0
        append(actor)
      else
        @list=@list[0...i]+Actor[actor]+@list[i..-1]
      end
    end

    def move_last(actor)
      elt=@list.delete( (actor.is_a? String) ? Actor[actor] : actor)
      @list << elt if elt
    end

    def output(txt)
      @list.each{|e|
        if e.is_a? Array
          e[0].output(txt,e[1])
        else
          e.output(txt)
        end
      }
    end
    
  end

end
