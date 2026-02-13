class Lisp
  module Console
    @@use_readline = false
    begin
      require 'readline'
      Readline.completion_proc = lambda do |input_str|
        result = []
        re = Regexp.compile('^' + Regexp.escape(input_str) + '.*')
        [vm.global_binding.hash, vm.sp_forms].each do |hash|
          hash.each_key do |sym|
            str = sym.to_s
            result.push(str) if re =~ str
          end
        end
        result
      end
      @@use_readline = true
    rescue LoadError
    end

    def eof?
      false
    end
    module_function :eof?

    def gets
      if @firstline
        prompt = 'rouge> '
        @firstline = false
      else
        prompt = 'rouge* '
      end

      if @@use_readline
        Readline.readline(prompt, true)
      else
        STDOUT.write(prompt)
        STDIN.gets
      end
    end
    module_function :gets

    def run(vm)
      @vm = vm
      reader = SexpReader.new(self)

      while true
        begin
          @firstline = true
          val = vm.evaluate(reader.read)
          STDOUT.puts(Lisp::Sexp(val, true)) if reader.buffer_empty? and val != Lisp::Unspecified
        rescue ScriptError, StandardError => e
          STDOUT.puts(e.inspect + "\n" + e.backtrace.join("\n"))
          reader.buffer_reset if e.is_a? SexpReader::ParseError
        end
      end
    end
    module_function :run

    def vm
      @vm
    end
    module_function :vm
  end # Console
end # Lisp
