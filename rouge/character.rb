class Lisp
  class Character < SExpObject
    include Comparable

    attr_reader :num

    NAME_TO_CHAR = {
      'space' => ?\s,
      'newline' => ?\n,
      'tab' => ?\t,
    }

    CHAR_TO_NAME = NAME_TO_CHAR.invert

    def initialize(obj)
      case obj
      when Integer
        @num = obj
      when String
        @num = if obj.size == 1
                 obj[0]
               else
                 NAME_TO_CHAR.fetch(obj) do
                   raise "Unknown character: #{obj}"
                 end
               end
      end
    end

    def name
      CHAR_TO_NAME.fetch(@num) do
        false
      end
    end

    def to_s
      '' << @num
    end

    def to_sexp
      s = CHAR_TO_NAME.fetch(@num) do
        String(self)
      end
      '#\\' + s
    end

    def upcase
      Character.new(String(self).upcase[0])
    end

    def downcase
      Character.new(String(self).downcase[0])
    end

    def to_i
      @num
    end

    def <=>(other)
      Integer(self) <=> Integer(other)
    end

    def alphabetic?
      s = String(self)
      (/^\w$/ === s) and !(/^\d$/ === s) and true
    end

    def numeric?
      /^\d$/ === String(self) and true
    end

    def whitespace?
      /^\s$/ === String(self) and true
    end

    def upper_case?
      @num.between(?A, ?Z)
    end

    def lower_case?
      @num.between(?a, ?z)
    end
  end
end
