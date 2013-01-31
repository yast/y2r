require "spec_helper"

module Y2R::AST
  describe Assign do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Assign.new(
          :name  => "i",
          :child => Const.new(:type => :int, :value => "42")
        )

        node.to_ruby.should == "i = 42"
      end
    end
  end

  describe Block do
    describe "#to_ruby" do
      it "emits correct code for def blocks" do
        node = Block.new(
          :kind       => :def,
          :statements => [
            Assign.new(
              :name  => "i",
              :child => Const.new(:type => :int, :value => "42")
            ),
            Assign.new(
              :name  => "j",
              :child => Const.new(:type => :int, :value => "43")
            ),
            Assign.new(
              :name  => "k",
              :child => Const.new(:type => :int, :value => "44")
            )
          ]
        )

        node.to_ruby.should == "i = 42\nj = 43\nk = 44"
      end

      it "emits correct code for file blocks" do
        node = Block.new(
          :kind       => :file,
          :statements => [
            Assign.new(
              :name  => "i",
              :child => Const.new(:type => :int, :value => "42")
            ),
            Assign.new(
              :name  => "j",
              :child => Const.new(:type => :int, :value => "43")
            ),
            Assign.new(
              :name  => "k",
              :child => Const.new(:type => :int, :value => "44")
            )
          ]
        )

        node.to_ruby.should == "i = 42\nj = 43\nk = 44"
      end

      it "emits correct code for unspec blocks" do
        node = Block.new(
          :kind       => :unspec,
          :statements => [
            Assign.new(
              :name  => "i",
              :child => Const.new(:type => :int, :value => "42")
            ),
            Assign.new(
              :name  => "j",
              :child => Const.new(:type => :int, :value => "43")
            ),
            Assign.new(
              :name  => "k",
              :child => Const.new(:type => :int, :value => "44")
            )
          ]
        )

        node.to_ruby.should == "lambda {\n  i = 42\n  j = 43\n  k = 44\n}"
      end

      it "raises an exception for stmt blocks" do
        node = Block.new(
          :kind       => :stmt,
          :statements => [
            Assign.new(
              :name  => "i",
              :child => Const.new(:type => :int, :value => "42")
            ),
            Assign.new(
              :name  => "j",
              :child => Const.new(:type => :int, :value => "43")
            ),
            Assign.new(
              :name  => "k",
              :child => Const.new(:type => :int, :value => "44")
            )
          ]
        )

        lambda {
          node.to_ruby
        }.should raise_error NotImplementedError, "Statement blocks are not supported."
      end
    end
  end

  describe Builtin do
    describe "#to_ruby" do
      it "emits correct code for builtins with no arguments" do
        node = Builtin.new(:name => "b", :children => [])

        node.to_ruby.should == "Builtins.b()"
      end

      it "emits correct code for builtins with arguments" do
        node = Builtin.new(
          :name     => "b",
          :children => [
            Const.new(:type => :int, :value => "42"),
            Const.new(:type => :int, :value => "43"),
            Const.new(:type => :int, :value => "44")
          ]
        )

        node.to_ruby.should == "Builtins.b(42, 43, 44)"
      end
    end
  end

  describe Call do
    describe "#to_ruby" do
      it "emits correct code for a call without arguments" do
        node = Call.new(:ns => "n", :name => "f", :args => [])

        node.to_ruby.should == "n.f()"
      end

      it "emits correct code for a call with arguments" do
        node = Call.new(
          :ns   => "n",
          :name => "f",
          :args => [
            Const.new(:type => :int, :value => "42"),
            Const.new(:type => :int, :value => "43"),
            Const.new(:type => :int, :value => "44")
          ]
        )

        node.to_ruby.should == "n.f(42, 43, 44)"
      end
    end
  end

  describe Compare do
    describe "#to_ruby" do
      it "emits correct code" do
        lhs = Const.new(:type => :int, :value => "42")
        rhs = Const.new(:type => :int, :value => "43")

        node_equal            = Compare.new(:op => "==", :lhs => lhs, :rhs => rhs)
        node_not_equal        = Compare.new(:op => "!=", :lhs => lhs, :rhs => rhs)
        node_less_than        = Compare.new(:op => "<",  :lhs => lhs, :rhs => rhs)
        node_greater_than     = Compare.new(:op => ">",  :lhs => lhs, :rhs => rhs)
        node_less_or_equal    = Compare.new(:op => "<=", :lhs => lhs, :rhs => rhs)
        node_greater_or_equal = Compare.new(:op => ">=", :lhs => lhs, :rhs => rhs)

        node_equal.to_ruby.should            == "Ops.equal(42, 43)"
        node_not_equal.to_ruby.should        == "Ops.not_equal(42, 43)"
        node_less_than.to_ruby.should        == "Ops.less_than(42, 43)"
        node_greater_than.to_ruby.should     == "Ops.greater_than(42, 43)"
        node_less_or_equal.to_ruby.should    == "Ops.less_or_equal(42, 43)"
        node_greater_or_equal.to_ruby.should == "Ops.greater_or_equal(42, 43)"
      end
    end
  end

  describe Const do
    describe "#to_ruby" do
      it "emits correct code for void constants" do
        node = Const.new(:type => :void)

        node.to_ruby.should == "nil"
      end

      it "emits correct code for boolean constants" do
        node_true  = Const.new(:type => :bool, :value => "true")
        node_false = Const.new(:type => :bool, :value => "false")

        node_true.to_ruby.should  == "true"
        node_false.to_ruby.should == "false"
      end

      it "emits correct code for integer constants" do
        node = Const.new(:type => :int, :value => "42")

        node.to_ruby.should == "42"
      end

      it "emits correct code for float constants" do
        node_without_decimals = Const.new(:type => :float, :value => "42.")
        node_with_decimals    = Const.new(:type => :float, :value => "42.1")

        node_without_decimals.to_ruby.should == "42.0"
        node_with_decimals.to_ruby.should    == "42.1"
      end

      it "emits correct code for symbol constants" do
        node = Const.new(:type => :symbol, :value => "abcd")

        node.to_ruby.should == ":abcd"
      end

      it "emits correct code for string constants" do
        node = Const.new(:type => :string, :value => "abcd")

        node.to_ruby.should == "'abcd'"
      end

      it "emits correct code for path constants" do
        node = Const.new(:type => :path, :value => ".abcd")

        node.to_ruby.should == "Path.new('.abcd')"
      end
    end
  end

  describe FunDef do
    describe "#to_ruby" do
      it "emits correct code for fundefs without arguments" do
        node = FunDef.new(
          :name  => "f",
          :args  => [],
          :block => Block.new(
            :kind       => :file,
            :statements => [
              Return.new(:child => Const.new(:type => :int, :value => "42"))
            ]
          )
        )

        node.to_ruby.should == "def f()\n  return 42\nend\n"
      end

      it "emits correct code for fundefs with arguments" do
        node = FunDef.new(
          :name  => "f",
          :args  => [
            Symbol.new(:name => "a"),
            Symbol.new(:name => "b"),
            Symbol.new(:name => "c")
          ],
          :block => Block.new(
            :kind       => :file,
            :statements => [
              Return.new(:child => Const.new(:type => :int, :value => "42"))
            ]
          )
        )

        node.to_ruby.should == "def f(a, b, c)\n  return 42\nend\n"
      end

      it "raises an exception for nested functions" do
        node = FunDef.new(
          :name  => "f",
          :args  => [],
          :block => Block.new(
            :kind       => :file,
            :statements => [
              Return.new(:child => Const.new(:type => :int, :value => "42"))
            ]
          )
        )

        lambda {
          node.to_ruby(Context.new(:blocks => [:file, :def]))
        }.should raise_error NotImplementedError, "Nested functions are not supported."
      end
    end
  end

  describe If do
    describe "#to_ruby" do
      it "emits correct code for ifs without else" do
        node = If.new(
          :cond => Const.new(:type => :bool, :value => "true"),
          :then => Call.new(:ns => "n", :name => "f", :args => []),
          :else => nil
        )

        node.to_ruby.should == "if true\n  n.f()\nend"
      end

      it "emits correct code for ifs with else" do
        node = If.new(
          :cond => Const.new(:type => :bool, :value => "true"),
          :then => Call.new(:ns => "n", :name => "f", :args => []),
          :else => Call.new(:ns => "n", :name => "f", :args => [])
        )

        node.to_ruby.should == "if true\n  n.f()\nelse\n  n.f()\nend"
      end
    end
  end

  describe Import do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Import.new(:name => "M")

        node.to_ruby.should == "YCP.import('M')\n"
      end
    end
  end

  describe List do
    describe "#to_ruby" do
      it "emits correct code for empty lists" do
        node = List.new(:children => [])

        node.to_ruby.should == "[]"
      end

      it "emits correct code for non-empty lists" do
        node = List.new(
          :children => [
            Const.new(:type => :int, :value => "42"),
            Const.new(:type => :int, :value => "43"),
            Const.new(:type => :int, :value => "44")
          ]
        )

        node.to_ruby.should == "[42, 43, 44]"
      end
    end
  end

  describe Locale do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Locale.new(
          :text => "Translated text."
        )

        node.to_ruby.should == "_('Translated text.')"
      end
    end
  end

  describe Map do
    describe "#to_ruby" do
      it "emits correct code for empty maps" do
        node = Map.new(:children => [])

        node.to_ruby.should == "{}"
      end

      it "emits correct code for non-empty maps" do
        node = Map.new(
          :children => [
            MapElement.new(
              :key   => Const.new(:type => :symbol, :value => "a"),
              :value => Const.new(:type => :int,    :value => "42")
            ),
            MapElement.new(
              :key   => Const.new(:type => :symbol, :value => "b"),
              :value => Const.new(:type => :int,    :value => "43")
            ),
            MapElement.new(
              :key   => Const.new(:type => :symbol, :value => "c"),
              :value => Const.new(:type => :int,    :value => "44")
            )
          ]
        )

        node.to_ruby.should == "{ :a => 42, :b => 43, :c => 44 }"
      end
    end
  end

  describe MapElement do
    describe "#to_ruby" do
      it "emits correct code" do
        node = MapElement.new(
          :key   => Const.new(:type => :symbol, :value => "a"),
          :value => Const.new(:type => :int,    :value => "42")
        )

        node.to_ruby.should == ":a => 42"
      end
    end
  end

  describe Return do
    describe "#to_ruby" do
      it "emits correct code for a return without a value" do
        node = Return.new(:child => nil)

        node.to_ruby.should == "return"
      end

      it "emits correct code for a return with a value" do
        node = Return.new(
          :child => Const.new(:type => :int, :value => "42")
        )

        node.to_ruby.should == "return 42"
      end
    end
  end

  describe Symbol do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Symbol.new(:name => "s")

        node.to_ruby.should == "s"
      end
    end
  end

  describe Textdomain do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Textdomain.new(:name => "d")

        node.to_ruby.should == "FastGettext.text_domain = 'd'\n"
      end
    end
  end

  describe Variable do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Variable.new(:name => "v")

        node.to_ruby.should == "v"
      end
    end
  end

  describe While do
    describe "#to_ruby" do
      it "emits correct code" do
        node = While.new(
          :cond => Const.new(:type => :bool, :value => "true"),
          :do   => Call.new(:ns => "n", :name => "f", :args => [])
        )

        node.to_ruby.should == "while true\n  n.f()\nend"
      end
    end
  end

  describe YEBinary do
    describe "#to_ruby" do
      it "emits correct code" do
        lhs = Const.new(:type => :int, :value => "42")
        rhs = Const.new(:type => :int, :value => "43")

        node_add         = YEBinary.new(:name => "+",  :lhs => lhs, :rhs => rhs)
        node_subtract    = YEBinary.new(:name => "-",  :lhs => lhs, :rhs => rhs)
        node_multiply    = YEBinary.new(:name => "*",  :lhs => lhs, :rhs => rhs)
        node_divide      = YEBinary.new(:name => "/",  :lhs => lhs, :rhs => rhs)
        node_modulo      = YEBinary.new(:name => "%",  :lhs => lhs, :rhs => rhs)
        node_bitwise_and = YEBinary.new(:name => "&",  :lhs => lhs, :rhs => rhs)
        node_bitwise_or  = YEBinary.new(:name => "|" , :lhs => lhs, :rhs => rhs)
        node_bitwise_xor = YEBinary.new(:name => "^" , :lhs => lhs, :rhs => rhs)
        node_shift_left  = YEBinary.new(:name => "<<", :lhs => lhs, :rhs => rhs)
        node_shift_right = YEBinary.new(:name => ">>", :lhs => lhs, :rhs => rhs)
        node_logical_and = YEBinary.new(:name => "&&", :lhs => lhs, :rhs => rhs)
        node_logical_or  = YEBinary.new(:name => "||", :lhs => lhs, :rhs => rhs)

        node_add.to_ruby.should         == "Ops.add(42, 43)"
        node_subtract.to_ruby.should    == "Ops.subtract(42, 43)"
        node_multiply.to_ruby.should    == "Ops.multiply(42, 43)"
        node_divide.to_ruby.should      == "Ops.divide(42, 43)"
        node_modulo.to_ruby.should      == "Ops.modulo(42, 43)"
        node_bitwise_and.to_ruby.should == "Ops.bitwise_and(42, 43)"
        node_bitwise_or.to_ruby.should  == "Ops.bitwise_or(42, 43)"
        node_bitwise_xor.to_ruby.should == "Ops.bitwise_xor(42, 43)"
        node_shift_left.to_ruby.should  == "Ops.shift_left(42, 43)"
        node_shift_right.to_ruby.should == "Ops.shift_right(42, 43)"
        node_logical_and.to_ruby.should == "Ops.logical_and(42, 43)"
        node_logical_or.to_ruby.should  == "Ops.logical_or(42, 43)"
      end
    end
  end

  describe YEBracket do
    describe "#to_ruby" do
      it "emits correct code" do
        node = YEBracket.new(
          :value => List.new(
            :children => [
              Const.new(:type => :int, :value => "42"),
              Const.new(:type => :int, :value => "43"),
              Const.new(:type => :int, :value => "44")
            ]
          ),
          :index => List.new(
            :children => [Const.new(:type => :int, :value => "1")]
          ),
          :default => Const.new(:type => :int, :value => "0")
        )

        node.to_ruby.should == "Ops.index([42, 43, 44], [1], 0)"
      end
    end
  end

  describe YETerm do
    describe "#to_ruby" do
      it "emits correct code for empty terms" do
        node = YETerm.new(:name => "a", :children => [])

        node.to_ruby.should == "Term.new(:a)"
      end

      it "emits correct code for non-empty terms" do
        node = YETerm.new(
          :name     => "a",
          :children => [
            Const.new(:type => :int, :value => "42"),
            Const.new(:type => :int, :value => "43"),
            Const.new(:type => :int, :value => "44")
          ]
        )

        node.to_ruby.should == "Term.new(:a, 42, 43, 44)"
      end
    end
  end

  describe YETriple do
    describe "#to_ruby" do
      it "emits correct code" do
        node = YETriple.new(
          :cond  => Const.new(:type => :bool, :value => "true"),
          :true  => Const.new(:type => :int, :value => "42"),
          :false => Const.new(:type => :int, :value => "43")
        )

        node.to_ruby.should == "true ? 42 : 43"
      end
    end
  end

  describe YEUnary do
    describe "#to_ruby" do
      it "emits correct code" do
        child = Const.new(:type => :int, :value => "42")

        node_unary_minus = YEUnary.new(:name => "-", :child => child)
        node_bitwise_not = YEUnary.new(:name => "~", :child => child)
        node_logical_not = YEUnary.new(:name => "!", :child => child)

        node_unary_minus.to_ruby.should == "Ops.unary_minus(42)"
        node_bitwise_not.to_ruby.should == "Ops.bitwise_not(42)"
        node_logical_not.to_ruby.should == "Ops.logical_not(42)"
      end
    end
  end
end
