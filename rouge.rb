#!/usr/bin/env ruby

require_relative 'rouge/rouge'
require_relative 'rouge/console'

STDERR.write <<~EOT
  ==============================================================
  Rouge - Lisp Interpriter written in Ruby

  Copyright (C) 2001 Masahiro Sakai
  This is free software with ABSOLUTELY NO WARRANTY.
  ==============================================================

EOT

STDERR.puts('initializing...')

vm = Lisp.new

Dir[File.join(File.dirname(__FILE__), 'lib', '*scm')].each do |item|
  STDERR.puts("loading #{item}")
  vm.load(item)
end

Lisp::Console.run(vm)
