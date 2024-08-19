# coding: utf-8
#############################################################################
# パーサー
#  modified from sexp.rb
#############################################################################

#############################################################################
#
# Handling symbolic expression (S expression) with Ruby.
#
# Copyright (C) 2001 Satoru Takabayashi <satoru@namazu.org>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# This is distributed freely in the sence of 
# GPL(GNU General Public License) or Ruby's licence.
#
# The latest version: <http://cvs.namazu.org/ruby-sexp/>
#############################################################################

class Lisp


  class SexpReader
    class ParseError < RuntimeError; end

    class UnexpectedEndOfExpression < ParseError; end
    class UnexpectedDot < ParseError; end
    class UnexpectedRightParen < ParseError; end
    class UnexpectedToken < ParseError; end

    def initialize(io = nil)
      @tokens = Array.new
      @io = io
    end

    attr_accessor :io

    private

    def peek_token
      while buffer_empty?
	break if (not @io) or @io.eof?
	str = @io.gets
	scan(str) if str
      end
      @tokens.first
    end
  
    def skip_token
      @tokens.shift
      nil
    end
  
    def read_paren2
      if peek_token == ')' then
        return Null
      end
      car = read
      if peek_token == '.' then
        skip_token # skip '.'
        retval = Cons.new(car, read)
      else
        if peek_token == ')' then
          retval = Cons.new(car, Null)
        else
          retval = Cons.new(car, read_paren2)
        end
      end
    end
  
    def read_paren
      raise UnexpectedToken unless peek_token == '('
      skip_token  # (
      retval = read_paren2
      raise UnexpectedToken unless peek_token == ')'
      skip_token # )
      return retval
    end

    public

    def buffer_reset
      @tokens = Array.new
    end

    def buffer_empty?
      @tokens.empty?
    end
    
    def empty?
      buffer_empty? and ((not @io) or @io.eof?)
    end

    def read
      case peek_token
      when nil
	raise UnexpectedEndOfExpression
      when '.'
	raise UnexpectedDot
      when ')'
	raise UnexpectedRightParen
      when '('
        read_paren
      when '#('
	@tokens[0] = '(' # XXX
        Array(read_paren)
      when "'"
	skip_token
	Quote.new(read)
      when "`"
	skip_token
	BackQuote.new(read)
      when ","
	skip_token
	Unquote.new(read, false)
      when ",@"
	skip_token
	Unquote.new(read, true)
      else
        token = @tokens.shift
	token
      end
    end

    def scan(str)
      str.scan /(;.*)|(#?\()|(\))|(\.)|(['`])|(,@?)|("[^"\\]*(?:\\.[^"\\]*)*")|(?:#\\( |[^()\s]+))|([^()\s]+)/ do
        next if $1 # comment

        token = $2 if $2 # (sharp?) left paren
        token = $3 if $3 # right paren
        token = $4 if $4 # dot
	token = $5 if $5 # quote / back-quote
	token = $6 if $6 # unquote / unquote-splicing
        token = Character.new($8) if $8 # character

	# double-quoted string
	if $7
	  token = $7
	  token = Thread.new{ $SAFE = 4; eval(token) }.value
	end

	if $9
	  token = $9.downcase
	  case token
	  when "#t"
	    token = true
	  when "#f"
	    token = false
	  when /^[+-]?(?:[0-9]+)?\.[0-9]*$/
	    token = token.to_f # floating number
	  when /^[+-]?[0-9]+$/
	    token = token.to_i # integer number
	  when /^([+-]?[0-9]+)\/([0-9]+)$/
	    token = Rational($1.to_i, $2.to_i) # rational number
	  else
	    token = token.intern # symbol
	  end
	end

        @tokens.push(token)
      end

      self
    end

  end # class SexpReader

end # class Lisp
