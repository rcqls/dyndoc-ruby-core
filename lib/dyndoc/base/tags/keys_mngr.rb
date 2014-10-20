module Dyndoc

class KeysManager

    ######## word ########

    def KeysManager.word_key(key)
      key2=/#{"^"+key.gsub(/\*/,"[\\w\\d\\.\\-:]_STAR_").gsub(/_STAR_/,"*")}/
      #p res
      key2
    end

    def KeysManager.word_lock(lock)
      
    end

    def KeysManager.word_unlocked?(lock,key)
      return nil if lock.nil?
      lock.strip=="*" or lock=~key
    end

    ########## list ########
    def KeysManager.list_key(key)
      key2=/#{"^"+key.gsub(/\*/,"[\\w\\d\\.\\-:]_STAR_").gsub(/_STAR_/,"*").gsub(/[\w\,]+/) {|e| "(?:#{$&})"}.gsub(",","|")}/
      #p key2
      key2
    end

    def KeysManager.list_unlocked?(lock,key)
#puts "list_unlocked";p lock;p key
      return nil if lock.nil?
      return true if lock.strip=="*"
      l=lock.split(",").map{|e| e.strip}
      cpt,ok=0,nil
      begin
	ok=l[cpt]=~key
      end while !ok and (cpt+=1)<l.length
#p ok
      return ok
    end


    ########## path ########
    def KeysManager.path_key(key)
      # key is automatically completed with -**
#puts "path_key:key";p key
      key2="^"+(key+"-**").gsub(/[\w\,\*]+/) {|e| "(?:#{$&})"}.gsub(",","|").gsub(/\*\*/,"[\\w\\d\\-\\.:]_STAR_").gsub(/\*/,"[\\w\\d\\.:]_STAR_").gsub(/_STAR_/,"*")
      #p key;p key2
      /#{key2}/
    end

    def KeysManager.path_lock(lock)
      lock+"-"
    end

    def KeysManager.path_unlocked?(lock,key)
      return nil if lock.nil?
      return (lock.strip=="*" or KeysManager.path_lock(lock)=~key)
    end

    ########## depth ########
    def KeysManager.depth_key(key)
      # key is automatically completed with -**
#puts "depth_key";p key
      key2=((key.is_a? Array) ? key : eval(key).to_a) 
#p key2
      key2
    end

    def KeysManager.depth_lock(lock)
      eval(lock).to_a
    end

    def KeysManager.depth_unlocked?(lock,key)
      return nil if lock.nil?
#p KeysManager.depth_lock(lock) & key
      return (lock.strip=="*" or !(KeysManager.depth_lock(lock) & key).empty?)
    end

    ########## num ########
    def KeysManager.num_val(val)
      val.to_i
    end

    def KeysManager.num_unlocked?(lock,key)
      return nil if lock.nil?
#p KeysManager.depth_lock(lock) & key
      return key[:order].include?(KeysManager.num_val(lock) <=> key[:val])
    end
    ########## date ########
    def KeysManager.date_val(val)
      Date.new(*val.split(/(?:\-|\/)/).reverse.map{|e| e.to_i})
    end

    def KeysManager.date_unlocked?(lock,key)
      return nil if lock.nil?
