#!/usr/bin/env ruby

# Copyright (C) 2001 Masahiro Sakai <s01397ms@sfc.keio.ac.jp>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# This is distributed freely in the sence of 
# GPL(GNU General Public License) or Ruby's licence.

require 'rouge/rouge'
require 'rouge/console'

STDERR.write <<EOT
==============================================================
Rouge - Lisp Interpriter written in Ruby

Copyright (C) 2001 Masahiro Sakai <s01397ms@sfc.keio.ac.jp>
    All rights reserved.
    This is free software with ABSOLUTELY NO WARRANTY.

This is distributed freely in the sence of 
GPL(GNU General Public License) or Ruby's licence.
==============================================================

EOT

STDERR.puts("initializing...")

vm = Lisp.new

Dir['lib/*scm'].each{|item|
  STDERR.puts("loading #{item}")
  vm.load(item)
}

Lisp::Console.run(vm)
