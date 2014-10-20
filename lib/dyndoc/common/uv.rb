require 'uv'
require 'textpow'

## fix Textpow::ScoreManager::START_VALUE class supposed to be a Bignum
unless Textpow::ScoreManager::START_VALUE.is_a? Bignum
  require 'bigdecimal'
  Textpow::ScoreManager.send(:remove_const,:START_VALUE)
  Textpow::ScoreManager.const_set(:START_VALUE,(BigDecimal("2") ** ( Textpow::ScoreManager::POINT_DEPTH * Textpow::ScoreManager::NESTING_DEPTH )).to_i)
end

module Uv

  self.syntax_path=File.join(Dyndoc.cfg_dir[:gem_path],"share","syntax","ultraviolet","syntax")
  self.render_path=File.join(Dyndoc.cfg_dir[:gem_path],"share","syntax","ultraviolet","render")

  def self.parse(text, output = "xhtml", syntax_name = nil, line_numbers = false, render_style = nil, headers = false)
    Dyndoc::RenderProcessor.load(output, render_style, line_numbers, headers) do |processor|
      syntax_node_for(syntax_name).parse(text, processor)
    end.string
  end

end

module Dyndoc

  class RenderProcessor
    @@score_manager = Textpow::ScoreManager.new

    attr_reader :string
    attr_accessor :escapeHTML

    def self.load(output, style = nil, line_numbers = false, headers = false)
      style  ||= Uv.default_style
      renderer = File.join( Uv.render_path, output,"#{style}.render")
      raise( ArgumentError, "Output for #{output} in #{style} style is not yet implemented" ) unless File.exists?(renderer)
      options   = YAML.load_file(renderer)
      processor = RenderProcessor.new(options, line_numbers, headers)
      yield processor if block_given?
      processor
    end

    def initialize render_options, line_numbers = false, headers = true, score_manager = nil
      @score_manager  = score_manager || @@score_manager
      @render_options = render_options
      @options        = {}
      @headers        = headers
      @line_numbers   = line_numbers
      @escapeHTML     = true
    end
    
    def start_parsing name
      @stack       = [name]
      @string      = ""
      @line        = nil
      @line_number = 0
      ## Dyndoc.warn "render_options",@render_options["listing"]
      print @render_options["document"]["begin"] if @headers
      ## FIX (01/09/2014): "begin-line-numbers" undefined for xhtml and has to replaced by "begin" 
      print (@line_numbers ? @render_options["listing"]["begin"] : @render_options["listing"]["begin-line-numbers"] || @render_options["listing"]["begin"])
      #         opt = options @stack
      #         print opt["begin"] if opt
    end
    
    def print string
      @string << string
    end
    
    def escape string
      if @render_options["filter"]
        @escaped = string
        @escaped = self.instance_eval( @render_options["filter"] )
        @escaped
      else
        string
      end
    end
    
    def open_tag name, position
      @stack << name
      print escape(@line[@position...position].gsub(/\n|\r/, '')) if position > @position
      @position = position
      opt = options @stack
      print opt["begin"] if opt
    end
    
    def close_tag name, position
      print escape(@line[@position...position].gsub(/\n|\r/, '')) if position > @position
      @position = position
      opt = options @stack
      print opt["end"] if opt
      @stack.pop
    end
    
    def close_line
      stack = @stack[0..-1]
      while stack.size > 1
        opt = options stack
        print opt["end"] if opt
        stack.pop
      end
    end
    
    def open_line
      stack = [@stack.first]
      clone = @stack[1..-1]
      while stack.size < @stack.size
        stack << clone.shift
        opt = options stack
        print opt["begin"] if opt
      end
    end
    
    def new_line line
      if @line
        print escape(@line[@position..-1].gsub(/\n|\r/, ''))
        close_line
        print @render_options["line"]["end"]
        print "\n" 
      end
      @position = 0
      @line_number += 1
      @line = line
      print @render_options["line"]["begin"]
      if @line_numbers
        print @render_options["line-numbers"]["begin"] 
        print @line_number.to_s.rjust(4).ljust(5)
        print @render_options["line-numbers"]["end"] 
        print " "
      end
      open_line
    end
    
    def end_parsing name
      if @line
        print escape(@line[@position..-1].gsub(/\n|\r/, '')) 
        while @stack.size > 1
          opt = options @stack
          print opt["end"] if opt
          @stack.pop
        end
        print @render_options["line"]["end"]
        print "\n"
      end
      #         opt = options @stack
      #         print opt["end"] if opt
      @stack.pop
      print @render_options["listing"]["end"]
      print @render_options["document"]["end"] if @headers
    end
    
    def options stack
      ref = stack.join ' '
      return @options[ref] if @options.has_key? ref
    
      result = @render_options['tags'].max do |a, b| 
        @score_manager.score( a['selector'], ref ) <=> @score_manager.score( b['selector'], ref )
      end
      result = nil if @score_manager.score( result['selector'], ref ) == 0
      @options[ref] = result
    end
  end
end

