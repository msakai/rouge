

class Lisp

  class Console
    
    @@use_readline = false
    begin
      require 'readline'
      @@use_readline = true
    rescue LoadError
    end

    def eof?
      false
    end
  
    def gets
      if @firstline
	prompt = "rouge> "
	@firstline = false
      else
	prompt = "rouge* "
      end
  
      if @@use_readline
  	Readline.readline(prompt, true)
      else
  	STDOUT.write(prompt)
  	STDIN.gets
      end
    end
  
  
    def run
      reader = SexpReader.new(self)

      while true
	begin
	  @firstline = true
	  val = @vm.evaluate(reader.read)
	  if reader.buffer_empty? and val != Lisp::Unspecified
	    STDOUT.puts(Lisp::Sexp(val, true))
	  end
	rescue ScriptError, StandardError => ex
	  STDOUT.puts(ex.inspect + "\n" + ex.backtrace.join("\n"))
	  reader.buffer_reset if ex.is_a? SexpReader::ParseError
	end
      end
    end


    def initialize(vm)
      @vm = vm

      Readline.completion_proc = lambda do
  	|input_str|
  	result = Array.new
  	re = Regexp.compile('^' + Regexp.escape(input_str) + '.*')
  	[vm.global_binding.hash, vm.sp_forms].each{|hash|
  	  hash.each_key{|sym|
  	    str = sym.id2name
  	    result.push(str) if re =~ str
  	  }
  	}
  	result
      end
    end
  
  end # Console

end # Lisp
