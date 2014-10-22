require 'fileutils'

module Dyndoc

# first declaration of the config directory
  @@dyn_root_path=Settings['path.dyn_home']
  @@dyn_gem_path=File.expand_path(File.join(__FILE__,[".."]*4))
  @@cfg_dir={
    :root_path=> @@dyn_root_path,
    :gem_path=> @@dyn_gem_path,
    :etc => File.join(@@dyn_root_path,"etc"),
    :tmpl_path=>{:tex=>"Tex",:odt=>"Odt",:ttm=>"Ttm"},
    :model_default=>"Model",
    :file => "", #to complete when dyndoc applied to a file
    :current_doc_path => "" #completed each time a file is parsed in parse_do 
  }


  def Dyndoc.cfg_dir
    @@cfg_dir
  end

  def Dyndoc.cfg_dyn
    Settings[:cfg_dyn]
  end

  @@dyn_block={}

  def Dyndoc.dyn_block
    @@dyn_block
  end

  ## default mode and extension
  @@mode=:txt
  @@tmplExt={:txt => [".dyn_txt","_tmpl.txt",".dyn"], :rb =>[".dyn_rb","_tmpl.rb",".dyn"], :c=>[".dyn_c","_tmpl.c",".dyn"], :html => [".dyn_html","_tmpl.html","_tmpl.rhtml",".dyn"],:txtl=>[".dyn_txtl","_tmpl.txtl","_tmpl.rhtml",".dyn"],
  :tm=>[".dyn_tm","_tmpl.tm",".dyn"],
  :tex=>[".dyn_tex","_tmpl.tex",".dyn",".rtex"],
  :odt=>[".dyn_odt_content","_tmpl_content.xml",".dyn_odt_styles","_tmpl_styles.xml",".dyn_odt","_tmpl.odt",".dyn"], #_tmpl.odt is an odt file with content body to extract!
  :ttm=>[".dyn_ttm","_tmpl.ttm",".dyn"],
  :all=>[".dyn"]
  }

  @@docExt={:txt => ".txt",:rb => ".rb",:c=>".c",:html=>".html",:txtl=>".rhtml",:tm=>".tm",:tex=>".tex",:odt=>".odt",:ttm=>"_ttm.xml"}

  @@dynExt=[".dyn"]

  EXTS={:txt => ".txt",:rb => ".rb",:c=>".c",:html=>".html",:txtl=>".rhtml",:tm=>".tm",:tex=>".tex",:odt_content=>"_content.xml",:odt_styles=>"_styles.xml",:dyn=>".dynout",:ttm=>"_ttm.xml"}

  def Dyndoc.mode
    @@mode
  end

  def Dyndoc.mode=(mode)
    @@mode=mode
  end

  def Dyndoc.docExt(mode=@@mode)
    @@docExt[mode]
  end

  def Dyndoc.tmplExt
    @@tmplExt
  end


  def Dyndoc.init_dyndoc_library_path

    [File.join(FileUtils.pwd,".dyndoc_library_path"),File.join(FileUtils.pwd,"dyndoc_library_path.txt"),File.join(@@cfg_dir[:etc],"dyndoc_library_path")].each do |dyndoc_library_path|
    
      if File.exists? dyndoc_library_path
        path=File.read(dyndoc_library_path).strip
        path=path.split(Dyndoc::PATH_SEP).map{|pa| File.expand_path(pa)}.join(Dyndoc::PATH_SEP)
        if !ENV["DYNDOC_LIBRARY_PATH"] or ENV["DYNDOC_LIBRARY_PATH"].empty?
          ENV["DYNDOC_LIBRARY_PATH"]= path 
        else
          ENV["DYNDOC_LIBRARY_PATH"] += Dyndoc::PATH_SEP + path
        end
      end

    end

  end

  def Dyndoc.setRootDoc(rootDoc,root,before=true)  
    if rootDoc
      if before
        rootDoc2 = "#{root}:"+rootDoc
     else
        rootDoc2 = rootDoc+":#{root}"
      end
    else
      rootDoc2=root 
    end
    #insure unique path and adress of rootDoc is unchanged!
    rootDoc.replace(rootDoc2.split(":").uniq.join(":")) if rootDoc2
  end

  def Dyndoc.guess_mode(filename)
    @@tmplExt.keys.map{|k| k.to_s}.sort.each do |ext|
      return ext.to_sym if filename =~ /(#{@@tmplExt[ext.to_sym].join("|")})$/
    end
    return nil
  end

  def Dyndoc.init_rootDoc
    rootDoc=""
    if File.directory?(path=File.join(@@cfg_dir[:etc],Dyndoc.cfg_dyn['etc_path_subdir']))
      Dir[File.join(path,"*")].sort.each do |pa|
        rootDoc += (rootDoc.empty? ? "" : ":") + File.read(pa).chomp 
      end
    end
    Dyndoc.cfg_dyn['root_doc']=rootDoc
  end

# append or alias tricks ##########################
  @@append=nil

  def Dyndoc.appendVar
    @@append
  end

  def Dyndoc.make_append
    ## global aliases
    @@append={}
    tmp=[]
    sys_append=File.join( @@cfg_dir[:etc],"alias")
    tmp += File.readlines(sys_append) if File.exists? sys_append 
    home_append=File.join(@@cfg_dir[:etc],'alias')
    tmp += File.readlines(home_append)  if File.exists? home_append
    file_append=File.join(@@cfg_dir[:file],'.dyn_alias')
    tmp += File.readlines(file_append)  if File.exists? file_append
    tmp.map{|l| 
      if l.include? ">"
        l2=l.strip
        unless l2.empty?
          l2=l2.split(/[=>,]/).map{|e| e.strip} 
          @@append[l2[0]]=l2[-1]
        end
      end
    }
  end

  ## more useable than this !!!   
  def Dyndoc.absolute_path(filename,pathenv)
#puts "ici";p filename
    return filename if File.exists? filename
    paths=pathenv##.split(":")
#puts "absolute_path:filname";p filename
    name=nil
    paths.each{|e| 
      f=File.expand_path(File.join([e,filename]))
#p f
      if (File.exists? f)
      	name=f
      	break
      end
    }
#puts "->";p name
    name
  end

  def Dyndoc.directory_tmpl?(name,exts=@@tmplExt[@@mode])
    if name and File.directory? name
#puts "directory_tmpl?:name";p name;p exts
#p File.join(name,"index")
      resname=Dyndoc.doc_filename(File.join(name,"index"),exts,false)
      resname=Dyndoc.doc_filename(File.join(name,File.basename(name,".*")),exts,false) unless resname

##IMPORTANT: this file could not depend on the format_doc because it is related to the template and not the document!!!
      resname=Dyndoc.doc_filename(File.join(@@cfg_dir[:root_path],["root","Default","index"]),exts,false) unless resname
      name=resname
    end
#puts "directory_tmpl?:return resname";p resname;p name
    return name
  end

  PATH_SEP=";"

  def Dyndoc.init_pathenv
    #p Dyndoc.cfg_dyn
      if Dyndoc.cfg_dyn[:dyndoc_mode]==:normal #normal mode
         pathenv="."
      else #client server mode
        #puts "working directory";p Dyndoc.cfg_dyn[:working_dir]
        pathenv = Dyndoc.cfg_dyn[:working_dir] + PATH_SEP + "."
      end
      return pathenv
  end


  def Dyndoc.ordered_pathenv(pathenv)
    path_ary=[]
    pathenv.split(PATH_SEP).each{|e| 
      if e=~/(?:\((\-?\d*)\))(.*)/ 
        path_ary.insert($1.to_i-1,$2.strip)
      else 
        path_ary << e.strip
      end
    }
    #puts "path_ary";p path_ary
    path_ary.compact.uniq #.join(":")
  end

  ## dynamically get pathenv!!!!
  def Dyndoc.get_pathenv(rootDoc=nil,with_currentRoot=true)
    pathenv =  Dyndoc.init_pathenv
    pathenv += PATH_SEP + File.join(@@dyn_gem_path,"dyndoc") + PATH_SEP + File.join(@@dyn_gem_path,"dyndoc","Std") if File.exists? File.join(@@dyn_gem_path,"dyndoc")
    # high level of priority since provided by user
    pathenv += PATH_SEP + ENV["DYNDOC_LIBRARY_PATH"] if ENV["DYNDOC_LIBRARY_PATH"] and !ENV["DYNDOC_LIBRARY_PATH"].empty?
    pathenv += PATH_SEP + File.join(@@cfg_dir[:root_path],"library") if File.exists? File.join(@@cfg_dir[:root_path],"library")
    pathenv += PATH_SEP + @@cfg_dir[:current_doc_path] if with_currentRoot and !@@cfg_dir[:current_doc_path].empty?
    pathenv += PATH_SEP + rootDoc  if rootDoc and !rootDoc.empty?
    pathenv += PATH_SEP + Dyndoc.cfg_dyn[:root_doc]  unless Dyndoc.cfg_dyn[:root_doc].empty?
    pathenv += PATH_SEP + ENV["TEXINPUTS"].split(RUBY_PLATFORM =~ /mingw/ ? ";" : ":" ).join(";") if ENV["TEXINPUTS"] and @@mode==:tex
    
    ##Dyndoc.warn "pathenv",pathenv
    return Dyndoc.ordered_pathenv(pathenv)
  end
  
  # if exts is a Symbol then it is the new @@mode!
  def Dyndoc.doc_filename(filename,exts=@@tmplExt[@@mode],warn=true,pathenv=".",rootDoc=nil)
    rootDoc=Dyndoc.cfg_dyn[:root_doc] unless Dyndoc.cfg_dyn[:root_doc].empty?
    filename=filename.strip
    if exts.is_a? Symbol
      @@mode=exts 
      exts=@@tmplExt[@@mode]
    end
     
    pathenv = Dyndoc.get_pathenv(rootDoc)
    exts = exts + @@tmplExt.values.flatten  #if @cfg[:output]
    exts << "" #with extension
#puts "before finding paths";p filename;p @@mode;p exts
    exts.uniq!
    names=exts.map{|ext| Dyndoc.absolute_path(filename+ext,pathenv)}.compact
    name=(names.length>0 ? names[0] : nil)
    if warn
      print "WARNING: #{filename}  with extension #{exts.join(',')} not reachable in:\n #{pathenv.join('\n')}\n" unless name
      #puts "tmpl:";p name
    end
    return name
  end


  def Dyndoc.input_from_file(filename)
    return Dyndoc.read_content_file(Dyndoc.doc_filename(filename))
  end

  # the filename path has to be complete
  def Dyndoc.read_content_file(filename,aux={})
#p filename
    case File.extname(filename)
    when ".odt"
      odt=Dyndoc::Odt.new(filename)
      aux[:doc].inputs={} unless aux[:doc].inputs 
      aux[:doc].inputs[filename]= odt unless aux[:doc].inputs[filename]
      odt.body_from_content
    else
      File.read(filename)
    end
  end

  #find the name of the template when mode is given
  def Dyndoc.name_tmpl(name,mode=:all)
    #clean dtag
    dtags=[:dtag] #update if necessary
    dtag=name.scan(/(?:#{dtags.map{|e| "_#{e}_" }.join("|")})/)[0]
    if dtag
      name=name.gsub(/(?:#{dtags.map{|e| "_#{e}_" }.join("|")})/,"")
    end
#puts "name";p name
    #file exists?
    if File.exists? name
      return name
    elsif name.scan(/([^\.]*)(#{@@tmplExt.map{|e| e[1]}.flatten.uniq.map{|e| Regexp.escape(e)}.join("|")})+$/)[0]
      pathenv=Dyndoc.get_pathenv(Dyndoc.cfg_dyn[:root_doc],false) #RMK: do not know if false really matters here (introduced just in case in get_pathenv!!!) 
#puts "pathenv";p pathenv; p Dyndoc.absolute_path(name,pathenv)
      return Dyndoc.absolute_path(name,pathenv)
    else
      return Dyndoc.doc_filename(name,@@tmplExt[mode],true)
    end
  end

  def Dyndoc.make_dir(dir)
    tmp=File.expand_path(dir)
    FileUtils.mkdir_p(tmp) unless File.exists? tmp
  end

end
