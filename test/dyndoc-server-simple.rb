#!ruby

require 'socket'                # Get sockets from stdlib
require "dyndoc-core"


module Dyndoc

  class InteractiveServer

    def initialize
      @tmpl_mngr=nil
      init_dyndoc
      init_server
    end

    def init_dyndoc
      unless @tmpl_mngr
        Dyndoc.cfg_dyn['dyndoc_session']=:interactive
        @tmpl_mngr = Dyndoc::Ruby::TemplateManager.new({})
        @tmpl_mngr.init_doc({:format_output=> "html"})
        puts "InteractiveServer initialized!\n"
      end
    end

    def process_dyndoc(content)
      ##p [:process_dyndoc_content,content]
      @tmpl_mngr.parse(content)
    end

    def init_server  
      @server = TCPServer.new('0.0.0.0',7777)
    end

    def run
    	trap("SIGINT") { @server.close;exit! }
		loop {
			socket = @server.accept

			b=socket.recv(100000)
			##p [:b,b]
			data=b.to_s.strip
			##p [:data,data]
			if data =~ /^__send_cmd__\[\[([a-z]*)\]\]__(.*)__\[\[END_TOKEN\]\]__$/m
			cmd,content = $1,$2
			##p [:cmd,cmd,:content,content]
			if content.strip == "__EXIT__" 
				socket.close
				@server.close
				break
			end
			if cmd == "dyndoc"
			  res = process_dyndoc(content)
			  ## p [:dyndoc_server,content,res]
			  socket.write "__send_cmd__[[dyndoc]]__"+res+"__[[END_TOKEN]]__"
			end
			end
			socket.close
		}
    end

  end

end

Dyndoc::InteractiveServer.new.run