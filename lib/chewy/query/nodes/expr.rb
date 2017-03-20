module Chewy
  class Query
    module Nodes
      class Expr < Base
        def &(other)
          Nodes::Bool.new.must(self, other)
        end

        def |(other)
          Nodes::Bool.new.should(self, other)
        end

        def !
          Nodes::Not.new self
        end

        def ~
          @options[:cache] = true
          self
        end

        def __render__
          raise NotImplementedError
        end
      end
    end
  end
end