#p KeysManager.depth_lock(lock) & key
      return key[:order].include?(KeysManager.date_val(lock) <=> key[:val])
    end

    ########## section ########
    def KeysManager.section_unlocked?(lock,key)
      return true
    end

    ## general
    def KeysManager.complete_name(k)
      k2=$dyn_keys[:index][k] if k.is_a? Integer
      k2=$dyn_keys[:index].find{|v| v=~/^#{k}/} unless k2
      unless k2
	k2=$dyn_keys[$dyn_keys[:alias].find_all{|v| v=~/^#{k}/}.sort[0]]
      end
      raise "Dyndoc Error: complete_name #{k}!" unless k2
      return k2
    end

    def KeysManager.prepare_comp(crit)
      res={}
      if crit=~/^(?:!=|>=|<=|>|<|=)/
	res[:order]= KeysManager.complete_comp($~[0])
	crit.replace($~.post_match)
      else 
	res[:order]=[0]
      end
      res
    end


    def KeysManager.complete_comp(comp)
      case comp
      when "="; [0]
      when "!="; [-1,1]
      when ">"; [1]
      when "<" ;[-1]
      when "<="; -1..0
      when ">="; 0..1
      end
    end
    
    # complete the name of criteria
    def KeysManager.var_names(keys,clean=nil)
      if $dyn_keys
	      keys2,index,aliases={},$dyn_keys[:index].dup,$dyn_keys[:alias].dup
#puts "var_names: index";p index
        index_to_clean=[]
	      keys.each_key{|k|
#puts "k";p k
	        to_merge=nil
	        k,to_merge=k[0...-1],true if k.is_a? String and k[-1,1]=="?"
#p index
	        k2=$dyn_keys[:index][k] if k.is_a? Integer
	        k2=index.find{|v| v=~/^#{k}/} unless k2
	        index_to_clean << index.delete(k2) if k2
	        unless k2
	          k2=$dyn_keys[aliases.find_all{|v| v=~/^#{k}/}.sort[0]]
	          index_to_clean << aliases.delete(k) if k2 
	        end
#puts "k2";p k2
          
	        keys2[(to_merge ? k2+"?" : k2)]=keys[(to_merge ? k+"?" : k)] if k2
	      }
        #update keys by deleting dealt elements
        index_to_clean.each{|k| keys.delete(k)} if clean
	      return keys2
      end
    end

    def KeysManager.make_title(lock)
      lock.each{|key,val|
	      if val and val.include? "("
	        $dyn_keys[:title]={} unless $dyn_keys[:title]
	        $dyn_keys[:title][key]=[] unless $dyn_keys[:title][key]
	        val,title=val.scan(/(.*)\((.*)\)/)[0]
	        lock[key]=val
	        $dyn_keys[:title][key] << [val,title]
	      end
      }
    end

    def KeysManager.make_keys(init_keys)
#p keys
      keys=KeysManager.var_names(init_keys,true)
#puts "make_keys";p keys
      keys.each_key{|k|
	      next if k.is_a? Symbol
	      case $dyn_keys[k][:type]
	      when :word
	        keys[k]=KeysManager.word_key(keys[k])
	      when :path
	        keys[k]=KeysManager.path_key(keys[k])
	      when :list
	        keys[k]=KeysManager.list_key(keys[k])
	      when :depth
	        keys[k]=KeysManager.depth_key(keys[k])
	      when :num
	        crit=keys[k].strip
	        res=KeysManager.prepare_comp(crit)
	        res[:val]=KeysManager.num_val(crit)
	        keys[k]=res
	      when :date
	        crit=keys[k].strip
	        res=KeysManager.prepare_comp(crit)
	        res[:val]=KeysManager.date_val(crit)
	        keys[k]=res
	      when :order #k="order"!
	        crits=keys[k].strip
#p crits
	        keys["order"]=keys["order"].strip.split(",").map{|crit| 
	          res={:order=>1}
	          if "+-><".include? crit[0,1]
	            case crit[0,1]
	            when ">","+"
	              res[:order]=1
	            when "<","-"
	              res[:order]=-1
	            end
	            crit=crit[1..-1].strip
	          end
	          res[:val]= KeysManager.complete_name(crit)
	          keys[:required]=[] unless keys[:required]
	          keys[:required] |= [res[:val]]
	          res
	        }
	      when :required #k="required"!
	        crits=keys["required"].strip.split(",")
	        keys[:required]=[] unless keys[:required]
	        keys["required"]=crits.map{|crit|  KeysManager.complete_name(crit)}
	        keys[:required] |=keys["required"]
	      end
      }
      KeysManager.keys_section(keys)
      keys
#puts "make_keys(OUT)";p keys
    end

    def KeysManager.begin(lock_keys_orig,lock,keys)
#p $dyn_keys[:begin_end]
#p ($dyn_keys[:begin_end] & lock.keys).empty?
      unless ($dyn_keys[:begin] & lock_keys_orig ).empty?
#puts "begin:lock" ;p lock_keys_orig
	$dyn_keys[:begin].each{|key|
	  case $dyn_keys[key][:type]
	  when :section
#p $dyn_keys[:section][key]
	    $dyn_keys[:section][key]=[] unless $dyn_keys[:section][key]
	    if $dyn_keys[:section][key].empty? or $dyn_keys[:section][key][-1][:state]==:open
#puts "begin #{k}"
	      $dyn_keys[:section][key] << {:cpt=>1,:state=>:open}
	    else
#puts "incr #{k}"
	      $dyn_keys[:section][key][-1][:cpt]+=1
	      $dyn_keys[:section][key][-1][:state]=:open
	    end
#p $dyn_keys[:section][k]
	    lock[key]=$dyn_keys[:section][key].map{|e| e[:cpt]}
#puts "lock[#{k}]";p lock[k]
#puts "begin:section_rel";p lock;p keys
#puts "keys2";p keys2;p lock
	    if  KeysManager.unlocked?(lock,$dyn_keys[:section_required][:keys])
	    $dyn_keys[:section_rel][key]=[] unless $dyn_keys[:section_rel][key]
	    if $dyn_keys[:section_rel][key].empty? or $dyn_keys[:section_rel][key][-1][:state]==:open
#puts "begin #{k}"
	      $dyn_keys[:section_rel][key] << {:cpt=>1,:state=>:open}
	    else
#puts "incr #{k}"
	      $dyn_keys[:section_rel][key][-1][:cpt]+=1
	      $dyn_keys[:section_rel][key][-1][:state]=:open
	    end
#p $dyn_keys[:section][k]
	    lock[key+"_rel"]=$dyn_keys[:section_rel][key].map{|e| e[:cpt]}
#puts "lock[section_rel]";p lock[key+"_rel"]
	    end
	  end
	}
      end
    end

    def KeysManager.end(lock_keys_orig,lock,keys)
#p $dyn_keys[:begin_end]
#p ($dyn_keys[:begin_end] & lock.keys).empty?
      unless ($dyn_keys[:end] & lock_keys_orig).empty?
#puts "end:lock" ;p lock_keys_orig
	$dyn_keys[:end].each{|key|
	  case $dyn_keys[key][:type]
	  when :section
#puts "close #{k}"
	    $dyn_keys[:section][key].pop if $dyn_keys[:section][key][-1][:state]==:close
	    $dyn_keys[:section][key][-1][:state]=:close if $dyn_keys[:section][key][-1][:state]==:open
	    if  KeysManager.unlocked?(lock,$dyn_keys[:section_required][:keys])
	    $dyn_keys[:section_rel][key].pop if $dyn_keys[:section_rel][key][-1][:state]==:close
	    $dyn_keys[:section_rel][key][-1][:state]=:close if $dyn_keys[:section_rel][key][-1][:state]==:open
	    end
	  end
#p $dyn_keys[:section][k]
	}
      end
    end

    
    def KeysManager.init_keys(keys)
#p keys
      #merge the different keys
      keys2={}
      key=keys.join(",") 
      KeysManager.make(key,keys2)
#puts "KeysManager.init_keys";p keys2
      return keys2
    end

    def KeysManager.keys_section(keys,section_required=["theme","part","topic"])
      #put the two lines below in register!
      $dyn_keys[:section]={} unless $dyn_keys[:section]
      $dyn_keys[:section_rel]={} unless $dyn_keys[:section_rel]
      $dyn_keys[:section_required]={:set=>section_required}
      $dyn_keys[:section_required][:keys]={};keys.select{|k,e| $dyn_keys[:section_required][:set].include? k}.each{|k,e| $dyn_keys[:section_required][:keys][k]=e}
    end


    def KeysManager.make(str,obj=nil)
      cpt=-1
      #str+=$dyn_keys[:require] unless obj
#puts "make_lock";p str
      obj={} unless obj
      str.split(/[:]/).each{|e|
	      cpt+=1
	      key,*val=e.split("=").map{|e2| e2.strip}
	      val=val.join("=") unless val.empty? 
	      key,val=cpt,key if val.empty?
	      obj[key]=val if val and !obj[key]
      }
      #p obj
      return obj
    end

    def KeysManager.simplify(obj)
      obj.each_key{|key|
	      if key[-1,1]=="?"
	        obj[key[0...-1]]=obj[key] unless obj[key[0...-1]]
	        obj.delete(key)
	      end
      }
#p obj
    end

    def KeysManager.merge(obj2,obj=$dyn_keys[:lastlock].dup)
#puts "merge_lock";p obj
#p obj2
      obj.each_key{|key|
	next if key.is_a? Symbol
#puts "merge #{key}";p (obj2[key] and !(obj2[key]=~/^\s*\w/))
	if obj2[key+"?"] or !obj2[key]
	  obj2.delete(key+"?") if obj2[key+"?"]
	  obj2[key]=obj[key] unless obj2[key]
	elsif $dyn_keys[key][:type]==:path
	  #obj2[key] and !(obj2[key]=~/^\s*\w/) #for :list and :path
#puts "add";p obj2[key]
	  obj2[key]=obj[key]+"-"+obj2[key].strip
	elsif $dyn_keys[key][:type]==:list
	  obj2[key]=obj[key]+","+obj2[key].strip
	end
      }
#p obj2
    end

    def KeysManager.unlocked?(lock,keys)
#puts "unlocked?";p lock
      lock_keys=lock.keys
#puts "required?";p  lock_keys;p keys[:required]
      return nil unless !keys[:required] or (keys[:required]-lock_keys).empty?
      to_open=keys.keys-[:required,"required","order"] #& lock_keys
#puts "to_open";p to_open
      ok=(to_open.empty? ? true : to_open.map{|k|
#puts "k=#{k}";p lock[k];p keys[k]
	next if k.is_a? Symbol
	case $dyn_keys[k][:type]
	when :word
	  res=KeysManager.word_unlocked?(lock[k],keys[k])
	when :path
	  res=KeysManager.path_unlocked?(lock[k],keys[k])
	when :list
	  res=KeysManager.list_unlocked?(lock[k],keys[k])
	when :depth
	  res=KeysManager.depth_unlocked?(lock[k],keys[k])
	when :num
	  res=KeysManager.num_unlocked?(lock[k],keys[k])
	when :date
	  res=KeysManager.date_unlocked?(lock[k],keys[k])
	when :section
	  res=KeysManager.section_unlocked?(lock[k],keys[k])
	end
#puts "ok#{k}?";p res
	res
      }.all?)
#puts "ok?";p ok
      return ok
    end


  end

end
