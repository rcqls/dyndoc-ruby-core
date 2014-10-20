#!ruby

require "libuv"
require "dyndoc-core"


module Dyndoc

  class InteractiveServer

    def initialize
      init_dyndoc
      init_uv_server
    end

    def init_dyndoc
      unless Dyndoc.tmpl_mngr
        Dyndoc.tmpl_mngr = Dyndoc::Ruby::TemplateManager.new({})
        Dyndoc.tmpl_mngr.init_doc({})
        puts "InteractiveServer initialized!\n"
      end
    end

    def process_dyndoc(content)
      Dyndoc.tmpl_mngr.parse(content)
    end

    def init_uv_server
      @log = []
      @general_failure = []
      @loop=Libuv::Loop.new
      @t = @loop.timer

      if Libuv::Signal::SIGNALS[:SIGINT]
        @loop.signal(Libuv::Signal::SIGNALS[:SIGINT]) do
          puts "connection closed"
          @t.stop
          @s.close
          @loop.stop
        end
      end

      @s = @loop.tcp

      @loop.all(@s, @c, @t).catch do |reason|
        @general_failure << reason.inspect
      end
          


    end

    def run
      @loop.run {|logger|
        logger.progress do |level, errorid, error|
          begin
            @general_failure << "Log called: #{level}: #{errorid}\n#{error.message}\n#{error.backtrace.join("\n") if error.backtrace}\n"
          rescue Exception => e
            @general_failure << "error in logger #{e.inspect}"
          end
        end

        @s.bind('127.0.0.1', 7777) do |s|
          puts "bound to #{s.sockname}"
  
          s.accept do |c|

            puts "connected (peer: #{c.peername})"
            c.progress do |b|
              data = b.to_s.strip
              @log << data
              ##p [:data,data]
              if data =~ /^__send_cmd__\[\[([a-z]*)\]\]__(.*)__\[\[END_TOKEN\]\]__$/m
                cmd,content = $1,$2
                ##p [:cmd,cmd,:content,content]
                if cmd == "dyndoc"
                  res = process_dyndoc(content)
                  ## p [content,res]
                  c.write "__send_cmd__[[dyndoc]]__"+res+"__[[END_TOKEN]]__"
                end
              end
            end
            c.start_read
          end
        end
        @s.listen(1024)
      }
    end

  end

end

Dyndoc::InteractiveServer.new.run
