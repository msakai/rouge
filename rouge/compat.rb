# ruby-1.6への後方互換性のため
unless Enumerable.method_defined? :inject
  module Enumerable
    def inject(result)
      tmp = result
      self.each{|item| tmp = yield(tmp, item)}
      tmp
    end
  end
end
