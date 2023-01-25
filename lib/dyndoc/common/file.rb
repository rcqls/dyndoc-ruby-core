module Dyndoc

	# allows to expand subpath of the form 'lib/<dyndoc/tutu/toto' 
	def Dyndoc.expand_path(filename)
		filename=File.expand_path(filename).split(File::Separator)
		to_find=filename.each_with_index.map{|pa,i| i if pa =~ /^\<[^\<\>]*/}.compact
		return File.join(filename) if to_find.empty?
		to_find=to_find[0]
		path=Dyndoc.find_subpath_before(File.join(filename[to_find][1..-1],filename[(to_find+1)...-1]),filename[0...to_find])
		return path ? Dyndoc.expand_path(File.join(path+filename[-1,1])) : nil
	end

	def Dyndoc.find_subpath_before(subpath,before)
		l=before.length+1
		return [before[0..l],subpath] if File.exist? File.join(before[0..l],subpath) while (l-=1)>=0
		return nil
	end

end

## inspired from http://stackoverflow.com/questions/21511347/how-to-create-a-symlink-on-windows-via-ruby
require 'open3'

class << File
  alias_method :old_symlink, :symlink
  alias_method :old_symlink?, :symlink?

  def symlink(target_name, link_name)
    #if on windows, call mklink, else self.symlink
    if RUBY_PLATFORM =~ /mswin32|cygwin|mingw|bccwin/
      #windows mklink syntax is reverse of unix ln -s
      #windows mklink is built into cmd.exe
      #vulnerable to command injection, but okay because this is a hack to make a cli tool work.
      opt = (File.directory? target_name) ? "/D" : ""
      stdin, stdout, stderr, wait_thr = Open3.popen3('cmd.exe', "/c mklink " + opt + "#{link_name} #{target_name}")
      wait_thr.value.exitstatus
    else
      self.old_symlink(target_name, link_name)
    end
  end

  def symlink?(file_name)
    #if on windows, call mklink, else self.symlink
    if RUBY_PLATFORM =~ /mswin32|cygwin|mingw|bccwin/
      #vulnerable to command injection because calling with cmd.exe with /c?
      stdin, stdout, stderr, wait_thr = Open3.popen3("cmd.exe /c dir #{file_name} | find \"SYMLINK\"")
      wait_thr.value.exitstatus
    else
      self.old_symlink?(file_name)
    end
  end
end