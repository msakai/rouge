# ruby-1.6�ؤθ����ߴ����Τ���
unless Enumerable.method_defined? :inject
  module Enumerable
    def inject(result)
      tmp = result
      self.each{|item| tmp = yield(tmp, item)}
      tmp
    end
  end
end
