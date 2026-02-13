# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../rouge/rouge'

# Create a VM instance and load the standard library
def create_vm
  vm = Lisp.new
  Dir[File.join(File.dirname(__FILE__), '..', 'lib', '*.scm')].each do |item|
    vm.load(item)
  end
  vm
end

# Evaluate a Lisp expression string and return the result
def lisp_eval(vm, str)
  reader = Lisp::SexpReader.new.scan(str)
  result = nil
  loop do
    result = vm.evaluate(reader.read)
  rescue Lisp::SexpReader::UnexpectedEndOfExpression
    break
  end
  result
end
