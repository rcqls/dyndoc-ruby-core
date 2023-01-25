module Dyndoc

  class PartTag
    
    def PartTag.make_alias(aliases,alias_lines) #alias_lines= array of lines of the form "alias1,...,aliasN=tag1,...,tagP"
#p alias_lines
      alias_lines.map{|e| e.split(/[=>]/)}.map{|e,e2,e3| tmp=e.split(",").map{|ee| ee.strip};tmp2=e2.split(",").map{|ee| ee.strip}+tmp;tmp.map{|ee| aliases[ee] = tmp2}}.flatten
      #aliases updated!
    end 

    def PartTag.global_alias(aliases)
      ## global aliases
      @@alias=""
      @@sys_alias=File.join(Dyndoc.cfg_dir[:sys],"alias")
      @@alias << File.read(@@sys_alias).chomp << "\n"  if File.exist? @@sys_alias
      @@home_alias=File.join(Dyndoc.cfg_dir[:home],'alias')
      @@alias << File.read(@@home_alias).chomp << "\n"  if File.exist? @@home_alias
      if Dyndoc.cfg_dir[:file]
        @@file_alias=File.join(Dyndoc.cfg_dir[:file],'.dyn_alias') 
        @@alias << File.read(@@file_alias).chomp << "\n"  if File.exist? @@file_alias
      end
      PartTag.make_alias(aliases,@@alias.chomp.split("\n"))
    end 

    def PartTag.local_alias(aliases,input) # @alias increased 
      PartTag.make_alias(aliases,input.scan(/%%%alias\(([^\)]*)\)/).flatten)
    end

    def PartTag.apply_alias(partTag,aliases) #partTag is modified at the end!
      partTag.each_key{|o|
        partTag[o]=partTag[o].map{|e| ( (aliases.keys.include? e) ? aliases[e] : e )}.flatten.uniq
      }
    end

    @@partTagDefault=["main"]

    def PartTag.partTagDefault(out_tag)
      partTag={}
      out_tag.each{|o| 
        partTag[o]=@@partTagDefault.dup
        partTag[o] << o unless o==:default
      }
      partTag
    end

    def PartTag.append(partTag,tags)
#puts "partTag";p partTag
#puts "tags";p tags
      partTag.each_key{|o| partTag[o]+=tags}
    end
 
    def PartTag.is_part_ok?(part,partTag)
      part[0]=part[0][1..-1] if (neg=(part[0][0,1] == "-"))
      tmp= (partTag & part).empty? 
      tmp = !tmp unless neg
      return tmp
    end

    def PartTag.make_part(str)
      if str.is_a? String
        str.split(",").map{|e| e.strip}.map{|t|
          if t[0,1]=="-"
            t
          else
            tmp=t.split(":")
            (0...tmp.length).map{|i| tmp[0..i].join(":")}
          end
        }.flatten
      else
        str
      end
    end

    @@partEmbed=["{","}"]
    ## filter part in doc
    def PartTag.part_doc(txt,partTag=[],partTagLimit=[Regexp.escape("%("),Regexp.escape(")")])
      return txt if partTag.empty? #nothing to do!
      parts=txt.scan(/#{partTagLimit[0]}([\#\d\w\-\:,]*[#{Regexp.escape(@@partEmbed[0]+@@partEmbed[1])}]?)#{partTagLimit[1]}/).flatten
#p partTag
#p parts
      #parts.map!{|pa| ( pa[0,1]==@@partEmbed[0] ? pa[1..-1]+pa[0,1] : pa ) } 
      #Rule opentag!
      # 1) an opentag non closed is as a norma tag
      # 2) a closetag non related to an opentag is ignored
      # These rules may be useful!
      open_part,close_part={},{}
      stack=[]
      parts.each_index{|i|
        tag=parts[i]
        case tag[-1,1]
        when @@partEmbed[0]
          prec_tag=nil 
          if i>0 
            prec_tag=parts[i-1]
#p prec_tag
            case prec_tag[-1,1]
              when @@partEmbed[0]
                prec_tag=prec_tag[0...-1]
              when @@partEmbed[1]
=begin
p i
p stack
p open_part
p close_part
=end
                prec_tag=open_part[close_part[i-1]][:prec_tag]
            end
          else
            prec_tag="main"
          end 
          stack.push({:index=>i,:name=>tag[0...-1],:prec_tag=>PartTag.make_part(prec_tag)})
        when @@partEmbed[1]
          close_tag=tag[0...-1]
          open_tag=stack.pop
          if open_tag and close_tag==open_tag[:name]
            open_part[open_tag[:index]]={:tag_name=>open_tag[:name],:close_index=>i,:prec_tag=>open_tag[:prec_tag]}
            close_part[i]=open_tag[:index] #to retrieve the information of the associated open_part
          else 
            stack.push(open_tag) if open_tag
          end
          #nothing is done if no associated open-close parts!
        end
      }

      parts=parts.map{|pa|
        pa=pa[0...-1] if pa[-1,1]=~/[#{Regexp.escape(@@partEmbed[0]+@@partEmbed[1])}]/
        PartTag.make_part(pa)
      }

      blocks=txt.split(/#{partTagLimit[0]}[\#\d\w\-\:,]*[#{Regexp.escape(@@partEmbed[0]+@@partEmbed[1])}]?#{partTagLimit[1]}/,-1)
      txt2=blocks[0]

      open_keys,close_keys=open_part.keys,close_part.keys
      locked={};partTag.each_key{|ot| locked[ot]=nil} 

      parts.each_index{|i|
        #is a open tag?
        if open_keys.include? i
          open_tag=open_part[i]
          part_tag=PartTag.make_part(open_tag[:tag_name])
          #is locked or unlocked?
          partTag.each_key{|ot|
            locked[ot]=open_tag[:close_index] if !(PartTag.is_part_ok?(part_tag,partTag[ot])) 
          }
        elsif close_keys.include? i
          #part_tag is the same before the open_tag!
          part_tag=open_part[close_part[i]][:prec_tag]
          #pop the last state of the open-close tag_block!
          partTag.each_key{|ot| locked[ot]=nil if locked[ot]==i}
        else
          part_tag=parts[i]
        end
#RMK: N'y-a-t-il pas une différence entre ne outtag et un part_tag???
## et les blocks ouvert et fermé n'ont-ils pas de sens que pour les part_tags?

        out_tag=[]
        partTag.each_key{|ot|
          out_tag << ot.to_s if !locked[ot] and  PartTag.is_part_ok?(part_tag,partTag[ot])
        }
        unless out_tag.empty?
          txt2 += "%("+out_tag.join(",")+")"
          txt2 += blocks[i+1]
        end 
      }
      return txt2
    end


     ## filter out_tag in doc
    def PartTag.out_tag_doc(txt,content,partTagLimit=[Regexp.escape("%("),Regexp.escape(")")])
      parts=txt.scan(/#{partTagLimit[0]}([\#\d\w\-\:,]*)#{partTagLimit[1]}/).flatten
      parts=parts.map{|pa|
        pa.split(",").map{|e| e.strip}.map{|t|
          if t[0,1]=="-"
            t
          else
            tmp=t.split(":")
            (0...tmp.length).map{|i| tmp[0..i].join(":")}
          end
        }.flatten
      }
      blocks=txt.split(/#{partTagLimit[0]}[\#\d\w\-\:,]*#{partTagLimit[1]}/,-1)
      content.each_key{|ot| content[ot] << blocks[0]}
      parts.each_index{|i|
        parts[i].each{|ot|
          ot=:default if ot=="default"
          content[ot] += blocks[i+1]
        }
      }
    end

  end

end