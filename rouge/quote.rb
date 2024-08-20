class Lisp

  class Quote < SExpObject
    attr_reader :quoted

    def initialize(quoted)
      @quoted = quoted
    end

    def ==(x)
      (x.is_a? Quote) and self.quoted == x.quoted
    end

    def evaluate(vm_binding)
      @quoted
    end

    def to_s
      "'" + String(@quoted)
    end

    def to_sexp
      "'" + Lisp.Sexp(@quoted)
    end
  end


  class BackQuote < SExpObject
    attr_reader :quoted

    def initialize(quoted)
      @quoted = quoted
    end

    def ==(x)
      (x.is_a? BackQuote) and self.quoted == x.quoted
    end

    def evaluate(vm_binding)
      unless @quoted.is_a? Cons
        @quoted
      else
        result = Array.new
        Array(@quoted).each do |item|
          unless item.is_a? Unquote
            result.push(item)
          else
            val = vm_binding.vm.evaluate(item.content, vm_binding)
            if item.splicing?
              result << Array(val)
            else
              result.push(val)
            end
          end
        end
        Cons.from_a(result)
      end
    end

    def to_s
      "`" + String(@quoted)
    end

    def to_sexp
      "`" + Lisp.Sexp(@quoted)
    end
  end


  class Unquote < SExpObject
    def initialize(content, splicing)
      @content  = content
      @splicing = splicing
    end

    attr_reader :content

    def splicing?
      @splicing
    end

    def evaluate(vm_binding)
      raise "Unquote should not be evaluated"
    end

    def to_sexp
      if splicing?
        ",@" + Sexp(@content)
      else
        "," + Sexp(@content)
      end
    end
  end

end
