require "spec_helper"

module Y2R::AST
  describe Args do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Args.new(
          :children => [
            Const.new(:type => "int", :value => "42"),
            Const.new(:type => "int", :value => "43"),
            Const.new(:type => "int", :value => "44")
          ]
        )

        node.to_ruby.should == "42, 43, 44"
      end
    end
  end

  describe Assign do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Assign.new(
          :name  => "i",
          :child => Const.new(:type => "int", :value => "42")
        )

        node.to_ruby.should == "i = 42"
      end
    end
  end

  describe Block do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Block.new(
          :statements => Statements.new(
            :children => [
              Stmt.new(
                :child => Assign.new(
                  :name  => "i",
                  :child => Const.new(:type => "int", :value => "42")
                )
              ),
              Stmt.new(
                :child => Assign.new(
                  :name  => "j",
                  :child => Const.new(:type => "int", :value => "43")
                )
              ),
              Stmt.new(
                :child => Assign.new(
                  :name  => "k",
                  :child => Const.new(:type => "int", :value => "44")
                )
              )
            ]
          )
        )

        node.to_ruby.should == "i = 42\nj = 43\nk = 44"
      end
    end
  end

  describe Builtin do
    describe "#to_ruby" do
      it "emits correct code for builtins with no arguments" do
        node = Builtin.new(:name => "b", :children => [])

        node.to_ruby.should == "YCP::Builtins.b()"
      end

      it "emits correct code for builtins with arguments" do
        node = Builtin.new(
          :name     => "b",
          :children => [
            BuiltinElement.new(:child => Const.new(:type => "int", :value => "42")),
            BuiltinElement.new(:child => Const.new(:type => "int", :value => "43")),
            BuiltinElement.new(:child => Const.new(:type => "int", :value => "44"))
          ]
        )

        node.to_ruby.should == "YCP::Builtins.b(42, 43, 44)"
      end
    end
  end

  describe BuiltinElement do
    describe "#to_ruby" do
      it "emits correct code" do
        node = BuiltinElement.new(
          :child => Const.new(:type => "int", :value => "42")
        )

        node.to_ruby.should == "42"
      end
    end
  end

  describe Call do
    describe "#to_ruby" do
      it "emits correct code for a call without arguments" do
        node = Call.new(:ns => "n", :name => "f")

        node.to_ruby.should == "n.f()"
      end

      it "emits correct code for a call with arguments" do
        node = Call.new(
          :ns    => "n",
          :name  => "f",
          :child => Args.new(
            :children => [
              Const.new(:type => "int", :value => "42"),
              Const.new(:type => "int", :value => "43"),
              Const.new(:type => "int", :value => "44")
            ]
          )
        )

        node.to_ruby.should == "n.f(42, 43, 44)"
      end
    end
  end

  describe Cond do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Cond.new(:child => Const.new(:type => "bool", :value => "true"))

        node.to_ruby.should == "true"
      end
    end
  end

  describe Const do
    describe "#to_ruby" do
      it "emits correct code for void constants" do
        node = Const.new(:type => "void")

        node.to_ruby.should == "nil"
      end

      it "emits correct code for boolean constants" do
        node_true  = Const.new(:type => "bool", :value => "true")
        node_false = Const.new(:type => "bool", :value => "false")

        node_true.to_ruby.should  == "true"
        node_false.to_ruby.should == "false"
      end

      it "emits correct code for integer constants" do
        node = Const.new(:type => "int", :value => "42")

        node.to_ruby.should == "42"
      end

      it "emits correct code for float constants" do
        node_without_decimals = Const.new(:type => "float", :value => "42.")
        node_with_decimals    = Const.new(:type => "float", :value => "42.1")

        node_without_decimals.to_ruby.should == "42.0"
        node_with_decimals.to_ruby.should    == "42.1"
      end

      it "emits correct code for symbol constants" do
        node = Const.new(:type => "symbol", :value => "abcd")

        node.to_ruby.should == ":abcd"
      end

      it "emits correct code for string constants" do
        node = Const.new(:type => "string", :value => "abcd")

        node.to_ruby.should == "'abcd'"
      end

      it "emits correct code for path constants" do
        node = Const.new(:type => "path", :value => ".abcd")

        node.to_ruby.should == "YCP::Path.new('.abcd')"
      end
    end
  end

  describe Do do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Do.new(:child => Call.new(:ns => "n", :name => "f"))

        node.to_ruby.should == "n.f()"
      end
    end
  end

  describe Else do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Else.new(:child => Call.new(:ns => "n", :name => "f"))

        node.to_ruby.should == "n.f()"
      end
    end
  end

  describe Expr do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Expr.new(:child => Call.new(:ns => "n", :name => "f"))

        node.to_ruby.should == "n.f()"
      end
    end
  end

  describe If do
    describe "#to_ruby" do
      it "emits correct code for ifs without else" do
        node = If.new(
          :children => [
            Const.new(:type => "bool", :value => "true"),
            Then.new(:child => Call.new(:ns => "n", :name => "f"))
          ]
        )

        node.to_ruby.should == "if true\n  n.f()\nend"
      end

      it "emits correct code for ifs with else" do
        node = If.new(
          :children => [
            Const.new(:type => "bool", :value => "true"),
            Then.new(:child => Call.new(:ns => "n", :name => "f")),
            Else.new(:child => Call.new(:ns => "n", :name => "f"))
          ]
        )

        node.to_ruby.should == "if true\n  n.f()\nelse\n  n.f()\nend"
      end
    end
  end

  describe Import do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Import.new(:name => "M")

        node.to_ruby.should == "YCP.import('M')"
      end
    end
  end

  describe Key do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Key.new(:child => Const.new(:type => "symbol", :value => "a"))

        node.to_ruby.should == ":a"
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
            ListElement.new(:child => Const.new(:type => "int", :value => "42")),
            ListElement.new(:child => Const.new(:type => "int", :value => "43")),
            ListElement.new(:child => Const.new(:type => "int", :value => "44"))
          ]
        )

        node.to_ruby.should == "[42, 43, 44]"
      end
    end
  end

  describe ListElement do
    describe "#to_ruby" do
      it "emits correct code" do
        node = ListElement.new(
          :child => Const.new(:type => "int", :value => "42")
        )

        node.to_ruby.should == "42"
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
              :key   => Const.new(:type => "symbol", :value => "a"),
              :value => Const.new(:type => "int",    :value => "42")
            ),
            MapElement.new(
              :key   => Const.new(:type => "symbol", :value => "b"),
              :value => Const.new(:type => "int",    :value => "43")
            ),
            MapElement.new(
              :key   => Const.new(:type => "symbol", :value => "c"),
              :value => Const.new(:type => "int",    :value => "44")
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
          :key   => Const.new(:type => "symbol", :value => "a"),
          :value => Const.new(:type => "int",    :value => "42")
        )

        node.to_ruby.should == ":a => 42"
      end
    end
  end

  describe Statements do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Statements.new(
          :children => [
            Stmt.new(
              :child => Assign.new(
                :name  => "i",
                :child => Const.new(:type => "int", :value => "42")
              )
            ),
            Stmt.new(
              :child => Assign.new(
                :name  => "j",
                :child => Const.new(:type => "int", :value => "43")
              )
            ),
            Stmt.new(
              :child => Assign.new(
                :name  => "k",
                :child => Const.new(:type => "int", :value => "44")
              )
            )
          ]
        )

        node.to_ruby.should == "i = 42\nj = 43\nk = 44"
      end
    end
  end

  describe Stmt do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Stmt.new(
          :child => Assign.new(
            :name  => "i",
            :child => Const.new(:type => "int", :value => "42")
          )
        )

        node.to_ruby.should == "i = 42"
      end
    end
  end

  describe Symbol do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Symbol.new

        node.to_ruby.should == ""
      end
    end
  end

  describe Symbols do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Symbols.new(:children => [Symbol.new, Symbol.new, Symbol.new])

        node.to_ruby.should == ""
      end
    end
  end

  describe Then do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Then.new(:child => Call.new(:ns => "n", :name => "f"))

        node.to_ruby.should == "n.f()"
      end
    end
  end

  describe Value do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Value.new(:child => Const.new(:type => "int", :value => "42"))

        node.to_ruby.should == "42"
      end
    end
  end

  describe While do
    describe "#to_ruby" do
      it "emits correct code" do
        node = While.new(
          :cond => Cond.new(
            :child => Const.new(:type => "bool", :value => "true")
          ),
          :do   => Do.new(:child => Call.new(:ns => "n", :name => "f"))
        )

        node.to_ruby.should == "while true\n  n.f()\nend"
      end
    end
  end

  describe YCP do
    describe "#to_ruby" do
      it "emits correct code" do
        node = YCP.new(:child => Const.new(:type => "void"))

        node.to_ruby.should == "nil"
      end
    end
  end

  describe YETerm do
    describe "#to_ruby" do
      it "emits correct code for empty terms" do
        node = YETerm.new(:name => "a", :children => [])

        node.to_ruby.should == "YCP::Term.new(:a)"
      end

      it "emits correct code for non-empty terms" do
        node = YETerm.new(
          :name     => "a",
          :children => [
            YETermElement.new(
              :child => Const.new(:type => "int", :value => "42")
            ),
            YETermElement.new(
              :child => Const.new(:type => "int", :value => "43")
            ),
            YETermElement.new(
              :child => Const.new(:type => "int", :value => "44")
            )
          ]
        )

        node.to_ruby.should == "YCP::Term.new(:a, 42, 43, 44)"
      end
    end
  end

  describe YETermElement do
    describe "#to_ruby" do
      it "emits correct code" do
        node = YETermElement.new(
          :child => Const.new(:type => "int", :value => "42")
        )

        node.to_ruby.should == "42"
      end
    end
  end
end
