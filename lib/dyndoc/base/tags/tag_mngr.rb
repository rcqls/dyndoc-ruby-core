module Dyndoc

  class TagManager
    
    def TagManager.make_alias(aliases,alias_lines) #alias_lines= array of lines of the form "alias1,...,aliasN=tag1,...,tagP"
#p alias_lines
      alias_lines.map{|e| e.split(/[=>]/)}.map{|e,e2,e3| tmp=e.split(",").map{|ee| ee.strip};tmp2=e2.split(",").map{|ee| ee.strip}+tmp;tmp.map{|ee| aliases[ee] = tmp2}}.flatten
      #aliases updated!
    end 

    def TagManager.global_alias(aliases)
      ## global aliases
      @@alias=""
      @@etc_alias=File.join(Dyndoc.cfg_dir[:etc],"alias")
      @@alias << File.read(@@etc_alias).chomp << "\n"  if File.exist? @@etc_alias
      if Dyndoc.cfg_dir[:file]
        @@file_alias=File.join(Dyndoc.cfg_dir[:file],'.dyn_alias') 
        @@alias << File.read(@@file_alias).chomp << "\n"  if File.exist? @@file_alias
      end
      TagManager.make_alias(aliases,@@alias.chomp.split("\n"))
    end 

    def TagManager.local_alias(aliases,input) # @alias increased 
      TagManager.make_alias(aliases,input.scan(/%%%alias\(([^\)]*)\)/).flatten)
    end

    def TagManager.apply_alias(tags,aliases) #partTag is modified at the end!
      tags.replace(tags.map{|e| ( (aliases.keys.include? e) ? aliases[e] : e )}.flatten.uniq)
    end

     
    def TagManager.append(partTag,tags)
#puts "partTag";p partTag
#puts "tags";p tags
      partTag.each_key{|o| partTag[o]+=tags}
    end
 
=begin
    def TagManager.tags_ok?(part,partTag)
      part[0]=part[0][1..-1] if (neg=(part[0][0,1] == "-"))
      tmp= (partTag & part).empty? 
      tmp = !tmp unless neg
puts "last";p part;p tmp
      return tmp
    end

    def TagManager.init_input_tags(tags)
      return tags
    end
=end

    def TagManager.init_input_tag(tag)
      res=/#{"^"+tag.gsub(/\*\*:/,"[\\w\\d\\-_:]_STAR_:").gsub(/\*:/,"[\\w\\d\\-_]_STAR_:").gsub(/_STAR_/,"*")+"$"}/
      #p res
      res
    end

    def TagManager.init_input_tags(tags)
      new_tags=tags.map{|t| (t.is_a?(String) ? TagManager.init_input_tag(t) : t ) }
#puts "newtags";p new_tags
      return new_tags
    end

    def TagManager.tags_ok?(part,partTag)
## Dyndoc.warn "tags_ok?",[part,partTag]
      return true if partTag.include? /^all$/
      part[0]=part[0][1..-1] if (neg=(part[0][0,1] == "-"))
      tmp=false
      partTag.each{|t|
#puts "t";p t
	      part.each{|t2|
#puts "t2";p t2
	        tmp=(t =~ t2)
#puts "tmp";p tmp
	        break if tmp
	      }
	      break if tmp
      }
      tmp = !tmp if neg
#puts "last";p part;p partTag;p tmp
      return tmp
    end

    def TagManager.pre_tag(tag)
      # first, replace $(i) by  $dyn_curtag[i]
      if $dyn_curtag
      	new_tag=tag.gsub(/\$\d?/){|e| 
      	  i=e[1..-1].to_i
      	  i-=1 if i>0
      	  ($dyn_curtag[i] ? $dyn_curtag[i] : "")
      	}
      else
	     new_tag=tag.dup
      end
#puts "new_tag";p new_tag
#puts "$dyn_curtag";p $dyn_curtag
      # second, find $dyn_curtag
      curtag=new_tag.scan(/\([^\(]*\)/)
      $dyn_curtag=curtag.map{|e| e[1...-1]} unless curtag.empty?
#puts "$dyn_curtag2";p $dyn_curtag
      new_tag.gsub!(/\([^\(]*\)/){|e| e[1...-1]}
#puts "new_tag2";p new_tag
      return new_tag
    end

    def TagManager.make_tags(str)
## Dyndoc.warn "make_tags",str
      if str.is_a? String
        TagManager.pre_tag(str)
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

  end

end
