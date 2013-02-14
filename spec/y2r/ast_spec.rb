require "spec_helper"

module Y2R::AST
  describe Assign do
    describe "#to_ruby" do
      before :each do
        @node_unprefixed_i = Assign.new(
          :name  => "i",
          :child => Const.new(:type => :int, :value => "42")
        )
        @node_unprefixed_j = Assign.new(
          :name  => "j",
          :child => Const.new(:type => :int, :value => "42")
        )
        @node_prefixed_m = Assign.new(
          :name  => "M::i",
          :child => Const.new(:type => :int, :value => "42")
        )
        @node_prefixed_n = Assign.new(
          :name  => "N::i",
          :child => Const.new(:type => :int, :value => "42")
        )
        @node_capital    = Assign.new(
          :name  => "I",
          :child => Const.new(:type => :int, :value => "42")
        )
        @node_underscore = Assign.new(
          :name  => "_i",
          :child => Const.new(:type => :int, :value => "42")
        )

        @def_block    = DefBlock.new(
          :symbols => [
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "i"
            )
          ]
        )
        @file_block   = FileBlock.new(:symbols => [])
        @module_block = ModuleBlock.new(:name => "M", :symbols => [])
      end

      describe "at client toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@file_block])

          @node_unprefixed_i.to_ruby(context).should == "i = 42"
          @node_unprefixed_j.to_ruby(context).should == "j = 42"
          @node_prefixed_m.to_ruby(context).should   == "M::i = 42"
          @node_prefixed_n.to_ruby(context).should   == "N::i = 42"
          @node_capital.to_ruby(context).should      == "_I = 42"
          @node_underscore.to_ruby(context).should   == "__i = 42"
        end
      end

      describe "at module toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@module_block])

          @node_unprefixed_i.to_ruby(context).should == "@i = 42"
          @node_unprefixed_j.to_ruby(context).should == "@j = 42"
          @node_prefixed_m.to_ruby(context).should   == "@i = 42"
          @node_prefixed_n.to_ruby(context).should   == "N::i = 42"
          @node_capital.to_ruby(context).should      == "@I = 42"
          @node_underscore.to_ruby(context).should   == "@_i = 42"
        end
      end

      describe "inside a function at client toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@file_block, @def_block])

          @node_unprefixed_i.to_ruby(context).should == "i = 42"
          @node_unprefixed_j.to_ruby(context).should == "j = 42"
          @node_prefixed_m.to_ruby(context).should   == "M::i = 42"
          @node_prefixed_n.to_ruby(context).should   == "N::i = 42"
          @node_capital.to_ruby(context).should      == "_I = 42"
          @node_underscore.to_ruby(context).should   == "__i = 42"
        end
      end

      describe "inside a function at module toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@module_block, @def_block])

          @node_unprefixed_i.to_ruby(context).should == "i = 42"
          @node_unprefixed_j.to_ruby(context).should == "@j = 42"
          @node_prefixed_m.to_ruby(context).should   == "@i = 42"
          @node_prefixed_n.to_ruby(context).should   == "N::i = 42"
          @node_capital.to_ruby(context).should      == "@I = 42"
          @node_underscore.to_ruby(context).should   == "@_i = 42"
        end
      end
    end
  end

  describe Bracket do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Bracket.new(
          :entry => Variable.new(:name => "l"),
          :arg => List.new(
            :children => [Const.new(:type => :int, :value => "1")]
          ),
          :rhs => Const.new(:type => :int, :value => "42")
        )

        node.to_ruby.should == "Ops.assign(@l, [1], 42)"
      end
    end
  end

  describe Break do
    describe "#to_ruby" do
      before :each do
        @node = Break.new
      end

      describe "inside a loop" do
        it "emits correct code" do
          context = Context.new(:blocks => [FileBlock.new, While.new])

          @node.to_ruby(context).should == "break"
        end
      end

      describe "inside a loop which is inside a block expression" do
        it "emits correct code" do
          context = Context.new(:blocks => [FileBlock.new, UnspecBlock.new, While.new])

          @node.to_ruby(context).should == "break"
        end
      end

      describe "inside a block expression" do
        it "emits correct code" do
          context = Context.new(:blocks => [FileBlock.new, UnspecBlock.new])

          @node.to_ruby(context).should == "raise Break"
        end
      end

      describe "inside a block expression which is inside a loop" do
        it "emits correct code" do
          context = Context.new(:blocks => [FileBlock.new, UnspecBlock.new])

          @node.to_ruby(context).should == "raise Break"
        end
      end
    end
  end

  describe Builtin do
    describe "#to_ruby" do
      it "emits correct code for builtins with no arguments and no block" do
        node = Builtin.new(
          :name    => "b",
          :args    => [],
          :block   => nil
        )

        node.to_ruby.should == "Builtins.b"
      end

      it "emits correct code for builtins with arguments and no block" do
        node = Builtin.new(
          :name    => "b",
          :args    => [
            Const.new(:type => :int, :value => "42"),
            Const.new(:type => :int, :value => "43"),
            Const.new(:type => :int, :value => "44")
          ],
          :block   => nil
        )

        node.to_ruby.should == "Builtins.b(42, 43, 44)"
      end

      it "emits correct code for builtins with no arguments and a block" do
        node = Builtin.new(
          :name    => "b",
          :args    => [],
          :block   => UnspecBlock.new(
            :args       => [
              Symbol.new(
                :global   => false,
                :category => :variable,
                :type     => "integer",
                :name     => "a"
              ),
              Symbol.new(
                :global   => false,
                :category => :variable,
                :type     => "integer",
                :name     => "b"
              ),
              Symbol.new(
                :global   => false,
                :category => :variable,
                :type     => "integer",
                :name     => "c"
              )
            ],
            :symbols    => [],
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
        )

        node.to_ruby.should ==
          "Builtins.b { |a, b, c|\n  @i = 42\n  @j = 43\n  @k = 44\n}"
      end

      it "emits correct code for builtins with arguments and a block" do
        node = Builtin.new(
          :name    => "b",
          :args    => [
            Const.new(:type => :int, :value => "42"),
            Const.new(:type => :int, :value => "43"),
            Const.new(:type => :int, :value => "44")
          ],
          :block => UnspecBlock.new(
            :args       => [
              Symbol.new(
                :global   => false,
                :category => :variable,
                :type     => "integer",
                :name     => "a"
              ),
              Symbol.new(
                :global   => false,
                :category => :variable,
                :type     => "integer",
                :name     => "b"
              ),
              Symbol.new(
                :global   => false,
                :category => :variable,
                :type     => "integer",
                :name     => "c"
              )
            ],
            :symbols    => [],
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
        )

        node.to_ruby.should ==
          "Builtins.b(42, 43, 44) { |a, b, c|\n  @i = 42\n  @j = 43\n  @k = 44\n}"
      end

      it "emits correct code for namespaced builtins" do
        node_scr   = Builtin.new(:name => "SCR::b",   :args => [], :block => nil)
        node_wfm   = Builtin.new(:name => "WFM::b",   :args => [], :block => nil)
        node_float = Builtin.new(:name => "float::b", :args => [], :block => nil)
        node_list  = Builtin.new(:name => "list::b",  :args => [], :block => nil)
        node_none  = Builtin.new(:name => "b",        :args => [], :block => nil)

        node_scr.to_ruby.should   == "SCR.b"
        node_wfm.to_ruby.should   == "WFM.b"
        node_float.to_ruby.should == "Builtins::Float.b"
        node_list.to_ruby.should  == "Builtins::List.b"
        node_none.to_ruby.should  == "Builtins.b"
      end
    end
  end

  describe Call do
    describe "#to_ruby" do
      it "emits correct code for a call without arguments" do
        node = Call.new(:ns => "n", :name => "f", :args => [])

        node.to_ruby.should == "n.f"
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

        node.to_ruby.should == "\"abcd\""
      end

      it "emits correct code for path constants" do
        node = Const.new(:type => :path, :value => ".abcd")

        node.to_ruby.should == "Path.new(\".abcd\")"
      end
    end
  end

  describe Continue do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Continue.new

        node.to_ruby.should == "next"
      end
    end
  end

  describe DefBlock do
    describe "#to_ruby" do
      it "emits correct code" do
        node = DefBlock.new(
          :symbols    => [],
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

        node.to_ruby.should == "@i = 42\n@j = 43\n@k = 44"
      end
    end
  end

  describe Entry do
    describe "#to_ruby" do
      before :each do
        @node_unprefixed_i = Entry.new(:ns => nil, :name => "i")
        @node_unprefixed_j = Entry.new(:ns => nil, :name => "j")
        @node_prefixed_m   = Entry.new(:ns => "M", :name => "i")
        @node_prefixed_n   = Entry.new(:ns => "N", :name => "i")
        @node_capital      = Entry.new(:ns => nil, :name => "I")
        @node_underscore   = Entry.new(:ns => nil, :name => "_i")

        @def_block    = DefBlock.new(
          :symbols => [
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "i"
            )
          ]
        )
        @file_block   = FileBlock.new(:symbols => [])
        @module_block = ModuleBlock.new(:name => "M", :symbols => [])
      end

      describe "at client toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@file_block])

          @node_unprefixed_i.to_ruby(context).should == "i"
          @node_unprefixed_j.to_ruby(context).should == "j"
          @node_prefixed_m.to_ruby(context).should   == "M::i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "_I"
          @node_underscore.to_ruby(context).should   == "__i"
        end
      end

      describe "at module toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@module_block])

          @node_unprefixed_i.to_ruby(context).should == "@i"
          @node_unprefixed_j.to_ruby(context).should == "@j"
          @node_prefixed_m.to_ruby(context).should   == "@i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "@I"
          @node_underscore.to_ruby(context).should   == "@_i"
        end
      end

      describe "inside a function at client toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@file_block, @def_block])

          @node_unprefixed_i.to_ruby(context).should == "i"
          @node_unprefixed_j.to_ruby(context).should == "j"
          @node_prefixed_m.to_ruby(context).should   == "M::i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "_I"
          @node_underscore.to_ruby(context).should   == "__i"
        end
      end

      describe "inside a function at module toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@module_block, @def_block])

          @node_unprefixed_i.to_ruby(context).should == "i"
          @node_unprefixed_j.to_ruby(context).should == "@j"
          @node_prefixed_m.to_ruby(context).should   == "@i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "@I"
          @node_underscore.to_ruby(context).should   == "@_i"
        end
      end
    end
  end

  describe FileBlock do
    describe "#to_ruby" do
      it "emits correct code" do
        node = FileBlock.new(
          :symbols    => [],
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
    end
  end

  describe Filename do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Filename.new

        node.to_ruby.should == ""
      end
    end
  end

  describe FunDef do
    describe "#to_ruby" do
      def fundef_with_args(type)
        FunDef.new(
          :name  => "f",
          :args  => [
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => type,
              :name     => "a"
            ),
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => type,
              :name     => "b"
            ),
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => type,
              :name     => "c"
            )
          ],
          :block => DefBlock.new(
            :symbols    => [],
            :statements => [
              Return.new(:child => Const.new(:type => :int, :value => "42"))
            ]
          )
        )
      end

      it "emits correct code for fundefs without arguments" do
        node = FunDef.new(
          :name  => "f",
          :args  => [],
          :block => DefBlock.new(
            :symbols    => [],
            :statements => [
              Return.new(:child => Const.new(:type => :int, :value => "42"))
            ]
          )
        )

        node.to_ruby.should == "def f\n  return 42\n\n  nil\nend\n"
      end

      it "emits correct code for fundefs with arguments" do
        node_boolean       = fundef_with_args("boolean")
        node_integer       = fundef_with_args("integer")
        node_symbol        = fundef_with_args("symbol")
        node_any           = fundef_with_args("any")
        node_const_boolean = fundef_with_args("const boolean")
        node_const_integer = fundef_with_args("const integer")
        node_const_symbol  = fundef_with_args("const symbol")
        node_const_any     = fundef_with_args("const any")

        code_without_copy = [
          "def f(a, b, c)",
          "  return 42",
          "",
          "  nil",
          "end",
          ""
        ].join("\n")

        code_with_copy = [
          "def f(a, b, c)",
          "  a = YCP.copy(a)",
          "  b = YCP.copy(b)",
          "  c = YCP.copy(c)",
          "  return 42",
          "",
          "  nil",
          "end",
          ""
        ].join("\n")

        node_boolean.to_ruby.should       == code_without_copy
        node_integer.to_ruby.should       == code_without_copy
        node_symbol.to_ruby.should        == code_without_copy
        node_any.to_ruby.should           == code_with_copy
        node_const_boolean.to_ruby.should == code_without_copy
        node_const_integer.to_ruby.should == code_without_copy
        node_const_symbol.to_ruby.should  == code_without_copy
        node_const_any.to_ruby.should     == code_with_copy
      end

      it "raises an exception for nested functions" do
        node = FunDef.new(
          :name  => "f",
          :args  => [],
          :block => DefBlock.new(
            :symbols    => [],
            :statements => [
              Return.new(:child => Const.new(:type => :int, :value => "42"))
            ]
          )
        )

        lambda {
          node.to_ruby(Context.new(:blocks => [FileBlock.new, DefBlock.new]))
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

        node.to_ruby.should == "if true\n  n.f\nend"
      end

      it "emits correct code for ifs with else" do
        node = If.new(
          :cond => Const.new(:type => :bool, :value => "true"),
          :then => Call.new(:ns => "n", :name => "f", :args => []),
          :else => Call.new(:ns => "n", :name => "f", :args => [])
        )

        node.to_ruby.should == "if true\n  n.f\nelse\n  n.f\nend"
      end
    end
  end

  describe Import do
    describe "#to_ruby" do
      it "emits correct code" do
        node_regular = Import.new(:name => "M")
        node_scr     = Import.new(:name => "SCR")
        node_wfm     = Import.new(:name => "WFM")

        node_regular.to_ruby.should == "YCP.import(\"M\")\n"
        node_scr.to_ruby.should     == ""
        node_wfm.to_ruby.should     == ""
      end
    end
  end

  describe Include do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Include.new

        node.to_ruby.should == ""
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

        node.to_ruby.should == "_(\"Translated text.\")"
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

  describe ModuleBlock do
    describe "#to_ruby" do
      it "emits correct code for empty blocks" do
        node = ModuleBlock.new(
          :name       => "M",
          :symbols    => [],
          :statements => []
        )

        node.to_ruby.should == [
          "require \"ycp\"",
          "",
          "module YCP",
          "  class MClass",
          "    extend Exportable",
          "  end",
          "",
          "  M = MClass.new",
          "end"
        ].join("\n")
      end

      it "emits correct code for blocks with symbols" do
        node = ModuleBlock.new(
          :name       => "M",
          :symbols    => [
            Symbol.new(
              :global   => true,
              :category => :variable,
              :type     => "integer",
              :name     => "a"
            ),
            Symbol.new(
              :global   => true,
              :category => :variable,
              :type     => "integer",
              :name     => "b"
            ),
            Symbol.new(
              :global   => true,
              :category => :variable,
              :type     => "integer",
              :name     => "c"
            )
          ],
          :statements => []
        )

        node.to_ruby.should == [
          "require \"ycp\"",
          "",
          "module YCP",
          "  class MClass",
          "    extend Exportable",
          "    publish :variable => :a, :type => \"integer\"",
          "    publish :variable => :b, :type => \"integer\"",
          "    publish :variable => :c, :type => \"integer\"",
          "  end",
          "",
          "  M = MClass.new",
          "end"
        ].join("\n")
      end

      it "emits correct code for blocks with statements" do
        node = ModuleBlock.new(
          :name       => "M",
          :symbols    => [],
          :statements => [
            Textdomain.new(:name => "d"),
            Textdomain.new(:name => "e"),
            Textdomain.new(:name => "f")
          ]
        )

        node.to_ruby.should == [
          "require \"ycp\"",
          "",
          "module YCP",
          "  class MClass",
          "    extend Exportable",
          "",
          "    def initialize",
          "      FastGettext.text_domain = \"d\"",
          "",
          "      FastGettext.text_domain = \"e\"",
          "",
          "      FastGettext.text_domain = \"f\"",
          "",
          "    end",
          "  end",
          "",
          "  M = MClass.new",
          "end"
        ].join("\n")
      end

      it "emits correct code for blocks with function declarations" do
        node = ModuleBlock.new(
          :name       => "M",
          :symbols    => [],
          :statements => [
            FunDef.new(
              :name  => "f",
              :args  => [],
              :block => DefBlock.new(
                :symbols    => [],
                :statements => [
                  Return.new(:child => Const.new(:type => :int, :value => "42"))
                ]
              )
            ),
            FunDef.new(
              :name  => "g",
              :args  => [],
              :block => DefBlock.new(
                :symbols    => [],
                :statements => [
                  Return.new(:child => Const.new(:type => :int, :value => "43"))
                ]
              )
            ),
            FunDef.new(
              :name  => "h",
              :args  => [],
              :block => DefBlock.new(
                :symbols    => [],
                :statements => [
                  Return.new(:child => Const.new(:type => :int, :value => "44"))
                ]
              )
            )
          ]
        )

        node.to_ruby.should == [
          "require \"ycp\"",
          "",
          "module YCP",
          "  class MClass",
          "    extend Exportable",
          "",
          "    def f",
          "      return 42",
          "",
          "      nil",
          "    end",
          "",
          "    def g",
          "      return 43",
          "",
          "      nil",
          "    end",
          "",
          "    def h",
          "      return 44",
          "",
          "      nil",
          "    end",
          "",
          "  end",
          "",
          "  M = MClass.new",
          "end"
        ].join("\n")
      end
    end
  end

  describe Return do
    describe "#to_ruby" do
      before :each do
        @node_without_value = Return.new(:child => nil)
        @node_with_value    = Return.new(
          :child => Const.new(:type => :int, :value => "42")
        )
      end

      describe "at client toplevel" do
        before :each do
          @context = Context.new(:blocks => [FileBlock.new])
        end

        it "raises an exception for a return without a value" do
          lambda {
            @node_without_value.to_ruby(@context)
          }.should raise_error NotImplementedError, "The \"return\" statement at client toplevel is not supported."
        end

        it "raises an exception for a return with a value" do
          lambda {
            @node_with_value.to_ruby(@context)
          }.should raise_error NotImplementedError, "The \"return\" statement at client toplevel is not supported."
        end
      end

      describe "inside a function" do
        before :each do
          @context = Context.new(:blocks => [FileBlock.new, DefBlock.new])
        end

        it "emits correct code for a return without a value" do
          @node_without_value.to_ruby(@context).should == "return"
        end

        it "emits correct code for a return with a value" do
          @node_with_value.to_ruby(@context).should == "return 42"
        end
      end

      describe "inside a function which is inside a block expression" do
        before :each do
          @context = Context.new(:blocks => [FileBlock.new, UnspecBlock.new, DefBlock.new])
        end

        it "emits correct code for a return without a value" do
          @node_without_value.to_ruby(@context).should == "return"
        end

        it "emits correct code for a return with a value" do
          @node_with_value.to_ruby(@context).should == "return 42"
        end
      end

      describe "inside a block expression" do
        before :each do
          @context = Context.new(:blocks => [FileBlock.new, UnspecBlock.new])
        end

        it "emits correct code for a return without a value" do
          @node_without_value.to_ruby(@context).should == "next"
        end

        it "emits correct code for a return with a value" do
          @node_with_value.to_ruby(@context).should == "next 42"
        end
      end

      describe "inside a block expression which is inside a function" do
        before :each do
          @context = Context.new(:blocks => [FileBlock.new, DefBlock.new, UnspecBlock.new])
        end

        it "emits correct code for a return without a value" do
          @node_without_value.to_ruby(@context).should == "next"
        end

        it "emits correct code for a return with a value" do
          @node_with_value.to_ruby(@context).should == "next 42"
        end
      end
    end
  end

  describe StmtBlock do
    describe "#to_ruby" do
      it "emits correct code" do
        node = StmtBlock.new(
          :symbols    => [],
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

        node.to_ruby.should == "@i = 42\n@j = 43\n@k = 44"
      end

      it "raises an exception when encountering a variable alias" do
        symbol = Symbol.new(
          :global   => true,
          :category => :variable,
          :type     => "integer",
          :name     => "a"
        )

        node = StmtBlock.new(
          :symbols    => [symbol],
          :statements => []
        )

        context = Context.new(
          :blocks => [
              DefBlock.new(
              :symbols    => [symbol],
              :statements => []
            )
          ]
        )

        lambda {
          node.to_ruby(context)
        }.should raise_error NotImplementedError, "Variable aliases are not supported."
      end
    end
  end

  describe Symbol do
    describe "#needs_copy?" do
      it "returns false for a boolean" do
        node = Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "boolean",
          :name     => "s"
        )

        node.needs_copy?.should be_false
      end

      it "returns false for an integer" do
        node = Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        node.needs_copy?.should be_false
      end

      it "returns false for a symbol" do
        node = Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "symbol",
          :name     => "s"
        )

        node.needs_copy?.should be_false
      end

      it "returns true for a any" do
        node = Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "any",
          :name     => "s"
        )

        node.needs_copy?.should be_true
      end
    end

    describe "#published?" do
      it "returns true for a global variable" do
        node = Symbol.new(
          :global   => true,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        node.should be_published
      end

      it "returns true for a global function" do
        node = Symbol.new(
          :global   => true,
          :category => :function,
          :type     => "integer ()",
          :name     => "s"
        )

        node.should be_published
      end

      it "returns false for a global filename" do
        node = Symbol.new(
          :global   => true,
          :category => :filename,
          :type     => nil,
          :name     => "s"
        )

        node.should_not be_published
      end

      it "returns false for a non-global variable" do
        node = Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        node.should_not be_published
      end

      it "returns false-true for a global function" do
        node = Symbol.new(
          :global   => false,
          :category => :function,
          :type     => "integer ()",
          :name     => "s"
        )

        node.should_not be_published
      end
    end

    describe "#to_ruby" do
      it "emits correct code" do
        node = Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        node.to_ruby.should == "s"
      end
    end

    describe "#to_ruby_copy_call" do
      it "emits correct code" do
        node = Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        node.to_ruby_copy_call.should == "s = YCP.copy(s)"
      end
    end

    describe "#to_ruby_publish_call" do
      it "emits correct code" do
        node = Symbol.new(
          :global   => true,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        node.to_ruby_publish_call.should ==
          "publish :variable => :s, :type => \"integer\""
      end
    end
  end

  describe Textdomain do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Textdomain.new(:name => "d")

        node.to_ruby.should == "FastGettext.text_domain = \"d\"\n"
      end
    end
  end

  describe UnspecBlock do
    describe "#to_ruby" do
      it "emits correct code" do
        node = UnspecBlock.new(
          :args       => [],
          :symbols    => [],
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

        node.to_ruby.should == "lambda {\n  @i = 42\n  @j = 43\n  @k = 44\n}"
      end

      it "raises an exception when encountering a variable alias" do
        symbol = Symbol.new(
          :global   => true,
          :category => :variable,
          :type     => "integer",
          :name     => "a"
        )

        node = UnspecBlock.new(
          :args       => [],
          :symbols    => [symbol],
          :statements => []
        )

        context = Context.new(
          :blocks => [
              DefBlock.new(
              :symbols    => [symbol],
              :statements => []
            )
          ]
        )

        lambda {
          node.to_ruby(context)
        }.should raise_error NotImplementedError, "Variable aliases are not supported."
      end
    end

    describe "#to_ruby_block" do
      it "emits correct code without arguments" do
        node = UnspecBlock.new(
          :args       => [],
          :symbols    => [],
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

        node.to_ruby_block.should == "{ ||\n  @i = 42\n  @j = 43\n  @k = 44\n}"
      end

      it "emits correct code with arguments" do
        node = UnspecBlock.new(
          :args       => [
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "a"
            ),
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "b"
            ),
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "c"
            )
          ],
          :symbols    => [],
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

        node.to_ruby_block.should ==
          "{ |a, b, c|\n  @i = 42\n  @j = 43\n  @k = 44\n}"
      end

      it "raises an exception when encountering a variable alias" do
        symbol = Symbol.new(
          :global   => true,
          :category => :variable,
          :type     => "integer",
          :name     => "a"
        )

        node = UnspecBlock.new(
          :args       => [],
          :symbols    => [symbol],
          :statements => []
        )

        context = Context.new(
          :blocks => [
              DefBlock.new(
              :symbols    => [symbol],
              :statements => []
            )
          ]
        )

        lambda {
          node.to_ruby_block(context)
        }.should raise_error NotImplementedError, "Variable aliases are not supported."
      end
    end
  end

  describe Variable do
    describe "#to_ruby" do
      before :each do
        @node_unprefixed_i = Variable.new(:name => "i")
        @node_unprefixed_j = Variable.new(:name => "j")
        @node_prefixed_m   = Variable.new(:name => "M::i")
        @node_prefixed_n   = Variable.new(:name => "N::i")
        @node_capital      = Variable.new(:name => "I")
        @node_underscore   = Variable.new(:name => "_i")

        @def_block    = DefBlock.new(
          :symbols => [
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "i"
            )
          ]
        )
        @file_block   = FileBlock.new(:symbols => [])
        @module_block = ModuleBlock.new(:name => "M", :symbols => [])
      end

      describe "at client toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@file_block])

          @node_unprefixed_i.to_ruby(context).should == "i"
          @node_unprefixed_j.to_ruby(context).should == "j"
          @node_prefixed_m.to_ruby(context).should   == "M::i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "_I"
          @node_underscore.to_ruby(context).should   == "__i"
        end
      end

      describe "at module toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@module_block])

          @node_unprefixed_i.to_ruby(context).should == "@i"
          @node_unprefixed_j.to_ruby(context).should == "@j"
          @node_prefixed_m.to_ruby(context).should   == "@i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "@I"
          @node_underscore.to_ruby(context).should   == "@_i"
        end
      end

      describe "inside a function at client toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@file_block, @def_block])

          @node_unprefixed_i.to_ruby(context).should == "i"
          @node_unprefixed_j.to_ruby(context).should == "j"
          @node_prefixed_m.to_ruby(context).should   == "M::i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "_I"
          @node_underscore.to_ruby(context).should   == "__i"
        end
      end

      describe "inside a function at module toplevel" do
        it "emits correct code" do
          context = Context.new(:blocks => [@module_block, @def_block])

          @node_unprefixed_i.to_ruby(context).should == "i"
          @node_unprefixed_j.to_ruby(context).should == "@j"
          @node_prefixed_m.to_ruby(context).should   == "@i"
          @node_prefixed_n.to_ruby(context).should   == "N::i"
          @node_capital.to_ruby(context).should      == "@I"
          @node_underscore.to_ruby(context).should   == "@_i"
        end
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

        node.to_ruby.should == "while true\n  n.f\nend"
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

  describe YEIs do
    describe "#to_ruby" do
      it "emits correct code" do
        node = YEIs.new(
          :child => Const.new(:type => :int, :value => "42"),
          :type  => "integer"
        )

        node.to_ruby.should == "Ops.is(42, \"integer\")"
      end
    end
  end

  describe YEPropagate do
    describe "#to_ruby" do
      it "emits correct code when the types are the same" do
        node_no_const = YEPropagate.new(
          :from  => "integer",
          :to    => "integer",
          :child => Const.new(:type => :int, :value => "42")
        )
        node_both_const = YEPropagate.new(
          :from  => "const integer",
          :to    => "const integer",
          :child => Const.new(:type => :int, :value => "42")
        )

        node_no_const.to_ruby.should   == "42"
        node_both_const.to_ruby.should == "42"
      end

      it "emits correct code when the types are the same but their constness is different" do
        node_from_const = YEPropagate.new(
          :from  => "const integer",
          :to    => "integer",
          :child => Const.new(:type => :int, :value => "42")
        )
        node_to_const = YEPropagate.new(
          :from  => "integer",
          :to    => "const integer",
          :child => Const.new(:type => :int, :value => "42")
        )

        node_from_const.to_ruby.should == "42"
        node_to_const.to_ruby.should   == "42"
      end

      it "emits correct code when the types are different" do
        node_no_const = YEPropagate.new(
          :from  => "integer",
          :to    => "float",
          :child => Const.new(:type => :int, :value => "42")
        )
        node_both_const = YEPropagate.new(
          :from  => "const integer",
          :to    => "const float",
          :child => Const.new(:type => :int, :value => "42")
        )

        node_no_const.to_ruby.should ==
          "Convert.convert(42, :from => \"integer\", :to => \"float\")"
        node_both_const.to_ruby.should ==
          "Convert.convert(42, :from => \"integer\", :to => \"float\")"
      end

      it "emits correct code when both the types and their constness are different" do
        node_from_const = YEPropagate.new(
          :from  => "const integer",
          :to    => "float",
          :child => Const.new(:type => :int, :value => "42")
        )
        node_to_const = YEPropagate.new(
          :from  => "integer",
          :to    => "const float",
          :child => Const.new(:type => :int, :value => "42")
        )

        node_from_const.to_ruby.should ==
          "Convert.convert(42, :from => \"integer\", :to => \"float\")"
        node_to_const.to_ruby.should ==
          "Convert.convert(42, :from => \"integer\", :to => \"float\")"
      end
    end
  end

  describe YEReturn do
    describe "#to_ruby" do
      it "emits correct code" do
        node = YEReturn.new(
          :args    => [],
          :symbols => [],
          :child   => Const.new(:type => :int, :value => "42")
        )

        node.to_ruby.should == "lambda { 42 }"
      end
    end

    describe "#to_ruby_block" do
      it "emits correct code without arguments" do
        node = YEReturn.new(
          :args    => [],
          :symbols => [],
          :child   => Const.new(:type => :int, :value => "42")
        )

        node.to_ruby_block.should == "{ || 42 }"
      end

      it "emits correct code with arguments" do
        node = YEReturn.new(
          :args    => [
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "a"
            ),
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "b"
            ),
            Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "c"
            )
          ],
          :symbols => [],
          :child   => Const.new(:type => :int, :value => "42")
        )

        node.to_ruby_block.should == "{ |a, b, c| 42 }"
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
