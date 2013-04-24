require "spec_helper"

module Y2R::AST
  RSpec.configure do |c|
    c.before :each, :type => :ycp do
      # ----- YCP AST Nodes -----

      @ycp_true = YCP::Const.new(:type => :bool, :value => "true")

      @ycp_const_a = YCP::Const.new(:type => :symbol, :value => "a")
      @ycp_const_b = YCP::Const.new(:type => :symbol, :value => "b")
      @ycp_const_c = YCP::Const.new(:type => :symbol, :value => "c")

      @ycp_const_0  = YCP::Const.new(:type => :int, :value => "0")
      @ycp_const_1  = YCP::Const.new(:type => :int, :value => "1")
      @ycp_const_42 = YCP::Const.new(:type => :int, :value => "42")
      @ycp_const_43 = YCP::Const.new(:type => :int, :value => "43")
      @ycp_const_44 = YCP::Const.new(:type => :int, :value => "44")

      @ycp_assign_a_42 = YCP::Assign.new(:name  => "a", :child => @ycp_const_42)
      @ycp_assign_b_43 = YCP::Assign.new(:name  => "b", :child => @ycp_const_43)
      @ycp_assign_c_44 = YCP::Assign.new(:name  => "c", :child => @ycp_const_44)

      @ycp_textdomain_d = YCP::Textdomain.new(:name => "d")
      @ycp_textdomain_e = YCP::Textdomain.new(:name => "e")
      @ycp_textdomain_f = YCP::Textdomain.new(:name => "f")

      @ycp_statements = [@ycp_assign_a_42, @ycp_assign_b_43, @ycp_assign_c_44]

      @ycp_symbol_private_a = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "a"
      )
      @ycp_symbol_private_b = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "b"
      )
      @ycp_symbol_private_c = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "c"
      )

      @ycp_symbols_private = [
        @ycp_symbol_private_a,
        @ycp_symbol_private_b,
        @ycp_symbol_private_c
      ]

      @ycp_symbol_public_a = YCP::Symbol.new(
        :global   => true,
        :category => :variable,
        :type     => "integer",
        :name     => "a"
      )
      @ycp_symbol_public_b = YCP::Symbol.new(
        :global   => true,
        :category => :variable,
        :type     => "integer",
        :name     => "b"
      )
      @ycp_symbol_public_c = YCP::Symbol.new(
        :global   => true,
        :category => :variable,
        :type     => "integer",
        :name     => "c"
      )

      @ycp_symbols_public = [
        @ycp_symbol_public_a,
        @ycp_symbol_public_b,
        @ycp_symbol_public_c
      ]

      @ycp_symbol_var_regular = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "a"
      )
      @ycp_symbol_var_capital = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "A"
      )
      @ycp_symbol_var_underscore = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "_a"
      )
      @ycp_symbol_var_reserved = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "end"
      )

      @symbols_var = [
        @ycp_symbol_var_regular,
        @ycp_symbol_var_capital,
        @ycp_symbol_var_underscore,
        @ycp_symbol_var_reserved
      ]

      @ycp_symbol_fun_regular = YCP::Symbol.new(
        :global   => false,
        :category => :function,
        :type     => "integer ()",
        :name     => "f"
      )
      @ycp_symbol_fun_capital = YCP::Symbol.new(
        :global   => false,
        :category => :function,
        :type     => "integer ()",
        :name     => "F"
      )
      @ycp_symbol_fun_underscore = YCP::Symbol.new(
        :global   => false,
        :category => :function,
        :type     => "integer ()",
        :name     => "_f"
      )
      @ycp_symbol_fun_reserved = YCP::Symbol.new(
        :global   => false,
        :category => :function,
        :type     => "integer ()",
        :name     => "end"
      )

      @symbols_fun = [
        @ycp_symbol_fun_regular,
        @ycp_symbol_fun_capital,
        @ycp_symbol_fun_underscore,
        @ycp_symbol_fun_reserved
      ]

      @ycp_stmt_block = YCP::StmtBlock.new(
        :symbols    => [],
        :statements => @ycp_statements
      )
      @ycp_stmt_block_break = YCP::StmtBlock.new(
        :symbols    => [],
        :statements => [
          @ycp_assign_a_42,
          @ycp_assign_b_43,
          @ycp_assign_c_44,
          YCP::Break.new
        ]
      )
      @ycp_stmt_block_return = YCP::StmtBlock.new(
        :symbols    => [],
        :statements => [
          @ycp_assign_a_42,
          @ycp_assign_b_43,
          @ycp_assign_c_44,
          YCP::Return.new(:child => nil)
        ]
      )
      @ycp_def_block = YCP::DefBlock.new(
        :symbols    => [],
        :statements => @ycp_statements
      )

      @ycp_case_42 = YCP::Case.new(
        :values => [@ycp_const_42],
        :body   => @ycp_stmt_block_break
      )
      @ycp_case_43 = YCP::Case.new(
        :values => [@ycp_const_43],
        :body   => @ycp_stmt_block_break
      )
      @ycp_case_44 = YCP::Case.new(
        :values => [@ycp_const_44],
        :body   => @ycp_stmt_block_break
      )

      @ycp_default = YCP::Default.new(:body => @ycp_stmt_block)

      @ycp_fundef_f = ycp_node = YCP::FunDef.new(
        :name  => "f",
        :args  => [],
        :block => @ycp_def_block
      )
      @ycp_fundef_g = ycp_node = YCP::FunDef.new(
        :name  => "g",
        :args  => [],
        :block => @ycp_def_block
      )
      @ycp_fundef_h = ycp_node = YCP::FunDef.new(
        :name  => "h",
        :args  => [],
        :block => @ycp_def_block
      )

      # ----- Ruby AST Nodes -----

      @ruby_literal_nil = Ruby::Literal.new(:value => nil)

      @ruby_literal_true = Ruby::Literal.new(:value => true)

      @ruby_literal_a = Ruby::Literal.new(:value => :a)
      @ruby_literal_b = Ruby::Literal.new(:value => :b)
      @ruby_literal_c = Ruby::Literal.new(:value => :c)

      @ruby_literal_0  = Ruby::Literal.new(:value => 0)
      @ruby_literal_1  = Ruby::Literal.new(:value => 1)
      @ruby_literal_42 = Ruby::Literal.new(:value => 42)
      @ruby_literal_43 = Ruby::Literal.new(:value => 43)
      @ruby_literal_44 = Ruby::Literal.new(:value => 44)

      @ruby_variable_a = Ruby::Variable.new(:name => "@a")
      @ruby_variable_b = Ruby::Variable.new(:name => "@b")
      @ruby_variable_c = Ruby::Variable.new(:name => "@c")

      @ruby_assignment_a_42 = Ruby::Assignment.new(
        :lhs => @ruby_variable_a,
        :rhs => @ruby_literal_42
      )
      @ruby_assignment_b_43 = Ruby::Assignment.new(
        :lhs => @ruby_variable_b,
        :rhs => @ruby_literal_43
      )
      @ruby_assignment_c_44 = Ruby::Assignment.new(
        :lhs => @ruby_variable_c,
        :rhs => @ruby_literal_44
      )

      @ruby_textdomain_d = Ruby::Statements.new(
        :statements => [
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "include",
            :args     => [Ruby::Variable.new(:name => "I18n")],
            :block    => nil,
            :parens   => false
          ),
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "textdomain",
            :args     => [Ruby::Literal.new(:value => "d")],
            :block    => nil,
            :parens   => false
          )
        ]
      )
      @ruby_textdomain_e = Ruby::Statements.new(
        :statements => [
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "include",
            :args     => [Ruby::Variable.new(:name => "I18n")],
            :block    => nil,
            :parens   => false
          ),
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "textdomain",
            :args     => [Ruby::Literal.new(:value => "e")],
            :block    => nil,
            :parens   => false
          )
        ]
      )
      @ruby_textdomain_f = Ruby::Statements.new(
        :statements => [
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "include",
            :args     => [Ruby::Variable.new(:name => "I18n")],
            :block    => nil,
            :parens   => false
          ),
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "textdomain",
            :args     => [Ruby::Literal.new(:value => "f")],
            :block    => nil,
            :parens   => false
          )
        ]
      )

      @ruby_statements_empty            = Ruby::Statements.new(
        :statements => []
      )
      @ruby_statements_non_empty        = Ruby::Statements.new(
        :statements => [
          @ruby_assignment_a_42,
          @ruby_assignment_b_43,
          @ruby_assignment_c_44
        ]
      )
      @ruby_statements_non_empty_return = Ruby::Statements.new(
        :statements => [
          @ruby_assignment_a_42,
          @ruby_assignment_b_43,
          @ruby_assignment_c_44,
          Ruby::Return.new(:value => nil)
        ]
      )

      @ruby_when_42 = Ruby::When.new(
        :values => [@ruby_literal_42],
        :body   => @ruby_statements_non_empty
      )
      @ruby_when_43 = Ruby::When.new(
        :values => [@ruby_literal_43],
        :body   => @ruby_statements_non_empty
      )
      @ruby_when_44 = Ruby::When.new(
        :values => [@ruby_literal_44],
        :body   => @ruby_statements_non_empty
      )

      @ruby_else = Ruby::Else.new(:body => @ruby_statements_non_empty)

      @ruby_arg_a = Ruby::Arg.new(:name => "a", :default => nil)
      @ruby_arg_b = Ruby::Arg.new(:name => "b", :default => nil)
      @ruby_arg_c = Ruby::Arg.new(:name => "c", :default => nil)

      @ruby_def_f = Ruby::Def.new(
        :name => "f",
        :args => [],
        :statements => Ruby::Statements.new(
          :statements => [
            @ruby_assignment_a_42,
            @ruby_assignment_b_43,
            @ruby_assignment_c_44,
            @ruby_literal_nil
          ]
        )
      )
      @ruby_def_g = Ruby::Def.new(
        :name => "g",
        :args => [],
        :statements => Ruby::Statements.new(
          :statements => [
            @ruby_assignment_a_42,
            @ruby_assignment_b_43,
            @ruby_assignment_c_44,
            @ruby_literal_nil
          ]
        )
      )
      @ruby_def_h = Ruby::Def.new(
        :name => "h",
        :args => [],
        :statements => Ruby::Statements.new(
          :statements => [
            @ruby_assignment_a_42,
            @ruby_assignment_b_43,
            @ruby_assignment_c_44,
            @ruby_literal_nil
          ]
        )
      )

      # ----- Contexts -----

      # Note we use non-filled AST nodes for :blocks. This doesn't cause any
      # harm as the compiler code only looks at the node class, not its data.

      @context_empty = YCP::Context.new

      @context_while           = YCP::Context.new(:blocks => [YCP::While.new])
      @context_while_in_unspec = YCP::Context.new(
        :blocks => [YCP::UnspecBlock.new, YCP::While.new]
      )

      @context_do               = YCP::Context.new(:blocks => [YCP::Do.new])
      @context_do_in_unspec     = YCP::Context.new(
        :blocks => [YCP::UnspecBlock.new, YCP::Do.new]
      )
      @context_repeat           = YCP::Context.new(:blocks => [YCP::Repeat.new])
      @context_repeat_in_unspec = YCP::Context.new(
        :blocks => [YCP::UnspecBlock.new, YCP::Repeat.new]
      )

      @context_unspec           = YCP::Context.new(
        :blocks => [YCP::UnspecBlock.new]
      )
      @context_unspec_in_while  = YCP::Context.new(
        :blocks => [YCP::While.new, YCP::UnspecBlock.new]
      )
      @context_unspec_in_do = YCP::Context.new(
        :blocks => [YCP::Do.new, YCP::UnspecBlock.new]
      )
      @context_unspec_in_repeat = YCP::Context.new(
        :blocks => [YCP::Repeat.new, YCP::UnspecBlock.new]
      )
      @context_unspec_in_file = YCP::Context.new(
        :blocks => [YCP::FileBlock.new, YCP::UnspecBlock.new]
      )
      @context_unspec_in_def = YCP::Context.new(
        :blocks => [YCP::DefBlock.new, YCP::UnspecBlock.new]
      )

      @context_def           = YCP::Context.new(
        :blocks => [YCP::DefBlock.new]
      )
      @context_def_in_file = YCP::Context.new(
        :blocks => [YCP::FileBlock.new, YCP::DefBlock.new]
      )
      @context_def_in_unspec = YCP::Context.new(
        :blocks => [YCP::UnspecBlock.new, YCP::DefBlock.new]
      )

      # The following contexts are used in context-sensitive variable name
      # handling tests, so we fill-in at least some data needed by them.

      @context_module = YCP::Context.new(
        :blocks => [YCP::ModuleBlock.new(:name => "M")]
      )
      @context_global = YCP::Context.new(
        :blocks => [YCP::FileBlock.new(:symbols => @symbols_var)]
      )
      @context_local_global_vars = YCP::Context.new(
        :blocks => [
          YCP::FileBlock.new(:symbols => @symbols_var),
          YCP::DefBlock.new(:symbols => [])
        ]
      )
      @context_local_local_vars = YCP::Context.new(
        :blocks => [
          YCP::FileBlock.new(:symbols => []),
          YCP::DefBlock.new(:symbols => @symbols_var)
        ]
      )
      @context_local_local_funs = YCP::Context.new(
        :blocks => [
          YCP::FileBlock.new(:symbols => []),
          YCP::DefBlock.new(:symbols => @symbols_fun)
        ]
      )
      @context_local_nested_vars = YCP::Context.new(
        :blocks => [
          YCP::FileBlock.new(:symbols => []),
          YCP::DefBlock.new(:symbols => @symbols_var),
          YCP::DefBlock.new(:symbols => @symbols_var)
        ]
      )
      @context_local_nested_funs = YCP::Context.new(
        :blocks => [
          YCP::FileBlock.new(:symbols => []),
          YCP::DefBlock.new(:symbols => @symbols_fun),
          YCP::DefBlock.new(:symbols => @symbols_fun)
        ]
      )
    end
  end

  describe YCP::Assign, :type => :ycp do
    describe "#compile" do
      describe "for qualified assignments" do
        it "returns correct AST node" do
          ycp_node_m = YCP::Assign.new(:name => "M::a", :child => @ycp_const_42)
          ycp_node_n = YCP::Assign.new(:name => "N::a", :child => @ycp_const_42)

          ruby_node_m = Ruby::Assignment.new(
            :lhs => Ruby::Variable.new(:name => "@a"),
            :rhs => @ruby_literal_42
          )
          ruby_node_n = Ruby::Assignment.new(
            :lhs => Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "N"),
              :name     => "a",
              :args     => [],
              :block    => nil,
              :parens   => true
            ),
            :rhs => @ruby_literal_42
          )

          ycp_node_m.compile(@context_module).should == ruby_node_m
          ycp_node_n.compile(@context_module).should == ruby_node_n
        end
      end

      describe "for unqualified assignments" do
        def ruby_assignment(name)
          Ruby::Assignment.new(
            :lhs => Ruby::Variable.new(:name => name),
            :rhs => @ruby_literal_42
          )
        end

        before :each do
          @ycp_node_regular    = YCP::Assign.new(
            :name  => "a",
            :child => @ycp_const_42
          )
          @ycp_node_capital    = YCP::Assign.new(
            :name  => "A",
            :child => @ycp_const_42
          )
          @ycp_node_underscore = YCP::Assign.new(
            :name  => "_a",
            :child => @ycp_const_42
          )
          @ycp_node_reserved   = YCP::Assign.new(
            :name  => "end",
            :child => @ycp_const_42
          )
        end

        describe "in global context that assign to global variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_assignment("@a")
            ruby_node_capital    = ruby_assignment("@A")
            ruby_node_underscore = ruby_assignment("@_a")
            ruby_node_reserved   = ruby_assignment("@end")

            @ycp_node_regular.compile(@context_global).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_global).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_global).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_global).should ==
              ruby_node_reserved
          end
        end

        describe "in local context that assign to global variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_assignment("@a")
            ruby_node_capital    = ruby_assignment("@A")
            ruby_node_underscore = ruby_assignment("@_a")
            ruby_node_reserved   = ruby_assignment("@end")

            @ycp_node_regular.compile(@context_local_global_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_global_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_global_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_global_vars).should ==
              ruby_node_reserved
          end
        end

        describe "in local context that assign to local variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_assignment("a")
            ruby_node_capital    = ruby_assignment("_A")
            ruby_node_underscore = ruby_assignment("__a")
            ruby_node_reserved   = ruby_assignment("_end")

            @ycp_node_regular.compile(@context_local_local_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_local_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_local_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_local_vars).should ==
              ruby_node_reserved
          end
        end

        describe "in nested local context that assign to inner variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_assignment("a2")
            ruby_node_capital    = ruby_assignment("_A2")
            ruby_node_underscore = ruby_assignment("__a2")
            ruby_node_reserved   = ruby_assignment("end2")

            @ycp_node_regular.compile(@context_local_nested_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_nested_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_nested_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_nested_vars).should ==
              ruby_node_reserved
          end
        end
      end
    end
  end

  describe YCP::Bracket, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::Bracket.new(
          :entry => YCP::Variable.new(:category => "variable", :name => "l"),
          :arg   => YCP::List.new(:children => [@ycp_const_1]),
          :rhs   => @ycp_const_0
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Ops"),
          :name     => "assign",
          :args     => [
            Ruby::Variable.new(:name => "@l"),
            Ruby::Array.new(:elements => [@ruby_literal_1]),
            @ruby_literal_0,
          ],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Break, :type => :ycp do
    describe "#compile" do
      before :each do
        @ycp_node = YCP::Break.new

        @ruby_node_break = Ruby::Break.new
        @ruby_node_raise = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "raise",
          :args     => [Ruby::Variable.new(:name => "Break")],
          :block    => nil,
          :parens   => false
        )
      end

      describe "for break statements inside a while statement" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_while).should == @ruby_node_break
        end
      end

      describe "for break statements inside a do statement" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_do).should == @ruby_node_break
        end
      end

      describe "for break statements inside a repeat statement" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_repeat).should == @ruby_node_break
        end
      end

      describe "for break statements inside a while statement which is inside a block expression" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_while_in_unspec).should == @ruby_node_break
        end
      end

      describe "for break statements inside a do statement which is inside a block expression" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_do_in_unspec).should ==
            @ruby_node_break
        end
      end

      describe "for break statements inside a repeat statement which is inside a block expression" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_repeat_in_unspec).should ==
            @ruby_node_break
        end
      end

      describe "for break statements inside a block expression" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_unspec).should == @ruby_node_raise
        end
      end

      describe "for break statements inside a block expression which is inside a while statement" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_unspec_in_while).should == @ruby_node_raise
        end
      end

      describe "for break statements inside a block expression which is inside a do statement" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_unspec_in_do).should == @ruby_node_raise
        end
      end

      describe "for break statements inside a block expression which is inside a repeat statement" do
        it "returns correct AST node" do
          @ycp_node.compile(@context_unspec_in_repeat).should == @ruby_node_raise
        end
      end
    end
  end

  describe YCP::Builtin, :type => :ycp do
    describe "#compile" do
      def ycp_builtin(name)
        YCP::Builtin.new(:name => name, :args => [], :block => nil)
      end

      def ruby_builtin_call(module_name, method_name)
        Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => module_name),
          :name     => method_name,
          :args     => [],
          :block    => nil,
          :parens   => true
        )
      end

      it "returns correct AST node for builtins with no arguments and no block" do
        ycp_node = YCP::Builtin.new(:name  => "b", :args => [], :block => nil)

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Builtins"),
          :name     => "b",
          :args     => [],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for builtins with arguments and no block" do
        ycp_node = YCP::Builtin.new(
          :name    => "b",
          :args    => [@ycp_const_42, @ycp_const_43, @ycp_const_44],
          :block   => nil
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Builtins"),
          :name     => "b",
          :args     => [@ruby_literal_42, @ruby_literal_43, @ruby_literal_44],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for builtins with no arguments and a block" do
        ycp_node = YCP::Builtin.new(
          :name  => "b",
          :args  => [],
          :block =>  YCP::UnspecBlock.new(
            :args       => @ycp_symbols_private,
            :symbols    => [],
            :statements => @ycp_statements
          )
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Builtins"),
          :name     => "b",
          :args     => [],
          :block    => Ruby::Block.new(
            :args       => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
            :statements => @ruby_statements_non_empty
          ),
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for builtins with arguments and a block" do
        ycp_node = YCP::Builtin.new(
          :name  => "b",
          :args  => [@ycp_const_42, @ycp_const_43, @ycp_const_44],
          :block =>  YCP::UnspecBlock.new(
            :args       => @ycp_symbols_private,
            :symbols    => [],
            :statements => @ycp_statements
          )
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Builtins"),
          :name     => "b",
          :args     => [@ruby_literal_42, @ruby_literal_43, @ruby_literal_44],
          :block    => Ruby::Block.new(
            :args       => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
            :statements => @ruby_statements_non_empty
          ),
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for namespaced builtins" do
        ycp_node_scr   = ycp_builtin("SCR::b")
        ycp_node_wfm   = ycp_builtin("WFM::b")
        ycp_node_float = ycp_builtin("float::b")
        ycp_node_list  = ycp_builtin("list::b")
        ycp_node_none  = ycp_builtin("b")

        ruby_node_scr   = ruby_builtin_call("SCR", "b")
        ruby_node_wfm   = ruby_builtin_call("WFM", "b")
        ruby_node_float = ruby_builtin_call("Builtins::Float", "b")
        ruby_node_list  = ruby_builtin_call("Builtins::List", "b")
        ruby_node_none  = ruby_builtin_call("Builtins", "b")

        ycp_node_scr.compile(@context_empty).should   == ruby_node_scr
        ycp_node_wfm.compile(@context_empty).should   == ruby_node_wfm
        ycp_node_float.compile(@context_empty).should == ruby_node_float
        ycp_node_list.compile(@context_empty).should  == ruby_node_list
        ycp_node_none.compile(@context_empty).should  == ruby_node_none
      end
    end
  end

  describe YCP::Call, :type => :ycp do
    describe "#compile" do
      describe "for calls of toplevel functions with category == \"function\"" do
        it "returns correct AST node for unqualified calls" do
          ycp_node = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "f",
            :args     => []
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "f",
            :args     => [],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end

        it "returns correct AST node for qualified calls" do
          ycp_node = YCP::Call.new(
            :category => "function",
            :ns       => "N",
            :name     => "f",
            :args     => []
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "N"),
            :name     => "f",
            :args     => [],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end

        it "returns correct AST node for calls without arguments" do
          ycp_node = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "f",
            :args     => []
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "f",
            :args     => [],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end

        it "returns correct AST node for calls with arguments" do
          ycp_node = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "f",
            :args     => [@ycp_const_42, @ycp_const_43, @ycp_const_44]
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "f",
            :args     => [@ruby_literal_42, @ruby_literal_43, @ruby_literal_44],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end
      end

      describe "for calls of nested functions with category == \"function\"" do
        def ruby_method_call(name)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => name),
            :name     => "call",
            :args     => [],
            :block    => nil,
            :parens   => true
          )
        end

        before :each do
          @ycp_node_regular    = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "f",
            :args     => []
          )
          @ycp_node_capital    = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "F",
            :args     => []
          )
          @ycp_node_underscore = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "_f",
            :args     => []
          )
          @ycp_node_reserved   = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "end",
            :args     => []
          )
        end

        describe "in local context that refer to local functions" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_method_call("f")
            ruby_node_capital    = ruby_method_call("_F")
            ruby_node_underscore = ruby_method_call("__f")
            ruby_node_reserved   = ruby_method_call("_end")

            @ycp_node_regular.compile(@context_local_local_funs).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_local_funs).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_local_funs).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_local_funs).should ==
              ruby_node_reserved
          end
        end

        describe "in nested local context that refer to inner functions" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_method_call("f2")
            ruby_node_capital    = ruby_method_call("_F2")
            ruby_node_underscore = ruby_method_call("__f2")
            ruby_node_reserved   = ruby_method_call("end2")

            @ycp_node_regular.compile(@context_local_nested_funs).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_nested_funs).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_nested_funs).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_nested_funs).should ==
              ruby_node_reserved
          end
        end

        it "returns correct AST node for calls without arguments" do
          ycp_node = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "f",
            :args     => []
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "f"),
            :name     => "call",
            :args     => [],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_local_local_funs).should == ruby_node
        end

        it "returns correct AST node for calls with arguments" do
          ycp_node = YCP::Call.new(
            :category => "function",
            :ns       => nil,
            :name     => "f",
            :args     => [@ycp_const_42, @ycp_const_43, @ycp_const_44]
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "f"),
            :name     => "call",
            :args     => [@ruby_literal_42, @ruby_literal_43, @ruby_literal_44],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_local_local_funs).should == ruby_node
        end
      end

      describe "for calls with category == \"variable\"" do
        describe "that are qualified" do
          it "returns correct AST node" do
            ycp_node_m = YCP::Entry.new(:ns => "M", :name => "a")
            ycp_node_n = YCP::Entry.new(:ns => "N", :name => "a")

            ruby_node_m = Ruby::Variable.new(:name => "@a")
            ruby_node_n = Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "N"),
              :name     => "a",
              :args     => [],
              :block    => nil,
              :parens   => true
            )

            ycp_node_m.compile(@context_module).should == ruby_node_m
            ycp_node_n.compile(@context_module).should == ruby_node_n
          end
        end

        describe "that are unqualified" do
          def ruby_method_call(name)
            Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => name),
              :name     => "call",
              :args     => [],
              :block    => nil,
              :parens   => true
            )
          end

          before :each do
            @ycp_node_regular    = YCP::Call.new(
              :category => "variable",
              :ns       => nil,
              :name     => "a",
              :args     => []
            )
            @ycp_node_capital    = YCP::Call.new(
              :category => "variable",
              :ns       => nil,
              :name     => "A",
              :args     => []
            )
            @ycp_node_underscore = YCP::Call.new(
              :category => "variable",
              :ns       => nil,
              :name     => "_a",
              :args     => []
            )
            @ycp_node_reserved   = YCP::Call.new(
              :category => "variable",
              :ns       => nil,
              :name     => "end",
              :args     => []
            )
          end

          describe "in global context that refer to global variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_method_call("@a")
              ruby_node_capital    = ruby_method_call("@A")
              ruby_node_underscore = ruby_method_call("@_a")
              ruby_node_reserved   = ruby_method_call("@end")

              @ycp_node_regular.compile(@context_global).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_global).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_global).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_global).should ==
                ruby_node_reserved
            end
          end

          describe "in local context that refer to global variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_method_call("@a")
              ruby_node_capital    = ruby_method_call("@A")
              ruby_node_underscore = ruby_method_call("@_a")
              ruby_node_reserved   = ruby_method_call("@end")

              @ycp_node_regular.compile(@context_local_global_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_global_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_global_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_global_vars).should ==
                ruby_node_reserved
            end
          end

          describe "in local context that refer to local variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_method_call("a")
              ruby_node_capital    = ruby_method_call("_A")
              ruby_node_underscore = ruby_method_call("__a")
              ruby_node_reserved   = ruby_method_call("_end")

              @ycp_node_regular.compile(@context_local_local_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_local_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_local_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_local_vars).should ==
                ruby_node_reserved
            end
          end

          describe "in nested local context that refer to inner variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_method_call("a2")
              ruby_node_capital    = ruby_method_call("_A2")
              ruby_node_underscore = ruby_method_call("__a2")
              ruby_node_reserved   = ruby_method_call("end2")

              @ycp_node_regular.compile(@context_local_nested_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_nested_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_nested_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_nested_vars).should ==
                ruby_node_reserved
            end
          end
        end

        it "returns correct AST node for calls without arguments" do
          ycp_node = YCP::Call.new(
            :category => "variable",
            :ns       => nil,
            :name     => "f",
            :args     => []
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "@f"),
            :name     => "call",
            :args     => [],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end

        it "returns correct AST node for calls with arguments" do
          ycp_node = YCP::Call.new(
            :category => "variable",
            :ns       => nil,
            :name     => "f",
            :args     => [@ycp_const_42, @ycp_const_43, @ycp_const_44]
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "@f"),
            :name     => "call",
            :args     => [@ruby_literal_42, @ruby_literal_43, @ruby_literal_44],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end
      end
    end
  end

  describe YCP::Case, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node for cases with one value" do
        ycp_node = YCP::Case.new(
          :values => [@ycp_const_42],
          :body   => @ycp_stmt_block_break
        )

        ruby_node = Ruby::When.new(
          :values => [@ruby_literal_42],
          :body   => @ruby_statements_non_empty
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for cases with multiple values" do
        ycp_node = YCP::Case.new(
          :values => [@ycp_const_42, @ycp_const_43, @ycp_const_44],
          :body   => @ycp_stmt_block_break
        )

        ruby_node = Ruby::When.new(
          :values => [@ruby_literal_42, @ruby_literal_43, @ruby_literal_44],
          :body   => @ruby_statements_non_empty
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "removes a break statement from the end" do
        ycp_node = YCP::Case.new(
          :values => [@ycp_const_42],
          :body   => @ycp_stmt_block_break
        )

        ruby_node = Ruby::When.new(
          :values => [@ruby_literal_42],
          :body   => @ruby_statements_non_empty
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "does not remove a return statement from the end" do
        ycp_node = YCP::Case.new(
          :values => [@ycp_const_42],
          :body   => @ycp_stmt_block_return
        )

        ruby_node = Ruby::When.new(
          :values => [@ruby_literal_42],
          :body   => @ruby_statements_non_empty_return
        )

        ycp_node.compile(@context_local_global_vars).should == ruby_node
      end

      it "raises an exception for cases wihtout break or return" do
        ycp_node = YCP::Case.new(
          :values => [@ycp_const_42],
          :body   => @ycp_stmt_block
        )

        lambda {
          ycp_node.compile(@context_empty)
        }.should raise_error NotImplementedError, "Case without a break or return encountered. These are not supported."
      end
    end
  end

  describe YCP::Compare, :type => :ycp do
    describe "#compile" do
      def ycp_compare(op)
        YCP::Compare.new(
          :op  => op,
          :lhs => @ycp_const_42,
          :rhs => @ycp_const_43
        )
      end

      def ruby_ops_call(name)
        Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Ops"),
          :name     => name,
          :args     => [@ruby_literal_42, @ruby_literal_43],
          :block    => nil,
          :parens   => true
        )
      end

      it "returns correct AST node" do
        ycp_node_equal            = ycp_compare("==")
        ycp_node_not_equal        = ycp_compare("!=")
        ycp_node_less_than        = ycp_compare("<")
        ycp_node_greater_than     = ycp_compare(">")
        ycp_node_less_or_equal    = ycp_compare("<=")
        ycp_node_greater_or_equal = ycp_compare(">=")

        ruby_node_equal            = ruby_ops_call("equal")
        ruby_node_not_equal        = ruby_ops_call("not_equal")
        ruby_node_less_than        = ruby_ops_call("less_than")
        ruby_node_greater_than     = ruby_ops_call("greater_than")
        ruby_node_less_or_equal    = ruby_ops_call("less_or_equal")
        ruby_node_greater_or_equal = ruby_ops_call("greater_or_equal")

        ycp_node_equal.compile(@context_empty).should ==
          ruby_node_equal
        ycp_node_not_equal.compile(@context_empty).should ==
          ruby_node_not_equal
        ycp_node_less_than.compile(@context_empty).should ==
          ruby_node_less_than
        ycp_node_greater_than.compile(@context_empty).should ==
          ruby_node_greater_than
        ycp_node_less_or_equal.compile(@context_empty).should ==
          ruby_node_less_or_equal
        ycp_node_greater_or_equal.compile(@context_empty).should ==
          ruby_node_greater_or_equal
      end
    end
  end

  describe YCP::Const, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node for void constants" do
        ycp_node  = YCP::Const.new(:type => :void)

        ruby_node = @ruby_literal_nil

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for boolean constants" do
        ycp_node_true   = YCP::Const.new(:type => :bool, :value => "true")
        ycp_node_false  = YCP::Const.new(:type => :bool, :value => "false")

        ruby_node_true  = Ruby::Literal.new(:value => true)
        ruby_node_false = Ruby::Literal.new(:value => false)

        ycp_node_true.compile(@context_empty).should  == ruby_node_true
        ycp_node_false.compile(@context_empty).should == ruby_node_false
      end

      it "returns correct AST node for integer constants" do
        ycp_node  = YCP::Const.new(:type => :int, :value => "42")

        ruby_node = Ruby::Literal.new(:value => 42)

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for float constants" do
        ycp_node_without_decimals = YCP::Const.new(
          :type  => :float,
          :value => "42."
        )
        ycp_node_with_decimals    = YCP::Const.new(
          :type => :float,
          :value => "42.1"
        )

        ruby_node_without_decimals = Ruby::Literal.new(:value => 42.0)
        ruby_node_with_decimals    = Ruby::Literal.new(:value => 42.1)

        ycp_node_without_decimals.compile(@context_empty).should ==
          ruby_node_without_decimals
        ycp_node_with_decimals.compile(@context_empty).should ==
          ruby_node_with_decimals
      end

      it "returns correct AST node for symbol constants" do
        ycp_node = YCP::Const.new(:type => :symbol, :value => "abcd")

        ruby_node = Ruby::Literal.new(:value => :abcd)

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for string constants" do
        ycp_node = YCP::Const.new(:type => :string, :value => "abcd")

        ruby_node = Ruby::Literal.new(:value => "abcd")

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for path constants" do
        ycp_node  = YCP::Const.new(:type => :path, :value => ".abcd")

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "path",
          :args     => [Ruby::Literal.new(:value => ".abcd")],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Continue, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::Continue.new

        ruby_node = Ruby::Next.new

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Default, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::Default.new(:body => @ycp_stmt_block)

        ruby_node = Ruby::Else.new(:body => @ruby_statements_non_empty)

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "removes a break statement from the end" do
        ycp_node = YCP::Default.new(:body => @ycp_stmt_block_break)

        ruby_node = Ruby::Else.new(:body => @ruby_statements_non_empty)

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::DefBlock, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::DefBlock.new(
          :symbols    => [],
          :statements => @ycp_statements
        )

        ruby_node = Ruby::Statements.new(
          :statements => [
            @ruby_assignment_a_42,
            @ruby_assignment_b_43,
            @ruby_assignment_c_44
          ]
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Do, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node for do statements without do" do
        ycp_node = YCP::Do.new(:do => nil, :while => @ycp_true)

        ruby_node = Ruby::While.new(
          :condition => @ruby_literal_true,
          :body      => Ruby::Begin.new(:statements => @ruby_statements_empty)
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for do statements with do" do
        ycp_node = YCP::Do.new(:do => @ycp_stmt_block, :while => @ycp_true)

        ruby_node = Ruby::While.new(
          :condition => @ruby_literal_true,
          :body      => Ruby::Begin.new(
            :statements => @ruby_statements_non_empty
          )
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Entry, :type => :ycp do
    describe "#compile" do
      describe "for qualified entries" do
        it "returns correct AST node" do
          ycp_node_m = YCP::Entry.new(:ns => "M", :name => "a")
          ycp_node_n = YCP::Entry.new(:ns => "N", :name => "a")

          ruby_node_m = Ruby::Variable.new(:name => "@a")
          ruby_node_n = Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "N"),
            :name     => "a",
            :args     => [],
            :block    => nil,
            :parens   => true
          )

          ycp_node_m.compile(@context_module).should == ruby_node_m
          ycp_node_n.compile(@context_module).should == ruby_node_n
        end
      end

      describe "for unqualified entries" do
        def ruby_variable(name)
          Ruby::Variable.new(:name => name)
        end

        before :each do
          @ycp_node_regular    = YCP::Entry.new(:ns => nil, :name => "a")
          @ycp_node_capital    = YCP::Entry.new(:ns => nil, :name => "A")
          @ycp_node_underscore = YCP::Entry.new(:ns => nil, :name => "_a")
          @ycp_node_reserved   = YCP::Entry.new(:ns => nil, :name => "end")
        end

        describe "in global context that refer to global variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_variable("@a")
            ruby_node_capital    = ruby_variable("@A")
            ruby_node_underscore = ruby_variable("@_a")
            ruby_node_reserved   = ruby_variable("@end")

            @ycp_node_regular.compile(@context_global).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_global).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_global).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_global).should ==
              ruby_node_reserved
          end
        end

        describe "in local context that refer to global variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_variable("@a")
            ruby_node_capital    = ruby_variable("@A")
            ruby_node_underscore = ruby_variable("@_a")
            ruby_node_reserved   = ruby_variable("@end")

            @ycp_node_regular.compile(@context_local_global_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_global_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_global_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_global_vars).should ==
              ruby_node_reserved
          end
        end

        describe "in local context that refer to local variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_variable("a")
            ruby_node_capital    = ruby_variable("_A")
            ruby_node_underscore = ruby_variable("__a")
            ruby_node_reserved   = ruby_variable("_end")

            @ycp_node_regular.compile(@context_local_local_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_local_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_local_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_local_vars).should ==
              ruby_node_reserved
          end
        end

        describe "in nested local context that refer to inner variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_variable("a2")
            ruby_node_capital    = ruby_variable("_A2")
            ruby_node_underscore = ruby_variable("__a2")
            ruby_node_reserved   = ruby_variable("end2")

            @ycp_node_regular.compile(@context_local_nested_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_nested_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_nested_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_nested_vars).should ==
              ruby_node_reserved
          end
        end
      end
    end
  end

  describe YCP::FileBlock, :type => :ycp do
    describe "#compile" do
      def ruby_client_statements(statements)
        class_statements = [
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "include",
            :args     => [Ruby::Variable.new(:name => "YCP")],
            :block    => nil,
            :parens   => false
          )
        ] + statements

        Ruby::Program.new(
          :statements => Ruby::Statements.new(
            :statements => [
              Ruby::Module.new(
                :name       => "YCP",
                :statements => Ruby::Module.new(
                  :name       => "Clients",
                  :statements => Ruby::Class.new(
                    :name       => "CClient",
                    :statements => Ruby::Statements.new(
                      :statements => class_statements
                    )
                  )
                )
              ),
              Ruby::MethodCall.new(
                :receiver => Ruby::MethodCall.new(
                  :receiver => Ruby::ConstAccess.new(
                    :receiver => Ruby::ConstAccess.new(
                      :receiver => Ruby::Variable.new(:name => "YCP"),
                      :name     => "Clients"
                    ),
                    :name     => "CClient"
                  ),
                  :name     => "new",
                  :args     => [],
                  :block    => nil,
                  :parens   => true
                ),
                :name     => "main",
                :args     => [],
                :block    => nil,
                :parens   => true
              )
            ]
          )
        )
      end

      it "returns correct AST node for empty blocks" do
        ycp_node = YCP::FileBlock.new(
          :filename   => "c.ycp",
          :symbols    => [],
          :statements => []
        )

        ruby_node = ruby_client_statements([])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for blocks with statements" do
        ycp_node = YCP::FileBlock.new(
          :filename   => "c.ycp",
          :symbols    => [],
          :statements => @ycp_statements
        )

        ruby_node = ruby_client_statements([
          Ruby::Def.new(
            :name       => "main",
            :args       => [],
            :statements => @ruby_statements_non_empty
          )
        ])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for blocks with textdomain statements" do
        ycp_node = YCP::FileBlock.new(
          :filename   => "c.ycp",
          :symbols    => [],
          :statements => [
            @ycp_textdomain_d,
            @ycp_textdomain_e,
            @ycp_textdomain_f
          ]
        )

        ruby_node = ruby_client_statements([
          @ruby_textdomain_d,
          @ruby_textdomain_e,
          @ruby_textdomain_f
        ])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for blocks with function definitions" do
        ycp_node = YCP::FileBlock.new(
          :filename   => "c.ycp",
          :symbols    => [],
          :statements => [
            @ycp_fundef_f,
            @ycp_fundef_g,
            @ycp_fundef_h
          ]
        )

        ruby_node = ruby_client_statements([
          @ruby_def_f,
          @ruby_def_g,
          @ruby_def_h,
        ])

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Filename, :type => :ycp do
    describe "#compile" do
      it "returns nil" do
        ycp_node = YCP::Filename.new

        ycp_node.compile(@context_empty).should be_nil
      end
    end
  end

  describe YCP::FunDef, :type => :ycp do
    describe "#compile" do
      def ycp_symbol(type, name)
        YCP::Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => type,
          :name     => name
        )
      end

      def ycp_fundef_with_args(type)
        YCP::FunDef.new(
          :name  => "f",
          :args  => [
            ycp_symbol(type, "a"),
            ycp_symbol(type, "b"),
            ycp_symbol(type, "c")
          ],
          :block => @ycp_def_block
        )
      end

      def ruby_arg_copy(name)
        Ruby::Assignment.new(
          :lhs => Ruby::Variable.new(:name => name),
          :rhs => Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "copy_arg",
            :args     => [Ruby::Variable.new(:name => name)],
            :block    => nil,
            :parens   => true
          )
        )
      end

      describe "for toplevel function definitions" do
        it "returns correct AST node for function definitions without argument" do
          ycp_node = YCP::FunDef.new(
            :name  => "f",
            :args  => [],
            :block => @ycp_def_block
          )

          ruby_node = Ruby::Def.new(
            :name => "f",
            :args => [],
            :statements => Ruby::Statements.new(
              :statements => [
                @ruby_assignment_a_42,
                @ruby_assignment_b_43,
                @ruby_assignment_c_44,
                @ruby_literal_nil
              ]
            )
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end

        it "returns correct AST node for function definitions with arguments" do
          ycp_node_without_copy = ycp_fundef_with_args("boolean")
          ycp_node_with_copy    = ycp_fundef_with_args("string")

          ruby_node_without_copy = Ruby::Def.new(
            :name => "f",
            :args => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
            :statements => Ruby::Statements.new(
              :statements => [
                @ruby_assignment_a_42,
                @ruby_assignment_b_43,
                @ruby_assignment_c_44,
                @ruby_literal_nil
              ]
            )
          )

          ruby_node_with_copy = Ruby::Def.new(
            :name => "f",
            :args => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
            :statements => Ruby::Statements.new(
              :statements => [
                ruby_arg_copy("a"),
                ruby_arg_copy("b"),
                ruby_arg_copy("c"),
                @ruby_assignment_a_42,
                @ruby_assignment_b_43,
                @ruby_assignment_c_44,
                @ruby_literal_nil
              ]
            )
          )

          ycp_node_without_copy.compile(@context_empty).should ==
            ruby_node_without_copy
          ycp_node_with_copy.compile(@context_empty).should ==
            ruby_node_with_copy
        end
      end

      describe "for nested function definitions" do
        def ruby_def(name)
          Ruby::Assignment.new(
            :lhs => Ruby::Variable.new(:name => name),
            :rhs => Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "lambda",
              :args     => [],
              :block    => Ruby::Block.new(
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => [
                    @ruby_assignment_a_42,
                    @ruby_assignment_b_43,
                    @ruby_assignment_c_44,
                    @ruby_literal_nil
                  ]
                )
              ),
              :parens   => true
            )
          )
        end

        before :each do
          @ycp_node_regular    = YCP::FunDef.new(
            :name  => "f",
            :args  => [],
            :block => @ycp_def_block
          )
          @ycp_node_capital    = YCP::FunDef.new(
            :name  => "F",
            :args  => [],
            :block => @ycp_def_block
          )
          @ycp_node_underscore = YCP::FunDef.new(
            :name  => "_f",
            :args  => [],
            :block => @ycp_def_block
          )
          @ycp_node_reserved   = YCP::FunDef.new(
            :name  => "end",
            :args  => [],
            :block => @ycp_def_block
          )
        end

        describe "in local context" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_def("f")
            ruby_node_capital    = ruby_def("_F")
            ruby_node_underscore = ruby_def("__f")
            ruby_node_reserved   = ruby_def("_end")

            @ycp_node_regular.compile(@context_local_local_funs).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_local_funs).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_local_funs).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_local_funs).should ==
              ruby_node_reserved
          end
        end

        describe "in nested local context" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_def("f2")
            ruby_node_capital    = ruby_def("_F2")
            ruby_node_underscore = ruby_def("__f2")
            ruby_node_reserved   = ruby_def("end2")

            @ycp_node_regular.compile(@context_local_nested_funs).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_nested_funs).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_nested_funs).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_nested_funs).should ==
              ruby_node_reserved
          end
        end

        it "returns correct AST node for function definitions without argument" do
          ycp_node = YCP::FunDef.new(
            :name  => "f",
            :args  => [],
            :block => @ycp_def_block
          )

          ruby_node = Ruby::Assignment.new(
            :lhs => Ruby::Variable.new(:name => "f"),
            :rhs => Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "lambda",
              :args     => [],
              :block    => Ruby::Block.new(
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => [
                    @ruby_assignment_a_42,
                    @ruby_assignment_b_43,
                    @ruby_assignment_c_44,
                    @ruby_literal_nil
                  ]
                )
              ),
              :parens   => true
            )
          )

          ycp_node.compile(@context_local_local_funs).should == ruby_node
        end

        it "returns correct AST node for function definitions with arguments" do
          ycp_node_without_copy = ycp_fundef_with_args("boolean")
          ycp_node_with_copy    = ycp_fundef_with_args("string")

          ruby_node_without_copy = Ruby::Assignment.new(
            :lhs => Ruby::Variable.new(:name => "f"),
            :rhs => Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "lambda",
              :args     => [],
              :block    => Ruby::Block.new(
                :args       => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
                :statements => Ruby::Statements.new(
                  :statements => [
                    @ruby_assignment_a_42,
                    @ruby_assignment_b_43,
                    @ruby_assignment_c_44,
                    @ruby_literal_nil
                  ]
                )
              ),
              :parens   => true
            )
          )
          ruby_node_with_copy = Ruby::Assignment.new(
            :lhs => Ruby::Variable.new(:name => "f"),
            :rhs => Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "lambda",
              :args     => [],
              :block    => Ruby::Block.new(
                :args       => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
                :statements => Ruby::Statements.new(
                  :statements => [
                    ruby_arg_copy("a"),
                    ruby_arg_copy("b"),
                    ruby_arg_copy("c"),
                    @ruby_assignment_a_42,
                    @ruby_assignment_b_43,
                    @ruby_assignment_c_44,
                    @ruby_literal_nil
                  ]
                )
              ),
              :parens   => true
            )
          )

          ycp_node_without_copy.compile(@context_local_local_funs).should ==
            ruby_node_without_copy
          ycp_node_with_copy.compile(@context_local_local_funs).should ==
            ruby_node_with_copy
        end
      end
    end
  end

  describe YCP::If, :type => :ycp do
    describe "#to_ruby" do
      it "returns correct AST node for if statements without then and else" do
        ycp_node = YCP::If.new(:cond => @ycp_true, :then => nil, :else => nil)

        ruby_node = Ruby::If.new(
          :condition => @ruby_literal_true,
          :then      => @ruby_statements_empty,
          :else      => nil
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for if statements with then but without else" do
        ycp_node = YCP::If.new(
          :cond => @ycp_true,
          :then => @ycp_stmt_block,
          :else => nil
        )

        ruby_node = Ruby::If.new(
          :condition => @ruby_literal_true,
          :then      => @ruby_statements_non_empty,
          :else      => nil
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for if statements without then but with else" do
        ycp_node = YCP::If.new(
          :cond => @ycp_true,
          :then => nil,
          :else => @ycp_stmt_block
        )

        ruby_node = Ruby::If.new(
          :condition => @ruby_literal_true,
          :then      => @ruby_statements_empty,
          :else      => @ruby_statements_non_empty
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for if statements with then and else" do
        ycp_node = YCP::If.new(
          :cond => @ycp_true,
          :then => @ycp_stmt_block,
          :else => @ycp_stmt_block
        )

        ruby_node = Ruby::If.new(
          :condition => @ruby_literal_true,
          :then      => @ruby_statements_non_empty,
          :else      => @ruby_statements_non_empty
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Import, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node for regular imports" do
        ycp_node = YCP::Import.new(:name => "M")

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "YCP"),
          :name     => "import",
          :args     => [Ruby::Literal.new(:value => "M")],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns nil for SCR imports" do
        ycp_node = YCP::Import.new(:name => "SCR")

        ycp_node.compile(@context_empty).should be_nil
      end

      it "returns nil for WFM imports" do
        ycp_node = YCP::Import.new(:name => "WFM")

        ycp_node.compile(@context_empty).should be_nil
      end
    end
  end

  describe YCP::Include, :type => :ycp do
    describe "#compile" do
      it "returns nil" do
        ycp_node = YCP::Include.new

        ycp_node.compile(@context_empty).should be_nil
      end
    end
  end

  describe YCP::List, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::List.new(
          :children => [@ycp_const_42, @ycp_const_43, @ycp_const_44]
        )

        ruby_node = Ruby::Array.new(
          :elements => [@ruby_literal_42, @ruby_literal_43, @ruby_literal_44]
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Locale, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::Locale.new(:text => "text")

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "_",
          :args     => [Ruby::Literal.new(:value => "text")],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Map, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::Map.new(
          :children => [
            YCP::MapElement.new(:key => @ycp_const_a, :value => @ycp_const_42),
            YCP::MapElement.new(:key => @ycp_const_b, :value => @ycp_const_43),
            YCP::MapElement.new(:key => @ycp_const_c, :value => @ycp_const_44)
          ]
        )

        ruby_node = Ruby::Hash.new(
          :entries => [
            Ruby::HashEntry.new(
              :key   => @ruby_literal_a,
              :value => @ruby_literal_42
            ),
            Ruby::HashEntry.new(
              :key   => @ruby_literal_b,
              :value => @ruby_literal_43
            ),
            Ruby::HashEntry.new(
              :key   => @ruby_literal_c,
              :value => @ruby_literal_44
            )
          ]
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::MapElement, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::MapElement.new(
          :key   => @ycp_const_a,
          :value => @ycp_const_42
        )

        ruby_node = Ruby::HashEntry.new(
          :key   => @ruby_literal_a,
          :value => @ruby_literal_42
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::ModuleBlock, :type => :ycp do
    describe "#compile" do
      def ruby_module_statements(statements)
        class_statements = [
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "include",
            :args     => [Ruby::Variable.new(:name => "YCP")],
            :block    => nil,
            :parens   => false
          ),
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "extend",
            :args     => [Ruby::Variable.new(:name => "Exportable")],
            :block    => nil,
            :parens   => false
          )
        ] + statements

        Ruby::Program.new(
          :statements => Ruby::Statements.new(
            :statements => [
              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "require",
                :args     => [Ruby::Literal.new(:value => "ycp")],
                :block    => nil,
                :parens   => false
              ),
              Ruby::Module.new(
                :name       => "YCP",
                :statements => Ruby::Statements.new(
                  :statements => [
                    Ruby::Class.new(
                      :name       => "MClass",
                      :statements => Ruby::Statements.new(
                        :statements => class_statements
                      )
                    ),
                    Ruby::Assignment.new(
                      :lhs => Ruby::Variable.new(:name => "M"),
                      :rhs => Ruby::MethodCall.new(
                        :receiver => Ruby::Variable.new(:name => "MClass"),
                        :name     => "new",
                        :args     => [],
                        :block    => nil,
                        :parens   => true
                      )
                    )
                  ]
                )
              ),
            ]
          )
        )
      end

      def ruby_publish_call(name, private)
        entries = [
          Ruby::HashEntry.new(
            :key   => Ruby::Literal.new(:value => :variable),
            :value => Ruby::Literal.new(:value => name.to_sym)
          ),
          Ruby::HashEntry.new(
            :key   => Ruby::Literal.new(:value => :type),
            :value => Ruby::Literal.new(:value => "integer")
          )
        ]

        if private
          entries << Ruby::HashEntry.new(
            :key   => Ruby::Literal.new(:value => :private),
            :value => Ruby::Literal.new(:value => true)
          )
        end

        Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "publish",
          :args     => [Ruby::Hash.new(:entries => entries)],
          :block    => nil,
          :parens   => true
        )
      end

      it "returns correct AST node for empty blocks" do
        ycp_node = YCP::ModuleBlock.new(
          :name       => "M",
          :symbols    => [],
          :statements => []
        )

        ruby_node = ruby_module_statements([])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for blocks with symbols" do
        ycp_node = YCP::ModuleBlock.new(
          :name       => "M",
          :symbols    => @ycp_symbols_public,
          :statements => []
        )

        ruby_node = ruby_module_statements([
          ruby_publish_call("a", false),
          ruby_publish_call("b", false),
          ruby_publish_call("c", false)
        ])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for blocks with statements" do
        ycp_node = YCP::ModuleBlock.new(
          :name       => "M",
          :symbols    => [],
          :statements => @ycp_statements
        )

        ruby_node = ruby_module_statements([
          Ruby::Def.new(
            :name       => "initialize",
            :args       => [],
            :statements => @ruby_statements_non_empty
          )
        ])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for blocks with textdomain statements" do
        ycp_node = YCP::ModuleBlock.new(
          :name       => "M",
          :symbols    => [],
          :statements => [
            @ycp_textdomain_d,
            @ycp_textdomain_e,
            @ycp_textdomain_f
          ]
        )

        ruby_node = ruby_module_statements([
          @ruby_textdomain_d,
          @ruby_textdomain_e,
          @ruby_textdomain_f
        ])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for blocks with function definitions" do
        ycp_node = YCP::ModuleBlock.new(
          :name       => "M",
          :symbols    => [],
          :statements => [
            @ycp_fundef_f,
            @ycp_fundef_g,
            @ycp_fundef_h
          ]
        )

        ruby_node = ruby_module_statements([
          @ruby_def_f,
          @ruby_def_g,
          @ruby_def_h,
        ])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "uppercases the first letter of the module name" do
        ycp_node = YCP::ModuleBlock.new(
          :name       => "m.ycp",
          :symbols    => [],
          :statements => []
        )

        ruby_node = ruby_module_statements([])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "strips the \".ycp\" extension from module name" do
        ycp_node = YCP::ModuleBlock.new(
          :name       => "M.ycp",
          :symbols    => [],
          :statements => []
        )

        ruby_node = ruby_module_statements([])

        ycp_node.compile(@context_empty).should == ruby_node
      end

      describe "in context with export_private == false" do
        it "does not export private symbols" do
          context = YCP::Context.new(:export_private => false)

          ycp_node = YCP::ModuleBlock.new(
            :name       => "M",
            :symbols    => @ycp_symbols_private,
            :statements => []
          )

          ruby_node = ruby_module_statements([])

          ycp_node.compile(context).should == ruby_node
        end
      end

      describe "in context with export_private == true" do
        it "does exports private symbols" do
          context = YCP::Context.new(:export_private => true)

          ycp_node = YCP::ModuleBlock.new(
            :name       => "M",
            :symbols    => @ycp_symbols_private,
            :statements => []
          )

          ruby_node = ruby_module_statements([
            ruby_publish_call("a", true),
            ruby_publish_call("b", true),
            ruby_publish_call("c", true)
          ])

          ycp_node.compile(context).should == ruby_node
        end
      end
    end
  end

  describe YCP::Repeat, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node for repeat statements without do" do
        ycp_node = YCP::Repeat.new(:do => nil, :until => @ycp_true)

        ruby_node = Ruby::Until.new(
          :condition => @ruby_literal_true,
          :body      => Ruby::Begin.new(:statements => @ruby_statements_empty)
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for repeat statements with do" do
        ycp_node = YCP::Repeat.new(:do => @ycp_stmt_block, :until => @ycp_true)

        ruby_node = Ruby::Until.new(
          :condition => @ruby_literal_true,
          :body      => Ruby::Begin.new(
            :statements => @ruby_statements_non_empty
          )
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Return, :type => :ycp do
    describe "#compile" do
      before :each do
        @ycp_node_without_value = YCP::Return.new(:child => nil)
        @ycp_node_with_value    = YCP::Return.new(:child => @ycp_const_42)

        @ruby_node_return_without_value = Ruby::Return.new(:value => nil)
        @ruby_node_return_with_value    = Ruby::Return.new(:value => @ruby_literal_42)
        @ruby_node_next_without_value   = Ruby::Next.new(:value => nil)
        @ruby_node_next_with_value      = Ruby::Next.new(:value => @ruby_literal_42)
      end

      describe "for return statements at the client toplevel" do
        it "returns correct AST node for a return without a value" do
          @ycp_node_without_value.compile(@context_def).should ==
            @ruby_node_return_without_value
        end

        it "returns correct AST node for a return with a value" do
          @ycp_node_with_value.compile(@context_def).should ==
            @ruby_node_return_with_value
        end
      end

      describe "for return statements inside a function" do
        it "returns correct AST node for a return without a value" do
          @ycp_node_without_value.compile(@context_def).should ==
            @ruby_node_return_without_value
        end

        it "returns correct AST node for a return with a value" do
          @ycp_node_with_value.compile(@context_def).should ==
            @ruby_node_return_with_value
        end
      end

      describe "for return statements inside a function which is inside a client toplevel" do
        it "returns correct AST node for a return without a value" do
          @ycp_node_without_value.compile(@context_def_in_file).should ==
            @ruby_node_return_without_value
        end

        it "returns correct AST node for a return with a value" do
          @ycp_node_with_value.compile(@context_def_in_file).should ==
            @ruby_node_return_with_value
        end
      end

      describe "for return statements inside a function which is inside a block expression" do
        it "returns correct AST node for a return without a value" do
          @ycp_node_without_value.compile(@context_def_in_unspec).should ==
            @ruby_node_return_without_value
        end

        it "returns correct AST node for a return with a value" do
          @ycp_node_with_value.compile(@context_def_in_unspec).should ==
            @ruby_node_return_with_value
        end
      end

      describe "for return statements inside a block expression" do
        it "returns correct AST node for a return without a value" do
          @ycp_node_without_value.compile(@context_unspec).should ==
            @ruby_node_next_without_value
        end

        it "returns correct AST node for a return with a value" do
          @ycp_node_with_value.compile(@context_unspec).should ==
            @ruby_node_next_with_value
        end
      end

      describe "for return statements inside a block expression which is inside a client toplevel" do
        it "returns correct AST node for a return without a value" do
          @ycp_node_without_value.compile(@context_unspec_in_file).should ==
            @ruby_node_next_without_value
        end

        it "returns correct AST node for a return with a value" do
          @ycp_node_with_value.compile(@context_unspec_in_file).should ==
            @ruby_node_next_with_value
        end
      end

      describe "for return statements inside a block expression which is inside a function" do
        it "returns correct AST node for a return without a value" do
          @ycp_node_without_value.compile(@context_unspec_in_def).should ==
            @ruby_node_next_without_value
        end

        it "returns correct AST node for a return with a value" do
          @ycp_node_with_value.compile(@context_unspec_in_def).should ==
            @ruby_node_next_with_value
        end
      end
    end
  end

  describe YCP::StmtBlock, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::StmtBlock.new(
          :symbols    => [],
          :statements => @ycp_statements
        )

        ruby_node = Ruby::Statements.new(
          :statements => [
            @ruby_assignment_a_42,
            @ruby_assignment_b_43,
            @ruby_assignment_c_44
          ]
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Switch, :type => :ycp do
    describe "#compile" do
      it "emits correct code for empty switch statements" do
        ycp_node = YCP::Switch.new(
          :cond    => @ycp_const_42,
          :cases   => [],
          :default => nil
        )

        ruby_node = Ruby::Case.new(
          :expression => @ruby_literal_42,
          :whens      => [],
          :else       => nil
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "emits correct code for switch statements with one case and no default" do
        ycp_node = YCP::Switch.new(
          :cond    => @ycp_const_42,
          :cases   => [@ycp_case_42],
          :default => nil
        )

        ruby_node = Ruby::Case.new(
          :expression => @ruby_literal_42,
          :whens      => [@ruby_when_42],
          :else       => nil
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "emits correct code for switch statements with multiple cases and no default" do
        ycp_node = YCP::Switch.new(
          :cond    => @ycp_const_42,
          :cases   => [@ycp_case_42, @ycp_case_43, @ycp_case_44],
          :default => nil
        )

        ruby_node = Ruby::Case.new(
          :expression => @ruby_literal_42,
          :whens      => [@ruby_when_42, @ruby_when_43, @ruby_when_44],
          :else       => nil
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "emits correct code for switch statements with one case and a default" do
        ycp_node = YCP::Switch.new(
          :cond    => @ycp_const_42,
          :cases   => [@ycp_case_42],
          :default => @ycp_default
        )

        ruby_node = Ruby::Case.new(
          :expression => @ruby_literal_42,
          :whens      => [@ruby_when_42],
          :else       => @ruby_else
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "emits correct code for switch statements with multiple cases and a default" do
        ycp_node = YCP::Switch.new(
          :cond    => @ycp_const_42,
          :cases   => [@ycp_case_42, @ycp_case_43, @ycp_case_44],
          :default => @ycp_default
        )

        ruby_node = Ruby::Case.new(
          :expression => @ruby_literal_42,
          :whens      => [@ruby_when_42, @ruby_when_43, @ruby_when_44],
          :else       => @ruby_else
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Symbol, :type => :ycp do
    before :each do
      @ycp_node_regular = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "s"
      )
      @ycp_node_capital = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "S"
      )
      @ycp_node_underscore = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "_s"
      )
      @ycp_node_reserved = YCP::Symbol.new(
        :global   => false,
        :category => :variable,
        :type     => "integer",
        :name     => "end"
      )
    end

    describe "#needs_copy?" do
      def ycp_symbol(type)
        YCP::Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => type,
          :name     => "s"
        )
      end

      it "returns false for booleans" do
        ycp_node = ycp_symbol("boolean")

        ycp_node.needs_copy?.should be_false
      end

      it "returns false for integers" do
        ycp_node = ycp_symbol("integer")

        ycp_node.needs_copy?.should be_false
      end

      it "returns false for symbols" do
        ycp_node = ycp_symbol("symbol")

        ycp_node.needs_copy?.should be_false
      end

      it "returns false for references" do
        ycp_node = ycp_symbol("string &")

        ycp_node.needs_copy?.should be_false
      end

      it "returns true for other types" do
        ycp_node = ycp_symbol("string")

        ycp_node.needs_copy?.should be_true
      end
    end

    describe "#exportable?" do
      def ycp_symbol(category, type)
        YCP::Symbol.new(
          :global   => false,
          :category => category,
          :type     => type,
          :name     => "s"
        )
      end

      it "returns true for variables" do
        ycp_node = ycp_symbol(:variable, "integer")

        ycp_node.should be_exportable
      end

      it "returns true for functions" do
        ycp_node = ycp_symbol(:function, "integer ()")

        ycp_node.should be_exportable
      end

      it "returns false for other global symbols" do
        ycp_node = ycp_symbol(:filename, nil)

        ycp_node.should_not be_exportable
      end
    end


    describe "#compile" do
      it "returns correct AST node" do
        ruby_node_regular    = Ruby::Arg.new(:name => "s", :default => nil)
        ruby_node_capital    = Ruby::Arg.new(:name => "_S", :default => nil)
        ruby_node_underscore = Ruby::Arg.new(:name => "__s", :default => nil)
        ruby_node_reserved   = Ruby::Arg.new(:name => "_end", :default => nil)

        @ycp_node_regular.compile(@context_empty).should ==
          ruby_node_regular
        @ycp_node_capital.compile(@context_empty).should ==
          ruby_node_capital
        @ycp_node_underscore.compile(@context_empty).should ==
          ruby_node_underscore
        @ycp_node_reserved.compile(@context_empty).should ==
          ruby_node_reserved
      end
    end

    describe "#compile_as_copy_arg_call" do
      def ruby_copy_call(name)
        Ruby::Assignment.new(
          :lhs => Ruby::Variable.new(:name => name),
          :rhs => Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "copy_arg",
            :args     => [Ruby::Variable.new(:name => name)],
            :block    => nil,
            :parens   => true
          )
        )
      end

      it "returns correct AST node" do
        ruby_node_regular    = ruby_copy_call("s")
        ruby_node_capital    = ruby_copy_call("_S")
        ruby_node_underscore = ruby_copy_call("__s")

        @ycp_node_regular.compile_as_copy_arg_call(@context_empty).should ==
          ruby_node_regular
        @ycp_node_capital.compile_as_copy_arg_call(@context_empty).should ==
          ruby_node_capital
        @ycp_node_underscore.compile_as_copy_arg_call(@context_empty).should ==
          ruby_node_underscore
      end
    end

    describe "#compile_as_publish_call" do
      it "returns correct AST node for global symbols" do
        ycp_node = YCP::Symbol.new(
          :global   => true,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "publish",
          :args     => [
            Ruby::Hash.new(
              :entries => [
                Ruby::HashEntry.new(
                  :key   => Ruby::Literal.new(:value => :variable),
                  :value => Ruby::Literal.new(:value => :s)
                ),
                Ruby::HashEntry.new(
                  :key   => Ruby::Literal.new(:value => :type),
                  :value => Ruby::Literal.new(:value => "integer")
                )
              ]
            )
          ],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile_as_publish_call(@context_empty).should == ruby_node
      end

      it "returns correct AST node for non-global symbols" do
        ycp_node = YCP::Symbol.new(
          :global   => false,
          :category => :variable,
          :type     => "integer",
          :name     => "s"
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "publish",
          :args     => [
            Ruby::Hash.new(
              :entries => [
                Ruby::HashEntry.new(
                  :key   => Ruby::Literal.new(:value => :variable),
                  :value => Ruby::Literal.new(:value => :s)
                ),
                Ruby::HashEntry.new(
                  :key   => Ruby::Literal.new(:value => :type),
                  :value => Ruby::Literal.new(:value => "integer")
                ),
                Ruby::HashEntry.new(
                  :key   => Ruby::Literal.new(:value => :private),
                  :value => Ruby::Literal.new(:value => true)
                )
              ]
            )
          ],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile_as_publish_call(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Textdomain, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::Textdomain.new(:name => "d")

        ruby_node = Ruby::Statements.new(
          :statements => [
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "include",
              :args     => [Ruby::Variable.new(:name => "I18n")],
              :block    => nil,
              :parens   => false
            ),
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "textdomain",
              :args     => [Ruby::Literal.new(:value => "d")],
              :block    => nil,
              :parens   => false
            )
          ]
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Typedef, :type => :ycp do
    describe "#compile" do
      it "returns nil" do
        ycp_node = YCP::Typedef.new

        ycp_node.compile(@context_empty).should be_nil
      end
    end
  end

  describe YCP::UnspecBlock, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::UnspecBlock.new(
          :args       => [],
          :symbols    => [],
          :statements => @ycp_statements
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "lambda",
          :args     => [],
          :block    => Ruby::Block.new(
            :args       => [],
            :statements => @ruby_statements_non_empty
          ),
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end

    describe "#compile_as_block" do
      it "returns correct AST node without arguments" do
        ycp_node = YCP::UnspecBlock.new(
          :args       => [],
          :symbols    => [],
          :statements => @ycp_statements
        )

        ruby_node = Ruby::Block.new(
          :args       => [],
          :statements => @ruby_statements_non_empty
        )

        ycp_node.compile_as_block(@context_empty).should == ruby_node
      end

      it "returns correct AST node with arguments" do
        ycp_node = YCP::UnspecBlock.new(
          :args       => @ycp_symbols_private,
          :symbols    => [],
          :statements => @ycp_statements
        )

        ruby_node = Ruby::Block.new(
          :args       => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
          :statements => @ruby_statements_non_empty
        )

        ycp_node.compile_as_block(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::Variable, :type => :ycp do
    describe "#compile" do
      describe "for calls with category == \"variable\"" do
        describe "that are qualified" do
          it "returns correct AST node" do
            ycp_node_m = YCP::Variable.new(
              :category => "variable",
              :name     => "M::a"
            )
            ycp_node_n = YCP::Variable.new(
              :category => "variable",
              :name     => "N::a"
            )

            ruby_node_m = Ruby::Variable.new(:name => "@a")
            ruby_node_n = Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "N"),
              :name     => "a",
              :args     => [],
              :block    => nil,
              :parens   => true
            )

            ycp_node_m.compile(@context_module).should == ruby_node_m
            ycp_node_n.compile(@context_module).should == ruby_node_n
          end
        end

        describe "that are unqualified" do
          def ruby_variable(name)
            Ruby::Variable.new(:name => name)
          end

          before :each do
            @ycp_node_regular    = YCP::Variable.new(
              :category => "variable",
              :name     => "a"
            )
            @ycp_node_capital    = YCP::Variable.new(
              :category => "variable",
              :name     => "A"
            )
            @ycp_node_underscore = YCP::Variable.new(
              :category => "variable",
              :name     => "_a"
            )
            @ycp_node_reserved   = YCP::Variable.new(
              :category => "variable",
              :name     => "end"
            )
          end

          describe "in global context that refer to global variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("@a")
              ruby_node_capital    = ruby_variable("@A")
              ruby_node_underscore = ruby_variable("@_a")
              ruby_node_reserved   = ruby_variable("@end")

              @ycp_node_regular.compile(@context_global).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_global).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_global).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_global).should ==
                ruby_node_reserved
            end
          end

          describe "in local context that refer to global variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("@a")
              ruby_node_capital    = ruby_variable("@A")
              ruby_node_underscore = ruby_variable("@_a")
              ruby_node_reserved   = ruby_variable("@end")

              @ycp_node_regular.compile(@context_local_global_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_global_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_global_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_global_vars).should ==
                ruby_node_reserved
            end
          end

          describe "in local context that refer to local variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("a")
              ruby_node_capital    = ruby_variable("_A")
              ruby_node_underscore = ruby_variable("__a")
              ruby_node_reserved   = ruby_variable("_end")

              @ycp_node_regular.compile(@context_local_local_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_local_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_local_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_local_vars).should ==
                ruby_node_reserved
            end
          end

          describe "in nested local context that refer to inner variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("a2")
              ruby_node_capital    = ruby_variable("_A2")
              ruby_node_underscore = ruby_variable("__a2")
              ruby_node_reserved   = ruby_variable("end2")

              @ycp_node_regular.compile(@context_local_nested_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_nested_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_nested_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_nested_vars).should ==
                ruby_node_reserved
            end
          end
        end
      end

      describe "for calls with category == \"reference\"" do
        describe "that are qualified" do
          it "returns correct AST node" do
            ycp_node_m = YCP::Variable.new(
              :category => "reference",
              :name     => "M::a"
            )
            ycp_node_n = YCP::Variable.new(
              :category => "reference",
              :name     => "N::a"
            )

            ruby_node_m = Ruby::Variable.new(:name => "@a")
            ruby_node_n = Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "N"),
              :name     => "a",
              :args     => [],
              :block    => nil,
              :parens   => true
            )

            ycp_node_m.compile(@context_module).should == ruby_node_m
            ycp_node_n.compile(@context_module).should == ruby_node_n
          end
        end

        describe "that are unqualified" do
          def ruby_variable(name)
            Ruby::Variable.new(:name => name)
          end

          before :each do
            @ycp_node_regular    = YCP::Variable.new(
              :category => "reference",
              :name     => "a"
            )
            @ycp_node_capital    = YCP::Variable.new(
              :category => "reference",
              :name     => "A"
            )
            @ycp_node_underscore = YCP::Variable.new(
              :category => "reference",
              :name     => "_a"
            )
            @ycp_node_reserved   = YCP::Variable.new(
              :category => "reference",
              :name     => "end"
            )
          end

          describe "in global context that refer to global variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("@a")
              ruby_node_capital    = ruby_variable("@A")
              ruby_node_underscore = ruby_variable("@_a")
              ruby_node_reserved   = ruby_variable("@end")

              @ycp_node_regular.compile(@context_global).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_global).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_global).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_global).should ==
                ruby_node_reserved
            end
          end

          describe "in local context that refer to global variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("@a")
              ruby_node_capital    = ruby_variable("@A")
              ruby_node_underscore = ruby_variable("@_a")
              ruby_node_reserved   = ruby_variable("@end")

              @ycp_node_regular.compile(@context_local_global_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_global_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_global_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_global_vars).should ==
                ruby_node_reserved
            end
          end

          describe "in local context that refer to local variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("a")
              ruby_node_capital    = ruby_variable("_A")
              ruby_node_underscore = ruby_variable("__a")
              ruby_node_reserved   = ruby_variable("_end")

              @ycp_node_regular.compile(@context_local_local_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_local_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_local_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_local_vars).should ==
                ruby_node_reserved
            end
          end

          describe "in nested local context that refer to inner variables" do
            it "returns correct AST node" do
              ruby_node_regular    = ruby_variable("a2")
              ruby_node_capital    = ruby_variable("_A2")
              ruby_node_underscore = ruby_variable("__a2")
              ruby_node_reserved   = ruby_variable("end2")

              @ycp_node_regular.compile(@context_local_nested_vars).should ==
                ruby_node_regular
              @ycp_node_capital.compile(@context_local_nested_vars).should ==
                ruby_node_capital
              @ycp_node_underscore.compile(@context_local_nested_vars).should ==
                ruby_node_underscore
              @ycp_node_reserved.compile(@context_local_nested_vars).should ==
                ruby_node_reserved
            end
          end
        end
      end

      describe "for calls to toplevel functions with category == \"function\"" do
        it "returns correct AST node for unqualified variables" do
          ycp_node = YCP::Variable.new(
            :category => "function",
            :name     => "a",
            :type     => "integer ()"
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "reference",
            :args     => [
              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "method",
                :args     => [Ruby::Literal.new(:value => :a)],
                :block    => nil,
                :parens   => true
              ),
              Ruby::Literal.new(:value => "integer ()")
            ],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end

        it "returns correct AST node for qualified variables" do
          ycp_node = YCP::Variable.new(
            :category => "function",
            :name     => "M::a",
            :type     => "integer ()"
          )

          ruby_node = Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "reference",
            :args     => [
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "M"),
                :name     => "method",
                :args     => [Ruby::Literal.new(:value => :a)],
                :block    => nil,
                :parens   => true
              ),
              Ruby::Literal.new(:value => "integer ()")
            ],
            :block    => nil,
            :parens   => true
          )

          ycp_node.compile(@context_empty).should == ruby_node
        end
      end

      describe "for calls to nested functions with category == \"function\"" do
        def ruby_reference_call(name)
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "reference",
            :args     => [
              Ruby::Variable.new(:name => name),
              Ruby::Literal.new(:value => "integer ()")
            ],
            :block    => nil,
            :parens   => true
          )
        end

        before :each do
          @ycp_node_regular    = YCP::Variable.new(
            :category => "function",
            :name     => "a",
            :type     => "integer ()"
          )
          @ycp_node_capital    = YCP::Variable.new(
            :category => "function",
            :name     => "A",
            :type     => "integer ()"
          )
          @ycp_node_underscore = YCP::Variable.new(
            :category => "function",
            :name     => "_a",
            :type     => "integer ()"
          )
          @ycp_node_reserved   = YCP::Variable.new(
            :category => "function",
            :name     => "end",
            :type     => "integer ()"
          )
        end

        describe "in local context that refer to local variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_reference_call("a")
            ruby_node_capital    = ruby_reference_call("_A")
            ruby_node_underscore = ruby_reference_call("__a")
            ruby_node_reserved   = ruby_reference_call("_end")

            @ycp_node_regular.compile(@context_local_local_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_local_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_local_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_local_vars).should ==
              ruby_node_reserved
          end
        end

        describe "in nested local context that refer to inner variables" do
          it "returns correct AST node" do
            ruby_node_regular    = ruby_reference_call("a2")
            ruby_node_capital    = ruby_reference_call("_A2")
            ruby_node_underscore = ruby_reference_call("__a2")
            ruby_node_reserved   = ruby_reference_call("end2")

            @ycp_node_regular.compile(@context_local_nested_vars).should ==
              ruby_node_regular
            @ycp_node_capital.compile(@context_local_nested_vars).should ==
              ruby_node_capital
            @ycp_node_underscore.compile(@context_local_nested_vars).should ==
              ruby_node_underscore
            @ycp_node_reserved.compile(@context_local_nested_vars).should ==
              ruby_node_reserved
          end
        end
      end
    end
  end

  describe YCP::While, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node for while statements without do" do
        ycp_node = YCP::While.new(:cond => @ycp_true, :do => nil)

        ruby_node = Ruby::While.new(
          :condition => @ruby_literal_true,
          :body      => @ruby_statements_empty
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end

      it "returns correct AST node for while statements with do" do
        ycp_node = YCP::While.new(:cond => @ycp_true, :do => @ycp_stmt_block)

        ruby_node = Ruby::While.new(
          :condition => @ruby_literal_true,
          :body      => @ruby_statements_non_empty
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YCPCode, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::YCPCode.new(
          :args    => [],
          :symbols => [],
          :child   => @ycp_const_42
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "lambda",
          :args     => [],
          :block    => Ruby::Block.new(
            :args       => [],
            :statements => @ruby_literal_42
          ),
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end

    describe "#compile_as_block" do
      it "returns correct AST node without arguments" do
        ycp_node = YCP::YCPCode.new(
          :args    => [],
          :symbols => [],
          :child   => @ycp_const_42
        )

        ruby_node = Ruby::Block.new(
          :args       => [],
          :statements => @ruby_literal_42
        )

        ycp_node.compile_as_block(@context_empty).should == ruby_node
      end

      it "returns correct AST node with arguments" do
        ycp_node = YCP::YCPCode.new(
          :args    => @ycp_symbols_private,
          :symbols => @ycp_symbols_private,
          :child   => @ycp_const_42
        )

        ruby_node = Ruby::Block.new(
          :args       => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
          :statements => @ruby_literal_42
        )

        ycp_node.compile_as_block(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YEBinary, :type => :ycp do
    describe "#compile" do
      def ycp_ye_binary(name)
        YCP::YEBinary.new(
          :name => name,
          :lhs  => @ycp_const_42,
          :rhs  => @ycp_const_43
        )
      end

      def ruby_ops_call(name)
        Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Ops"),
          :name     => name,
          :args     => [@ruby_literal_42, @ruby_literal_43],
          :block    => nil,
          :parens   => true
        )
      end

      def ruby_operator(name)
        Ruby::BinaryOperator.new(
          :op  => name,
          :lhs => @ruby_literal_42,
          :rhs => @ruby_literal_43
        )
      end

      it "returns correct AST node" do
        ycp_node_add         = ycp_ye_binary("+")
        ycp_node_subtract    = ycp_ye_binary("-")
        ycp_node_multiply    = ycp_ye_binary("*")
        ycp_node_divide      = ycp_ye_binary("/")
        ycp_node_modulo      = ycp_ye_binary("%")
        ycp_node_bitwise_and = ycp_ye_binary("&")
        ycp_node_bitwise_or  = ycp_ye_binary("|" )
        ycp_node_bitwise_xor = ycp_ye_binary("^" )
        ycp_node_shift_left  = ycp_ye_binary("<<")
        ycp_node_shift_right = ycp_ye_binary(">>")
        ycp_node_logical_and = ycp_ye_binary("&&")
        ycp_node_logical_or  = ycp_ye_binary("||")

        ruby_node_add         = ruby_ops_call("add")
        ruby_node_subtract    = ruby_ops_call("subtract")
        ruby_node_multiply    = ruby_ops_call("multiply")
        ruby_node_divide      = ruby_ops_call("divide")
        ruby_node_modulo      = ruby_ops_call("modulo")
        ruby_node_bitwise_and = ruby_ops_call("bitwise_and")
        ruby_node_bitwise_or  = ruby_ops_call("bitwise_or")
        ruby_node_bitwise_xor = ruby_ops_call("bitwise_xor")
        ruby_node_shift_left  = ruby_ops_call("shift_left")
        ruby_node_shift_right = ruby_ops_call("shift_right")
        ruby_node_logical_and = ruby_operator("&&")
        ruby_node_logical_or  = ruby_operator("||")

        ycp_node_add.compile(@context_empty).should ==
          ruby_node_add
        ycp_node_subtract.compile(@context_empty).should ==
          ruby_node_subtract
        ycp_node_multiply.compile(@context_empty).should ==
          ruby_node_multiply
        ycp_node_divide.compile(@context_empty).should ==
          ruby_node_divide
        ycp_node_modulo.compile(@context_empty).should ==
          ruby_node_modulo
        ycp_node_bitwise_and.compile(@context_empty).should ==
          ruby_node_bitwise_and
        ycp_node_bitwise_or.compile(@context_empty).should ==
          ruby_node_bitwise_or
        ycp_node_bitwise_xor.compile(@context_empty).should ==
          ruby_node_bitwise_xor
        ycp_node_shift_left.compile(@context_empty).should ==
          ruby_node_shift_left
        ycp_node_shift_right.compile(@context_empty).should ==
          ruby_node_shift_right
        ycp_node_logical_and.compile(@context_empty).should ==
          ruby_node_logical_and
        ycp_node_logical_or.compile(@context_empty).should ==
          ruby_node_logical_or
      end
    end
  end

  describe YCP::YEBracket, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::YEBracket.new(
          :value   => YCP::List.new(
            :children => [@ycp_const_42, @ycp_const_43, @ycp_const_44]
          ),
          :index   => YCP::List.new(:children => [@ycp_const_1]),
          :default => @ycp_const_0
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Ops"),
          :name     => "index",
          :args     => [
            Ruby::Array.new(
              :elements => [
                @ruby_literal_42,
                @ruby_literal_43,
                @ruby_literal_44
              ]
            ),
            Ruby::Array.new(:elements => [@ruby_literal_1]),
            @ruby_literal_0,
          ],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YEIs, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::YEIs.new(:child => @ycp_const_42, :type  => "integer")

        ruby_node = Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Ops"),
          :name     => "is",
          :args     => [
            @ruby_literal_42,
            Ruby::Literal.new(:value => "integer")
          ],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YEPropagate, :type => :ycp do
    describe "#compile" do
      def ycp_yepropagate(from, to)
        YCP::YEPropagate.new(
          :from  => from,
          :to    => to,
          :child => @ycp_const_42
        )
      end

      def ruby_convert_call(from, to)
        Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Convert"),
          :name     => "convert",
          :args     => [
            @ruby_literal_42,
            Ruby::Hash.new(
              :entries => [
                Ruby::HashEntry.new(
                  :key   => Ruby::Literal.new(:value => :from),
                  :value => Ruby::Literal.new(:value => from)
                ),
                Ruby::HashEntry.new(
                  :key   => Ruby::Literal.new(:value => :to),
                  :value => Ruby::Literal.new(:value => to)
                )
              ]
            )
          ],
          :block    => nil,
          :parens   => true
        )
      end

      it "returns correct AST node when the types are the same" do
        ycp_node_no_const   = ycp_yepropagate("integer", "integer")
        ycp_node_both_const = ycp_yepropagate("const integer", "const integer")

        ycp_node_no_const.compile(@context_empty).should   == @ruby_literal_42
        ycp_node_both_const.compile(@context_empty).should == @ruby_literal_42
      end

      it "returns correct AST node when the types are the same but their constness is different" do
        ycp_node_from_const = ycp_yepropagate("const integer", "integer")
        ycp_node_to_const   = ycp_yepropagate("integer", "const integer")

        ycp_node_from_const.compile(@context_empty).should == @ruby_literal_42
        ycp_node_to_const.compile(@context_empty).should   == @ruby_literal_42
      end

      it "returns correct AST node when the types are different" do
        ycp_node_no_const   = ycp_yepropagate("integer", "float")
        ycp_node_both_const = ycp_yepropagate("const integer", "const float")

        ruby_node_no_const   = ruby_convert_call("integer", "float")
        ruby_node_both_const = ruby_convert_call("integer", "float")

        ycp_node_no_const.compile(@context_empty).should ==
          ruby_node_no_const
        ycp_node_both_const.compile(@context_empty).should ==
          ruby_node_both_const
      end

      it "returns correct AST node when when both the types and their constness are different" do
        ycp_node_from_const = ycp_yepropagate("const integer", "float")
        ycp_node_to_const   = ycp_yepropagate("integer", "const float")

        ruby_node_from_const = ruby_convert_call("integer", "float")
        ruby_node_to_const   = ruby_convert_call("integer", "float")

        ycp_node_from_const.compile(@context_empty).should ==
          ruby_node_from_const
        ycp_node_to_const.compile(@context_empty).should ==
          ruby_node_to_const
      end
    end
  end

  describe YCP::YEReference, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::YEReference.new(:child => @ycp_const_42)

        ruby_node = @ruby_literal_42

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YEReturn, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::YEReturn.new(
          :args    => [],
          :symbols => [],
          :child   => @ycp_const_42
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "lambda",
          :args     => [],
          :block    => Ruby::Block.new(
            :args       => [],
            :statements => @ruby_literal_42
          ),
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end

    describe "#compile_as_block" do
      it "returns correct AST node without arguments" do
        ycp_node = YCP::YEReturn.new(
          :args    => [],
          :symbols => [],
          :child   => @ycp_const_42
        )

        ruby_node = Ruby::Block.new(
          :args       => [],
          :statements => @ruby_literal_42
        )

        ycp_node.compile_as_block(@context_empty).should == ruby_node
      end

      it "returns correct AST node with arguments" do
        ycp_node = YCP::YEReturn.new(
          :args    => @ycp_symbols_private,
          :symbols => @ycp_symbols_private,
          :child   => @ycp_const_42
        )

        ruby_node = Ruby::Block.new(
          :args       => [@ruby_arg_a, @ruby_arg_b, @ruby_arg_c],
          :statements => @ruby_literal_42
        )

        ycp_node.compile_as_block(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YETerm, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::YETerm.new(
          :name     => "t",
          :children => [@ycp_const_42, @ycp_const_43, @ycp_const_44]
        )

        ruby_node = Ruby::MethodCall.new(
          :receiver => nil,
          :name     => "term",
          :args     => [
            Ruby::Literal.new(:value => :t),
            @ruby_literal_42,
            @ruby_literal_43,
            @ruby_literal_44
          ],
          :block    => nil,
          :parens   => true
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YETriple, :type => :ycp do
    describe "#compile" do
      it "returns correct AST node" do
        ycp_node = YCP::YETriple.new(
          :cond  => @ycp_true,
          :true  => @ycp_const_42,
          :false => @ycp_const_43
        )

        ruby_node = Ruby::Ternary.new(
          :condition => @ruby_literal_true,
          :then      => @ruby_literal_42,
          :else      => @ruby_literal_43
        )

        ycp_node.compile(@context_empty).should == ruby_node
      end
    end
  end

  describe YCP::YEUnary, :type => :ycp do
    describe "#compile" do
      def ycp_ye_unary(name)
        YCP::YEUnary.new(:name => name, :child => @ycp_const_42)
      end

      def ruby_ops_call(name)
        Ruby::MethodCall.new(
          :receiver => Ruby::Variable.new(:name => "Ops"),
          :name     => name,
          :args     => [@ruby_literal_42],
          :block    => nil,
          :parens   => true
        )
      end

      def ruby_operator(name)
        Ruby::UnaryOperator.new(
          :op         => name,
          :expression => @ruby_literal_42
        )
      end

      it "returns correct AST node" do
        ycp_node_unary_minus = ycp_ye_unary("-")
        ycp_node_bitwise_not = ycp_ye_unary("~")
        ycp_node_logical_not = ycp_ye_unary("!")

        ruby_node_unary_minus = ruby_ops_call("unary_minus")
        ruby_node_bitwise_not = ruby_ops_call("bitwise_not")
        ruby_node_logical_not = ruby_operator("!")

        ycp_node_unary_minus.compile(@context_empty).should ==
          ruby_node_unary_minus
        ycp_node_bitwise_not.compile(@context_empty).should ==
          ruby_node_bitwise_not
        ycp_node_logical_not.compile(@context_empty).should ==
          ruby_node_logical_not
      end
    end
  end
end
