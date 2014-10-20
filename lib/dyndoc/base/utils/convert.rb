# encoding: UTF-8

require "open3"
begin
  require 'redcloth'
rescue LoadError
  Dyndoc.warn "Warning: RedCloth not installed or supported!"
end
#require 'pandoc-ruby'

module Dyndoc

  module Converter

    SOFTWARE={}

    def Converter.mathlink(input)
      unless SOFTWARE[:mathlink]
        cmd=`type "math"`
        unless cmd.empty?
          require 'mathematica'
          SOFTWARE[:mathlink]=Mathematica::Mathematica.new.start  #cmd.strip.split(" ")[2] unless cmd.empty?
        end
      end
      SOFTWARE[:mathlink] ? SOFTWARE[:mathlink].eval_foreground(input) : ""
    end

    def Converter.pdflatex(input,opt='')
      output = ''
      unless SOFTWARE[:pdflatex]
        cmd=`type "pdflatex"`
        SOFTWARE[:pdflatex]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
      if SOFTWARE[:pdflatex]
        Open3.popen3("#{SOFTWARE[:pdflatex]} #{opt}") {|stdin,stdout,stderr|
          stdin.print input
          stdin.close
          output=stdout.read
        }
        return nil
      else
        $dyn_logger.write("ERROR pdflatex: software not installed!\n")
        return nil
      end
    end

    def Converter.pandoc(input,opt='')
      output = ''
      unless SOFTWARE[:pandoc]
        if File.exist? File.join(ENV["HOME"],".cabal","bin","pandoc")
          SOFTWARE[:pandoc]=File.join(ENV["HOME"],".cabal","bin","pandoc")
        else
          cmd = `which pandoc`.strip
          SOFTWARE[:pandoc]=cmd unless cmd.empty?
          #cmd=`type "pandoc"`
          #SOFTWARE[:pandoc]=cmd.strip.split(" ")[2] unless cmd.empty?
        end
      end
      if SOFTWARE[:pandoc]
        if input
          Open3::popen3(SOFTWARE[:pandoc]+" #{opt}") do |stdin, stdout, stderr| 
            stdin.puts input 
            stdin.close
            output = stdout.read.strip 
          end
          output
        else
          #p SOFTWARE[:pandoc]+" #{opt}"
          system(SOFTWARE[:pandoc]+" #{opt}")
        end
      else
        $dyn_logger.write("ERROR pandoc: software not installed!\n")
        ""
      end
    end

# ttm converter
    def Converter.ttm(input,opt='-e2')
#puts "ttm:begin"
      output=nil
      unless SOFTWARE[:ttm]
        cmd=`type "ttm"`
        SOFTWARE[:ttm]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
      if SOFTWARE[:ttm]
        Open3.popen3("#{SOFTWARE[:ttm]} #{opt}") {|stdin,stdout,stderr|
        	stdin.print input
        	stdin.close
        	output=stdout.read
  #puts "ttm:wait"
        }
  #puts "ttm:end"
        output.gsub("__VERBATIM__","verbatim").sub(/\A\n*/,"") #the last is because ttm adds 6 \n for nothing!
      else
         $dyn_logger.write("ERROR ttm: software not installed!\n")
        ""
      end
    end

    def Converter.convert(input,format,outputFormat,to_protect=nil)
      ##
      format=format.to_s unless format.is_a? String
      ## Dyndoc.warn "convert input",[input,format]
      outputFormat=outputFormat.to_s unless outputFormat.is_a? String
      res=""
      input.split("__PROTECTED__FORMAT__").each_with_index do |code,i|
        ## Dyndoc.warn "code",[i,code,format+">"+outputFormat]
        if i%2==0
          res << case format+outputFormat
          when "md>html"
            ##PandocRuby.new(code, :from => :markdown, :to => :html).convert
            Dyndoc::Converter.pandoc(code)
          when "md>tex"
            #puts "latex documentclass";p Dyndoc::Utils.dyndoc_globvar("_DOCUMENTCLASS_")
            if Dyndoc::Utils.dyndoc_globvar("_DOCUMENTCLASS_")=="beamer"
              Dyndoc::Converter.pandoc(code,"-t beamer")
            else
              Dyndoc::Converter.pandoc(code,"-t latex")
            end
          when "md>odt"
            ##PandocRuby.new(code, :from => :markdown, :to => :opendocument).convert
            Dyndoc::Converter.pandoc(code,"-t opendocument")
          when "txtl>html"
            (rc=RedCloth.new(code))
            rc.hard_breaks=false
            rc.to_html
          when "txtl>tex"
            RedCloth.new(code).to_latex   
          when "ttm>html"
            Dyndoc::Converter.ttm(code,"-e2 -r -y1 -L").gsub(/<mtable[^>]*>/,"<mtable>").gsub("\\ngtr","<mtext>&ngtr;</mtext>").gsub("\\nless","<mtext>&nless;</mtext>").gsub("&#232;","<mtext>&egrave;</mtext>")
          when "tex>odt"
            puts "tex => odt"
            tmp="<text:p><draw:frame draw:name=\""+`uuidgen`.strip+"\" draw:style-name=\"mml-inline\" text:anchor-type=\"as-char\" draw:z-index=\"0\" ><draw:object>"+Dyndoc::Converter.pandoc(code,"--mathml -f latex -t html").gsub(/<\/?p>/,"").gsub(/<(\/?)([^\<]*)>/) {|e| "<"+($1 ? $1 : "")+"math:"+$2+">"}+"</draw:object></draw:frame></text:p>"
            ##p tmp
            tmp
          when "tex>html"
            ##PandocRuby.new(code, :from => :markdown, :to => :html).convert
            Dyndoc::Converter.pandoc(code,"--mathjax -f latex -t html")             
          when "ttm>tex", "html>html",'tex>tex'
            code
          ## the rest returns nothing!
          end
        else
          res << code
        end
        #puts "res";p res
      end
      return (to_protect ? "__PROTECTED__FORMAT__"+res+"__PROTECTED__FORMAT__": res)
    end

  end
end
