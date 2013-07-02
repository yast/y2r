# encoding: utf-8

require "spec_helper"

def node_to_ruby_mock(expected_context)
  mock = double

  mock.should_receive(:to_ruby) do |context|
    expected_context.each_pair do |key, value|
      context.send(key).should == value
    end
    ""
  end

  mock
end

def node_width_and_to_ruby_mock(expected_context)
  mock = node_to_ruby_mock(expected_context)
  mock.should_receive(:single_line_width).and_return(0)
  mock
end

def node_to_ruby_enclosed_mock(expected_context)
  mock = double

  mock.should_receive(:to_ruby_enclosed) do |context|
    expected_context.each_pair do |key, value|
      context.send(key).should == value
    end
    ""
  end

  mock
end

module Y2R::AST::Ruby
  RSpec.configure do |c|
    c.before :each, :type => :ruby do
      @literal_true  = Literal.new(:value => true)
      @literal_false = Literal.new(:value => false)

      @literal_a   = Literal.new(:value => :a)
      @literal_aa  = Literal.new(:value => :aa)
      @literal_aaa = Literal.new(:value => :aaa)
      @literal_b   = Literal.new(:value => :b)
      @literal_c   = Literal.new(:value => :c)

      @literal_42 = Literal.new(:value => 42)
      @literal_43 = Literal.new(:value => 43)
      @literal_44 = Literal.new(:value => 44)
      @literal_45 = Literal.new(:value => 45)

      @variable_a = Variable.new(:name => "a")
      @variable_b = Variable.new(:name => "b")
      @variable_c = Variable.new(:name => "c")
      @variable_S = Variable.new(:name => "S")

      @assignment_a_42 = Assignment.new(
        :lhs => @variable_a,
        :rhs => @literal_42
      )
      @assignment_b_43 = Assignment.new(
        :lhs => @variable_b,
        :rhs => @literal_43
      )
      @assignment_c_44 = Assignment.new(
        :lhs => @variable_c,
        :rhs => @literal_44
      )

      @binary_operator_true_or_false = BinaryOperator.new(
        :op  => "||",
        :lhs => @literal_true,
        :rhs => @literal_false
      )
      @binary_operator_42_plus_43 = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_42,
        :rhs => @literal_43
      )
      @binary_operator_44_plus_45 = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_44,
        :rhs => @literal_45
      )

      @statements = Statements.new(
        :statements => [@assignment_a_42, @assignment_b_43, @assignment_c_44]
      )

      @hash_entry_a_42 = HashEntry.new(
        :key   => @literal_a,
        :value => @literal_42
      )
      @hash_entry_a_statements = HashEntry.new(
        :key   => @literal_a,
        :value => @statements
      )
      @hash_entry_aa_43 = HashEntry.new(
        :key   => @literal_aa,
        :value => @literal_43
      )
      @hash_entry_aaa_44 = HashEntry.new(
        :key   => @literal_aaa,
        :value => @literal_44
      )
      @hash_entry_b_43 = HashEntry.new(
        :key   => @literal_b,
        :value => @literal_43
      )
      @hash_entry_b_statements = HashEntry.new(
        :key   => @literal_b,
        :value => @statements
      )
      @hash_entry_c_44 = HashEntry.new(
        :key   => @literal_c,
        :value => @literal_44
      )
      @hash_entry_c_statements = HashEntry.new(
        :key   => @literal_c,
        :value => @statements
      )

      @begin = Begin.new(:statements => @statements)

      @when_42 = When.new(:values => [@literal_42], :body => @statements)
      @when_43 = When.new(:values => [@literal_43], :body => @statements)
      @when_44 = When.new(:values => [@literal_44], :body => @statements)

      @else = Else.new(:body => @statements)

      @def = Def.new(:name => "m", :args => [], :statements => @statements)

      @context_default       = EmitterContext.new(:width => 80, :shift => 0)
      @context_narrow        = EmitterContext.new(:width => 0, :shift => 0)
      @context_max_key_width = EmitterContext.new(
        :width         => 0,
        :shift         => 0,
        :max_key_width => 4
      )
    end
  end

  describe Node, :type => :ruby do
    class NotEnclosedNode < Node
      def enclose?
        false
      end

      def to_ruby(context)
        "ruby"
      end

      def single_line_width
        4
      end
    end

    class EnclosedNode < Node
      def enclose?
        true
      end

      def to_ruby(context)
        "ruby"
      end

      def single_line_width
        4
      end
    end

    before :each do
      @node_not_enclosed = NotEnclosedNode.new
      @node_enclosed     = EnclosedNode.new
    end

    describe "#to_ruby_enclosed" do
      describe "basics" do
        describe "on nodes where #enclosed? returns false" do
          it "returns code that is not enclosed in parens" do
            @node_not_enclosed.to_ruby_enclosed(@context_default).should == "ruby"
          end
        end

        describe "on nodes where #enclosed? returns true" do
          it "returns code that is enclosed in parens" do
            @node_enclosed.to_ruby_enclosed(@context_default).should == "(ruby)"
          end
        end
      end

      describe "formatting" do
        describe "on nodes where #enclosed? returns false" do
          it "passes correct available space info to #to_ruby" do
            @node_not_enclosed.should_receive(:to_ruby) do |context|
              context.width.should == 80
              context.shift.should == 0
              "ruby"
            end

            @node_not_enclosed.to_ruby_enclosed(@context_default)
          end
        end

        describe "on nodes where #enclosed? returns true" do
          it "passes correct available space info to #to_ruby" do
            @node_enclosed.should_receive(:to_ruby) do |context|
              context.width.should == 80
              context.shift.should == 1
              "ruby"
            end

            @node_enclosed.to_ruby_enclosed(@context_default)
          end
        end
      end
    end

    describe "#single_line_width_enclosed" do
      describe "on nodes where #enclosed? returns false" do
        it "returns correct value" do
          @node_not_enclosed.single_line_width_enclosed.should == 4
        end
      end

      describe "on nodes where #enclosed? returns true" do
        it "returns correct value" do
          @node_enclosed.single_line_width_enclosed.should == 6
        end
      end
    end
  end

  describe Program, :type => :ruby do
    before :each do
      @node_without_comment = Program.new(
        :statements => @statements,
        :comment    => nil
      )
      @node_with_comment = Program.new(
        :statements => @statements,
        :comment    => "line 1\n\nline 3"
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code without a comment" do
          @node_without_comment.to_ruby(@context_default).should == [
            "# encoding: utf-8",
            "",
            "a = 42",
            "b = 43",
            "c = 44"
          ].join("\n")
        end

        it "emits correct code with a comment" do
          @node_with_comment.to_ruby(@context_default).should == [
            "# encoding: utf-8",
            "",
            "# line 1",
            "#",
            "# line 3",
            "",
            "a = 42",
            "b = 43",
            "c = 44"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to statements" do
          node = Program.new(
            :statements => node_to_ruby_mock(:width => 80, :shift => 0),
            :comment    => nil
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity without a comment" do
        @node_without_comment.single_line_width.should == Float::INFINITY
      end

      it "returns infinity with a comment" do
        @node_with_comment.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Class, :type => :ruby do
    before :each do
      @node = Class.new(
        :name       => "C",
        :superclass => @variable_S,
        :statements => @statements
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == [
            "class C < S",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to superclass" do
          node = Class.new(
            :name       => "C",
            :superclass => node_to_ruby_mock(:width => 80, :shift => 10),
            :statements => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to statements" do
          node = Class.new(
            :name       => "C",
            :superclass => @variable_S,
            :statements => node_to_ruby_mock(:width => 78, :shift => 0),
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity" do
        @node.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Module, :type => :ruby do
    before :each do
      @node = Module.new(:name  => "M", :statements => @statements)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == [
            "module M",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to statements" do
          node = Module.new(
            :name       => "M",
            :statements => node_to_ruby_mock(:width => 78, :shift => 0),
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity" do
        @node.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Def, :type => :ruby do
    before :each do
      @node_no_args = Def.new(
        :name       => "m",
        :args       => [],
        :statements => @statements
      )
      @node_one_arg = Def.new(
        :name       => "m",
        :args       => [@variable_a],
        :statements => @statements
      )
      @node_multiple_args = Def.new(
        :name       => "m",
        :args       => [@variable_a, @variable_b, @variable_c],
        :statements => @statements
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for method definitions with no arguments" do
          @node_no_args.to_ruby(@context_default).should == [
            "def m",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for method definitions with one argument" do
          @node_one_arg.to_ruby(@context_default).should == [
            "def m(a)",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for method definitions with multiple arguments" do
          @node_multiple_args.to_ruby(@context_default).should == [
            "def m(a, b, c)",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to args" do
          node = Def.new(
            :name       => "m",
            :args       => [
              node_to_ruby_mock(:width => 80, :shift => 6),
              node_to_ruby_mock(:width => 80, :shift => 8),
              node_to_ruby_mock(:width => 80, :shift => 10)
            ],
            :statements => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to statements" do
          node = Def.new(
            :name       => "m",
            :args       => [],
            :statements => node_to_ruby_mock(:width => 78, :shift => 0),
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity for method definitions with no arguments" do
        @node_no_args.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for method definitions with one argument" do
        @node_one_arg.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for method definitions with multiple arguments" do
        @node_multiple_args.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Statements, :type => :ruby do
    before :each do
      @node_empty    = Statements.new(:statements => [])
      @node_one      = Statements.new(:statements => [@assignment_a_42])
      @node_multiple = Statements.new(
        :statements => [
          @assignment_a_42,
          @assignment_b_43,
          @assignment_c_44
        ]
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for statement lists with no statements" do
          @node_empty.to_ruby(@context_default).should == ""
        end

        it "emits correct code for statement lists with one statement" do
          @node_one.to_ruby(@context_default).should == "a = 42"
        end

        it "emits correct code for statement lists with multiple statements" do
          @node_multiple.to_ruby(@context_default).should == [
            "a = 42",
            "b = 43",
            "c = 44",
          ].join("\n")
        end

        it "handles nils in the statement list correctly" do
          node = Statements.new(
            :statements => [
              @assignment_a_42,
              nil,
              @assignment_b_43,
              nil,
              @assignment_c_44
            ]
          )

          node.to_ruby(@context_default).should == [
            "a = 42",
            "b = 43",
            "c = 44",
          ].join("\n")
        end

        it "emits blank lines before method definitions" do
          node = Statements.new(:statements => [@assignment_a_42, @def])

          node.to_ruby(@context_default).should == [
            "a = 42",
            "",
            "def m",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits blank lines after method definitions" do
          node = Statements.new(:statements => [@def, @assignment_a_42])

          node.to_ruby(@context_default).should == [
            "def m",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end",
            "",
            "a = 42"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to statements" do
          node = Statements.new(
            :statements => [node_to_ruby_mock(:width => 80, :shift => 0)]
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for statement lists with no statements" do
        @node_empty.single_line_width.should == 0
      end

      it "returns correct value for statement lists with one statement" do
        @node_one.single_line_width.should == 6
      end

      it "returns infinity for statement lists with multiple statements" do
        @node_multiple.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Begin, :type => :ruby do
    before :each do
      @node = Begin.new(:statements => @statements)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == [
            "begin",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to statements" do
          node = Begin.new(
            :statements => node_to_ruby_mock(:width => 78, :shift => 0)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity" do
        @node.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe If, :type => :ruby do
    before :each do
      @node_without_else_single = If.new(
        :condition => @literal_true,
        :then      => @assignment_a_42,
        :else      => nil
      )
      @node_without_else_multi = If.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => nil
      )
      @node_with_else = If.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => @statements
      )
    end

    describe "#to_ruby" do
      describe "for if statements without else" do
        it "emits a single-line if statement when the if statement fits available space and then is single-line" do
          node = If.new(
            :condition => @literal_true,
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby(@context_default).should == "a = 42 if true"
        end

        it "emits a multi-line if statement when the if statement doesn't fit available space" do
          node = If.new(
            :condition => @literal_true,
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby(@context_narrow).should == [
            "if true",
            "  a = 42",
            "end"
          ].join("\n")
        end

        it "emits a multi-line if statement when then is multi-line" do
          node = If.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => nil
          )

          node.to_ruby(@context_default).should == [
            "if true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        describe "for single-line if statements" do
          it "emits correct code" do
            @node_without_else_single.to_ruby(@context_default).should ==
              "a = 42 if true"
          end

          it "passes correct available space info to condition" do
            node = If.new(
              :condition => node_width_and_to_ruby_mock(
                :width => 80,
                :shift => 10
              ),
              :then      => @assignment_a_42,
              :else      => nil
            )

            node.to_ruby(@context_default)
          end

          it "passes correct available space info to then" do
            node = If.new(
              :condition => @literal_true,
              :then      => node_width_and_to_ruby_mock(
                :width => 80,
                :shift => 0
              ),
              :else      => nil
            )

            node.to_ruby(@context_default)
          end
        end

        describe "for multi-line if statements" do
          it "emits correct code" do
            @node_without_else_multi.to_ruby(@context_narrow).should == [
              "if true",
              "  a = 42",
              "  b = 43",
              "  c = 44",
              "end"
            ].join("\n")
          end

          it "passes correct available space info to condition" do
            node = If.new(
              :condition => node_width_and_to_ruby_mock(
                :width => 0,
                :shift => 3
              ),
              :then      => @statements,
              :else      => nil
            )

            node.to_ruby(@context_narrow)
          end

          it "passes correct available space info to then" do
            node = If.new(
              :condition => @literal_true,
              :then      => node_width_and_to_ruby_mock(
                :width => -2,
                :shift => 0
              ),
              :else      => nil
            )

            node.to_ruby(@context_narrow)
          end
        end
      end

      describe "for if statements with else" do
        it "emits correct code" do
          @node_with_else.to_ruby(@context_default).should == [
            "if true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "else",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "passes correct available space info to condition" do
          node = If.new(
            :condition => node_to_ruby_mock(:width => 80, :shift => 3),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to then" do
          node = If.new(
            :condition => @literal_true,
            :then      => node_to_ruby_mock(:width => 78, :shift => 0),
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to else" do
          node = If.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => node_to_ruby_mock(:width => 78, :shift => 0)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      describe "for if statements without else" do
        describe "for single-line if statements" do
          it "returns correct value" do
            @node_without_else_single.single_line_width.should == 14
          end
        end

        describe "for multi-line if statements" do
          it "returns infinity" do
            @node_without_else_multi.single_line_width.should == Float::INFINITY
          end
        end
      end

      describe "for if statements with else" do
        it "returns infinity" do
          @node_with_else.single_line_width.should == Float::INFINITY
        end
      end
    end
  end

  describe Unless, :type => :ruby do
    before :each do
      @node_without_else_single = Unless.new(
        :condition => @literal_true,
        :then      => @assignment_a_42,
        :else      => nil
      )
      @node_without_else_multi = Unless.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => nil
      )
      @node_with_else = Unless.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => @statements
      )
    end

    describe "#to_ruby" do
      describe "for unless statements without else" do
        it "emits a single-line unless statement when the unless statement fits available space and then is single-line" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby(@context_default).should == "a = 42 unless true"
        end

        it "emits a multi-line unless statement when the unless statement doesn't fit available space" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby(@context_narrow).should == [
            "unless true",
            "  a = 42",
            "end"
          ].join("\n")
        end

        it "emits a multi-line unless statement when then is multi-line" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => nil
          )

          node.to_ruby(@context_default).should == [
            "unless true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        describe "for single-line unless statements" do
          it "emits correct code" do
            @node_without_else_single.to_ruby(@context_default).should ==
              "a = 42 unless true"
          end

          it "passes correct available space info to condition" do
            node = Unless.new(
              :condition => node_width_and_to_ruby_mock(
                :width => 80,
                :shift => 14
              ),
              :then      => @assignment_a_42,
              :else      => nil
            )

            node.to_ruby(@context_default)
          end

          it "passes correct available space info to then" do
            node = Unless.new(
              :condition => @literal_true,
              :then      => node_width_and_to_ruby_mock(
                :width => 80,
                :shift => 0
              ),
              :else      => nil
            )

            node.to_ruby(@context_default)
          end
        end

        describe "for multi-line unless statements" do
          it "emits correct code" do
            @node_without_else_multi.to_ruby(@context_narrow).should == [
              "unless true",
              "  a = 42",
              "  b = 43",
              "  c = 44",
              "end"
            ].join("\n")
          end

          it "passes correct available space info to condition" do
            node = Unless.new(
              :condition => node_width_and_to_ruby_mock(
                :width => 0,
                :shift => 7
              ),
              :then      => @statements,
              :else      => nil
            )

            node.to_ruby(@context_narrow)
          end

          it "passes correct available space info to then" do
            node = Unless.new(
              :condition => @literal_true,
              :then      => node_width_and_to_ruby_mock(
                :width => -2,
                :shift => 0
              ),
              :else      => nil
            )

            node.to_ruby(@context_narrow)
          end
        end
      end

      describe "for unless statements with else" do
        it "emits correct code" do
          @node_with_else.to_ruby(@context_default).should == [
            "unless true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "else",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "passes correct available space info to condition" do
          node = Unless.new(
            :condition => node_to_ruby_mock(:width => 80, :shift => 7),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to then" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => node_to_ruby_mock(:width => 78, :shift => 0),
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to else" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => node_to_ruby_mock(:width => 78, :shift => 0)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      describe "for unless statements without else" do
        describe "for single-line unless statements" do
          it "returns correct value" do
            @node_without_else_single.single_line_width.should == 18
          end
        end

        describe "for multi-line unless statements" do
          it "returns infinity" do
            @node_without_else_multi.single_line_width.should == Float::INFINITY
          end
        end
      end

      describe "for unless statements with else" do
        it "returns infinity" do
          @node_with_else.single_line_width.should == Float::INFINITY
        end
      end
    end
  end

  describe Case, :type => :ruby do
    before :each do
      @node_empty = Case.new(
        :expression => @literal_42,
        :whens      => [],
        :else       => nil
      )
      @node_one_when_without_else = Case.new(
        :expression => @literal_42,
        :whens      => [@when_42],
        :else       => nil
      )
      @node_one_when_with_else = Case.new(
        :expression => @literal_42,
        :whens      => [@when_42],
        :else       => @else
      )
      @node_multiple_whens_without_else = Case.new(
        :expression => @literal_42,
        :whens      => [@when_42, @when_43, @when_44],
        :else       => nil
      )
      @node_multiple_whens_with_else = Case.new(
        :expression => @literal_42,
        :whens      => [@when_42, @when_43, @when_44],
        :else       => @else
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for empty case statements" do
          @node_empty.to_ruby(@context_default).should == [
            "case 42",
            "end"
          ].join("\n")
        end

        it "emits correct code for case statements with one when clause and no else clause" do
          @node_one_when_without_else.to_ruby(@context_default).should == [
            "case 42",
            "  when 42",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for case statements with one when clause and an else clause" do
          @node_one_when_with_else.to_ruby(@context_default).should == [
            "case 42",
            "  when 42",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "  else",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for case statements with multiple when clauses and no else clause" do
          @node_multiple_whens_without_else.to_ruby(@context_default).should == [
            "case 42",
            "  when 42",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "  when 43",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "  when 44",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for case statements with multiple when clauses and an else clause" do
          @node_multiple_whens_with_else.to_ruby(@context_default).should == [
            "case 42",
            "  when 42",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "  when 43",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "  when 44",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "  else",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to expression" do
          node = Case.new(
            :expression => node_to_ruby_mock(:width => 80, :shift => 5),
            :whens      => [],
            :else       => nil
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to whens" do
          node = Case.new(
            :expression => @literal_42,
            :whens      => [node_to_ruby_mock(:width => 78, :shift => 0)],
            :else       => nil
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to else" do
          node = Case.new(
            :expression => @literal_42,
            :whens      => [],
            :else       => node_to_ruby_mock(:width => 78, :shift => 0)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity for empty case statements" do
        @node_empty.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for case statements with one when clause and no else clause" do
        @node_one_when_without_else.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for case statements with one when clause and an else clause" do
        @node_one_when_with_else.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for case statements with multiple when clauses and no else clause" do
        @node_multiple_whens_without_else.single_line_width.should ==
          Float::INFINITY
      end

      it "returns infinity for case statements with multiple when clauses and an else clause" do
        @node_multiple_whens_with_else.single_line_width.should ==
          Float::INFINITY
      end
    end
  end

  describe When, :type => :ruby do
    before :each do
      @node_one_value = When.new(
        :values => [@literal_42],
        :body   => @statements
      )
      @node_multiple_values = When.new(
        :values => [@literal_42, @literal_43, @literal_44],
        :body   => @statements
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for when clauses with one value" do
          @node_one_value.to_ruby(@context_default).should == [
            "when 42",
            "  a = 42",
            "  b = 43",
            "  c = 44"
          ].join("\n")
        end

        it "emits correct code for when clauses with multiple values" do
          @node_multiple_values.to_ruby(@context_default).should == [
            "when 42, 43, 44",
            "  a = 42",
            "  b = 43",
            "  c = 44"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to values" do
          node = When.new(
            :values => [
              node_to_ruby_mock(:width => 80, :shift => 5),
              node_to_ruby_mock(:width => 80, :shift => 7),
              node_to_ruby_mock(:width => 80, :shift => 9)
            ],
            :body   => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to body" do
          node = When.new(
            :values => [@literal_42],
            :body   => node_to_ruby_mock(:width => 78, :shift => 0)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity for when clauses with one value" do
        @node_one_value.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for when clauses with multiple values" do
        @node_multiple_values.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Else, :type => :ruby do
    before :each do
      @node = Else.new(:body => @statements)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == [
            "else",
            "  a = 42",
            "  b = 43",
            "  c = 44"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to body" do
          node = Else.new(:body => node_to_ruby_mock(:width => 78, :shift => 0))

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity" do
        @node.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe While, :type => :ruby do
    before :each do
      @node_common  = While.new(
        :condition => @literal_true,
        :body      => @statements
      )
      @node_wrapper = While.new(:condition  => @literal_true, :body => @begin)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for common while statements" do
          @node_common.to_ruby(@context_default).should == [
            "while true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for while statements wrapping begin...end" do
          @node_wrapper.to_ruby(@context_default).should == [
            "begin",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end while true",
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to condition" do
          node = While.new(
            :condition => node_to_ruby_mock(:width => 80, :shift => 6),
            :body      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to body" do
          node = While.new(
            :condition => @literal_true,
            :body      => node_to_ruby_mock(:width => 78, :shift => 0)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity for common while statements" do
        @node_common.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for while statements wrapping begin...end" do
        @node_wrapper.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Until, :type => :ruby do
    before :each do
      @node_common  = Until.new(
        :condition => @literal_true,
        :body      => @statements
      )
      @node_wrapper = Until.new(:condition  => @literal_true, :body => @begin)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for common until statements" do
          @node_common.to_ruby(@context_default).should == [
            "until true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for until statements wrapping begin...end" do
          @node_wrapper.to_ruby(@context_default).should == [
            "begin",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end until true",
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available space info to condition" do
          node = Until.new(
            :condition => node_to_ruby_mock(:width => 80, :shift => 6),
            :body      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to body" do
          node = Until.new(
            :condition => @literal_true,
            :body      => node_to_ruby_mock(:width => 78, :shift => 0)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns infinity for common unless statements" do
        @node_common.single_line_width.should == Float::INFINITY
      end

      it "returns infinity for unless statements wrapping begin...end" do
        @node_wrapper.single_line_width.should == Float::INFINITY
      end
    end
  end

  describe Break, :type => :ruby do
    before :each do
      @node = Break.new
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == "break"
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node.single_line_width.should == 5
      end
    end
  end

  describe Next, :type => :ruby do
    before :each do
      @node_without_value = Next.new(:value => nil)
      @node_with_value    = Next.new(:value => @literal_42)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for nexts without a value" do
          @node_without_value.to_ruby(@context_default).should == "next"
        end

        it "emits correct code for nexts with a value" do
          @node_with_value.to_ruby(@context_default).should == "next 42"
        end
      end

      describe "formatting" do
        it "passes correct available space info to value" do
          node = Next.new(
            :value => node_to_ruby_mock(:width => 80, :shift => 5)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for nexts without a value" do
        @node_without_value.single_line_width.should == 4
      end

      it "returns correct value for nexts with a value" do
        @node_with_value.single_line_width.should == 7
      end
    end
  end

  describe Return, :type => :ruby do
    before :each do
      @node_without_value = Return.new(:value => nil)
      @node_with_value    = Return.new(:value => @literal_42)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for returns without a value" do
          @node_without_value.to_ruby(@context_default).should == "return"
        end

        it "emits correct code for returns with a value" do
          @node_with_value.to_ruby(@context_default).should == "return 42"
        end
      end

      describe "formatting" do
        it "passes correct available space info to value" do
          node = Return.new(
            :value => node_to_ruby_mock(:width => 80, :shift => 7)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for nexts without a value" do
        @node_without_value.single_line_width.should == 6
      end

      it "returns correct value for nexts with a value" do
        @node_with_value.single_line_width.should == 9
      end
    end
  end

  describe Expressions, :type => :ruby do
    before :each do
      @node_empty    = Expressions.new(:expressions => [])
      @node_one      = Expressions.new(:expressions => [@literal_42])
      @node_multiple = Expressions.new(
        :expressions => [@literal_42, @literal_43, @literal_44]
      )
    end

    describe "#to_ruby" do
      it "emits a single-line expression list when the expression list fits available space and all expressions are single-line" do
        @node_multiple.to_ruby(@context_default).should == "(42; 43; 44)"
      end

      it "emits a multi-line expression list when the expression list doesn't fit available space" do
        @node_multiple.to_ruby(@context_narrow).should == [
          "(",
          "  42;",
          "  43;",
          "  44",
          ")"
        ].join("\n")
      end

      it "emits a multi-line expression list when any expression is multi-line" do
        # Using @statements is nonsense semantically, but it is a convenient
        # multi-line node.
        node1 = Expressions.new(:expressions => [@statements, @literal_43, @literal_44])
        node2 = Expressions.new(:expressions => [@literal_42, @statements, @literal_44])
        node3 = Expressions.new(:expressions => [@literal_42, @literal_43, @statements])

        node1.to_ruby(@context_default).should == [
          "(",
          "  a = 42",
          "  b = 43",
          "  c = 44;",
          "  43;",
          "  44",
          ")"
        ].join("\n")
        node2.to_ruby(@context_default).should == [
          "(",
          "  42;",
          "  a = 42",
          "  b = 43",
          "  c = 44;",
          "  44",
          ")"
        ].join("\n")
        node3.to_ruby(@context_default).should == [
          "(",
          "  42;",
          "  43;",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          ")"
        ].join("\n")
      end

      describe "for single-line expression lists" do
        it "emits correct code for empty expression lists" do
          @node_empty.to_ruby(@context_default).should == "()"
        end

        it "emits correct code for expression lists with one expression" do
          @node_one.to_ruby(@context_default).should == "(42)"
        end

        it "emits correct code for expression lists with multiple expressions" do
          @node_multiple.to_ruby(@context_default).should == "(42; 43; 44)"
        end

        it "passes correct available space info to expressions" do
          node = Expressions.new(
            :expressions => [
              node_width_and_to_ruby_mock(:width => 80, :shift => 1),
              node_width_and_to_ruby_mock(:width => 80, :shift => 3),
              node_width_and_to_ruby_mock(:width => 80, :shift => 5)
            ]
          )

          node.to_ruby(@context_default)
        end
      end

      describe "for multi-line expression lists" do
        it "emits correct code for empty expression lists" do
          @node_empty.to_ruby(@context_narrow).should == "()"
        end

        it "emits correct code for expression lists with one expression" do
          @node_one.to_ruby(@context_narrow).should == [
           "(",
           "  42",
           ")"
          ].join("\n")
        end

        it "emits correct code for expression lists with multiple expressions" do
          @node_multiple.to_ruby(@context_narrow).should == [
           "(",
           "  42;",
           "  43;",
           "  44",
           ")"
          ].join("\n")
        end

        it "passes correct available space info to expressions" do
          node = Expressions.new(
            :expressions => [
              node_width_and_to_ruby_mock(:width => -2, :shift => 0),
              node_width_and_to_ruby_mock(:width => -2, :shift => 0),
              node_width_and_to_ruby_mock(:width => -2, :shift => 0)
            ]
          )

          node.to_ruby(@context_narrow)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for empty expression lists" do
        @node_empty.single_line_width.should == 2
      end

      it "returns correct value for expression lists with one expression" do
        @node_one.single_line_width.should == 4
      end

      it "returns correct value for expression lists with multiple expressions" do
        @node_multiple.single_line_width.should == 12
      end
    end
  end

  describe Assignment, :type => :ruby do
    before :each do
      @node = Assignment.new(:lhs => @variable_a, :rhs => @literal_42)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == "a = 42"
        end
      end

      describe "formatting" do
        it "passes correct available space info to lhs" do
          node = Assignment.new(
            :lhs => node_to_ruby_mock(:width => 80, :shift => 0),
            :rhs => @literal_42
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to rhs" do
          node = Assignment.new(
            :lhs => @variable_a,
            :rhs => node_to_ruby_mock(:width => 80, :shift => 4)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node.single_line_width.should == 6
      end
    end
  end

  describe UnaryOperator, :type => :ruby do
    before :each do
      @node_without_parens = UnaryOperator.new(
        :op         => "+",
        :expression => @literal_42,
      )
      @node_with_parens = UnaryOperator.new(
        :op         => "+",
        :expression => @binary_operator_42_plus_43,
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node_without_parens.to_ruby(@context_default).should == "+42"
        end

        it "encloses operand in parens when needed" do
          @node_with_parens.to_ruby(@context_default).should == "+(42 + 43)"
        end
      end

      describe "formatting" do
        it "passes correct available space info to expression" do
          node = UnaryOperator.new(
            :op         => "+",
            :expression => node_to_ruby_enclosed_mock(
              :width => 80,
              :shift => 1
            ),
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node_without_parens.single_line_width.should == 3
      end

      it "returns correct value when parens are needed" do
        @node_with_parens.single_line_width.should == 10
      end
    end
  end

  describe BinaryOperator, :type => :ruby do
    before :each do
      @node_without_parens = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_42,
        :rhs => @literal_43
      )
      @node_with_parens = BinaryOperator.new(
        :op  => "+",
        :lhs => @binary_operator_42_plus_43,
        :rhs => @binary_operator_44_plus_45
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node_without_parens.to_ruby(@context_default).should == "42 + 43"
        end

        it "encloses operands in parens when needed" do
          @node_with_parens.to_ruby(@context_default).should ==
            "(42 + 43) + (44 + 45)"
        end
      end

      describe "formatting" do
        it "passes correct available space info to lhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => node_to_ruby_enclosed_mock(:width => 80, :shift => 0),
            :rhs => @literal_43
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to rhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @literal_42,
            :rhs => node_to_ruby_enclosed_mock(:width => 80, :shift => 5)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node_without_parens.single_line_width.should == 7
      end

      it "returns correct value when parens are needed" do
        @node_with_parens.single_line_width.should == 21
      end
    end
  end

  describe TernaryOperator, :type => :ruby do
    before :each do
      @node_without_parens = TernaryOperator.new(
        :condition => @literal_true,
        :then      => @literal_42,
        :else      => @literal_43
      )
      @node_with_parens = TernaryOperator.new(
        :condition  => @binary_operator_true_or_false,
        :then       => @binary_operator_42_plus_43,
        :else       => @binary_operator_44_plus_45
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node_without_parens.to_ruby(@context_default).should ==
            "true ? 42 : 43"
        end

        it "encloses operands in parens when needed" do
          @node_with_parens.to_ruby(@context_default).should ==
            "(true || false) ? (42 + 43) : (44 + 45)"
        end
      end

      describe "formatting" do
        it "passes correct available space info to condition" do
          node = TernaryOperator.new(
            :condition => node_to_ruby_enclosed_mock(:width => 80, :shift => 0),
            :then      => @literal_42,
            :else      => @literal_43
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to then" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => node_to_ruby_enclosed_mock(:width => 80, :shift => 7),
            :else      => @literal_43
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to else" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => @literal_42,
            :else      => node_to_ruby_enclosed_mock(
              :width => 80,
              :shift => 12
            ),
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node_without_parens.single_line_width.should == 14
      end

      it "returns correct value when parens are needed" do
        @node_with_parens.single_line_width.should == 39
      end
    end
  end

  describe MethodCall, :type => :ruby do
    before :each do
      @node_without_receiver = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [],
        :block    => nil,
        :parens   => false
      )
      @node_with_receiver = MethodCall.new(
        :receiver => @variable_a,
        :name     => "m",
        :args     => [],
        :block    => nil,
        :parens   => false
      )

      @node_parens_no_args = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [],
        :block    => nil,
        :parens   => true
      )
      @node_parens_one_arg = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [@literal_42],
        :block    => nil,
        :parens   => true
      )
      @node_parens_multiple_args = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [@literal_42, @literal_43, @literal_44],
        :block    => nil,
        :parens   => true
      )
      @node_parens_const = MethodCall.new(
        :receiver => nil,
        :name     => "M",
        :args     => [],
        :block    => nil,
        :parens   => true
      )
      @node_parens_without_block = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [],
        :block    => nil,
        :parens   => true
      )
      @node_parens_with_block = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [],
        :block    => Block.new(:args => [], :statements => @statements),
        :parens   => true
      )

      @node_no_parens_no_args = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [],
        :block    => nil,
        :parens   => false
      )
      @node_no_parens_one_arg = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [@literal_42],
        :block    => nil,
        :parens   => false
      )
      @node_no_parens_multiple_args = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [@literal_42, @literal_43, @literal_44],
        :block    => nil,
        :parens   => false
      )
      @node_no_parens_const = MethodCall.new(
        :receiver => nil,
        :name     => "M",
        :args     => [],
        :block    => nil,
        :parens   => false
      )
      @node_no_parens_without_block = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [],
        :block    => nil,
        :parens   => false
      )
      @node_no_parens_with_block = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [],
        :block    => Block.new(:args => [], :statements => @statements),
        :parens   => false
      )
    end

    describe "#to_ruby" do
      it "emits correct code for method calls without a receiver" do
        @node_without_receiver.to_ruby(@context_default).should == "m"
      end

      it "emits correct code for method calls with a receiver" do
        @node_with_receiver.to_ruby(@context_default).should == "a.m"
      end

      it "passes correct available space info to receiver" do
        node = MethodCall.new(
          :receiver => node_width_and_to_ruby_mock(:width => 80, :shift => 0),
          :name     => "m",
          :args     => [],
          :block    => nil,
          :parens   => false
        )

        node.to_ruby(@context_default)
      end

      describe "on method calls with :parens => true" do
        describe "for single-line method calls" do
          it "emits correct code for method calls with no arguments" do
            @node_parens_no_args.to_ruby(@context_default).should == "m"
          end

          it "emits correct code for method calls with one argument" do
            @node_parens_one_arg.to_ruby(@context_default).should == "m(42)"
          end

          it "emits correct code for method calls with multiple arguments" do
            @node_parens_multiple_args.to_ruby(@context_default).should ==
              "m(42, 43, 44)"
          end

          it "emits correct code for method calls with no receiver, const-like name and no arguments" do
            @node_parens_const.to_ruby(@context_default).should == "M()"
          end

          it "passes correct available space info to args" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [
                node_width_and_to_ruby_mock(:width => 80, :shift => 3),
                node_width_and_to_ruby_mock(:width => 80, :shift => 5),
                node_width_and_to_ruby_mock(:width => 80, :shift => 7)
              ],
              :block    => nil,
              :parens   => false
            )

            node.to_ruby(@context_default)
          end

          it "passes correct available space info to block" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [],
              :block    => node_to_ruby_mock(:width => 80, :shift => 3),
              :parens   => false
            )

            node.to_ruby(@context_default)
          end
        end

        describe "for multi-line method calls" do
          it "emits correct code for method calls with no arguments" do
            @node_parens_no_args.to_ruby(@context_narrow).should == [
              "m(",
              ")"
            ].join("\n")
          end

          it "emits correct code for method calls with one argument" do
            @node_parens_one_arg.to_ruby(@context_narrow).should == [
              "m(",
              "  42",
              ")"
            ].join("\n")
          end

          it "emits correct code for method calls with multiple arguments" do
            @node_parens_multiple_args.to_ruby(@context_narrow).should == [
              "m(",
              "  42,",
              "  43,",
              "  44",
              ")"
            ].join("\n")
          end

          it "emits correct code for method calls with no receiver, const-like name and no arguments" do
            @node_parens_const.to_ruby(@context_narrow).should == [
              "M(",
              ")"
            ].join("\n")
          end

          it "passes correct available space info to args" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [
                node_width_and_to_ruby_mock(:width => -2, :shift => 0),
                node_width_and_to_ruby_mock(:width => -2, :shift => 0),
                node_width_and_to_ruby_mock(:width => -2, :shift => 0)
              ],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby(@context_narrow)
          end

          it "passes correct available space info to block" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [],
              :block    => node_to_ruby_mock(:width => 0, :shift => 1),
              :parens   => true
            )

            node.to_ruby(@context_narrow)
          end
        end

        it "emits correct code for method calls without a block" do
          @node_parens_without_block.to_ruby(@context_default).should == "m"
        end

        it "emits correct code for method calls with a block" do
          @node_parens_with_block.to_ruby(@context_default).should == [
            "m do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "on method calls with :parens => false" do
        it "emits correct code for method calls with no arguments" do
          @node_no_parens_no_args.to_ruby(@context_default).should == "m"
        end

        it "emits correct code for method calls with one argument" do
          @node_no_parens_one_arg.to_ruby(@context_default).should == "m 42"
        end

        it "emits correct code for method calls with multiple arguments" do
          @node_no_parens_multiple_args.to_ruby(@context_default).should == "m 42, 43, 44"
        end

        it "emits correct code for method calls with no receiver, const-like name and no arguments" do
          @node_no_parens_const.to_ruby(@context_default).should == "M()"
        end

        it "emits correct code for method calls without a block" do
          @node_no_parens_without_block.to_ruby(@context_default).should == "m"
        end

        it "emits correct code for method calls with a block" do
          @node_no_parens_with_block.to_ruby(@context_default).should == [
            "m do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "passes correct available space info to args" do
          node = MethodCall.new(
            :receiver => @variable_a,
            :name     => "m",
            :args     => [
              node_width_and_to_ruby_mock(:width => 80, :shift => 3),
              node_width_and_to_ruby_mock(:width => 80, :shift => 5),
              node_width_and_to_ruby_mock(:width => 80, :shift => 7)
            ],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to block" do
          node = MethodCall.new(
            :receiver => @variable_a,
            :name     => "m",
            :args     => [],
            :block    => node_to_ruby_mock(:width => 80, :shift => 3),
            :parens   => false
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for method calls without a receiver" do
        @node_without_receiver.single_line_width.should == 1
      end

      it "returns correct value for method calls with a receiver" do
        @node_with_receiver.single_line_width.should == 3
      end

      describe "on method calls with :parens => true" do
        it "returns correct value for method calls with no arguments" do
          @node_parens_no_args.single_line_width.should == 1
        end

        it "returns correct value for method calls with one argument" do
          @node_parens_one_arg.single_line_width.should == 5
        end

        it "returns correct value for method calls with multiple arguments" do
          @node_parens_multiple_args.single_line_width.should == 13
        end

        it "returns correct value for method calls with no receiver, const-like name and no arguments" do
          @node_parens_const.single_line_width.should == 3
        end

        it "returns correct value for method calls without a block" do
          @node_parens_without_block.single_line_width.should == 1
        end

        it "returns correct value for method calls with a block" do
          @node_parens_with_block.single_line_width.should == 1
        end
      end

      describe "on method calls with :parens => false" do
        it "returns correct value for method calls with no arguments" do
          @node_no_parens_no_args.single_line_width.should == 1
        end

        it "returns correct value for method calls with one argument" do
          @node_no_parens_one_arg.single_line_width.should == 4
        end

        it "returns correct value for method calls with multiple arguments" do
          @node_no_parens_multiple_args.single_line_width.should == 12
        end

        it "returns correct value for method calls with no receiver, const-like name and no arguments" do
          @node_no_parens_const.single_line_width.should == 3
        end

        it "returns correct value for method calls without a block" do
          @node_no_parens_without_block.single_line_width.should == 1
        end

        it "returns correct value for method calls with a block" do
          @node_no_parens_with_block.single_line_width.should == 1
        end
      end
    end
  end

  describe Block, :type => :ruby do
    before :each do
      @node_single_no_args = Block.new(
        :args       => [],
        :statements => @assignment_a_42
      )
      @node_single_one_arg = Block.new(
        :args       => [@variable_a],
        :statements => @assignment_a_42
      )
      @node_single_multiple_args = Block.new(
        :args       => [@variable_a, @variable_b, @variable_c],
        :statements => @assignment_a_42
      )

      @node_multi_no_args = Block.new(
        :args       => [],
        :statements => @statements
      )
      @node_multi_one_arg = Block.new(
        :args       => [@variable_a],
        :statements => @statements
      )
      @node_multi_multiple_args = Block.new(
        :args       => [@variable_a, @variable_b, @variable_c],
        :statements => @statements
      )
    end

    describe "#to_ruby" do
      it "emits a single-line block when the block fits available space and the statments are single-line" do
        node = Block.new(:args => [], :statements => @assignment_a_42)

        node.to_ruby(@context_default).should == "{ a = 42 }"
      end

      it "emits a multi-line block when the block doesn't fit available space" do
        node = Block.new(:args => [], :statements => @assignment_a_42)

        node.to_ruby(@context_narrow).should == [
          "do",
          "  a = 42",
          "end"
        ].join("\n")
      end

      it "emits a multi-line block when the statements are multi-line" do
        node = Block.new(:args => [], :statements => @statements)

        node.to_ruby(@context_default).should == [
          "do",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      describe "for single-line blocks" do
        it "emits correct code for blocks with no arguments" do
          @node_single_no_args.to_ruby(@context_default).should == "{ a = 42 }"
        end

        it "emits correct code for blocks with one argument" do
          @node_single_one_arg.to_ruby(@context_default).should ==
            "{ |a| a = 42 }"
        end

        it "emits correct code for blocks with multiple arguments" do
          @node_single_multiple_args.to_ruby(@context_default).should ==
            "{ |a, b, c| a = 42 }"
        end

        it "passes correct available space info to args" do
          node = Block.new(
            :args       => [
              node_width_and_to_ruby_mock(:width => 80, :shift => 3),
              node_width_and_to_ruby_mock(:width => 80, :shift => 5),
              node_width_and_to_ruby_mock(:width => 80, :shift => 7)
            ],
            :statements => @assignment_a_42
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to statements" do
          node = Block.new(
            :args       => [],
            :statements => node_width_and_to_ruby_mock(
              :width => 80,
              :shift => 2
            )
          )

          node.to_ruby(@context_default)
        end
      end

      describe "for multi-line blocks" do
        it "emits correct code for blocks with no arguments" do
          @node_multi_no_args.to_ruby(@context_narrow).should == [
            "do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for blocks with one argument" do
          @node_multi_one_arg.to_ruby(@context_narrow).should == [
            "do |a|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for blocks with multiple arguments" do
          @node_multi_multiple_args.to_ruby(@context_narrow).should == [
            "do |a, b, c|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "passes correct available space info to args" do
          node = Block.new(
            :args       => [
              node_width_and_to_ruby_mock(:width => 0, :shift => 4),
              node_width_and_to_ruby_mock(:width => 0, :shift => 6),
              node_width_and_to_ruby_mock(:width => 0, :shift => 8)
            ],
            :statements => @statements
          )

          node.to_ruby(@context_narrow)
        end

        it "passes correct available space info to statements" do
          node = Block.new(
            :args       => [],
            :statements => node_width_and_to_ruby_mock(
              :width => -2,
              :shift => 0
            )
          )

          node.to_ruby(@context_narrow)
        end
      end
    end

    describe "#single_line_width" do
      describe "for single-line blocks" do
        it "returns correct value for blocks with no arguments" do
          @node_single_no_args.single_line_width.should == 10
        end

        it "returns correct value for blocks with one argument" do
          @node_single_one_arg.single_line_width.should == 14
        end

        it "returns correct value for blocks with multiple arguments" do
          @node_single_multiple_args.single_line_width.should == 20
        end
      end

      describe "for multi-line blocks" do
        it "returns infinity for blocks with no arguments" do
          @node_multi_no_args.single_line_width.should == Float::INFINITY
        end

        it "returns infinity for blocks with one argument" do
          @node_multi_one_arg.single_line_width.should == Float::INFINITY
        end

        it "returns infinity for blocks with multiple arguments" do
          @node_multi_multiple_args.single_line_width.should == Float::INFINITY
        end
      end
    end
  end

  describe ConstAccess, :type => :ruby do
    before :each do
      @node_without_receiver = ConstAccess.new(:receiver => nil, :name => "C")
      @node_with_receiver    = ConstAccess.new(
        :receiver => @variable_a,
        :name     => "C"
      )
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for const accesses without a receiver" do
          @node_without_receiver.to_ruby(@context_default).should == "C"
        end

        it "emits correct code for const accesses with a receiver" do
          @node_with_receiver.to_ruby(@context_default).should == "a::C"
        end
      end

      describe "formatting" do
        it "passes correct available space info to statements" do
          node = ConstAccess.new(
            :receiver => node_to_ruby_mock(:width => 80, :shift => 0),
            :name     => "C"
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for const accesses without a receiver" do
        @node_without_receiver.single_line_width.should == 1
      end

      it "returns correct value for const accesses with a receiver" do
        @node_with_receiver.single_line_width.should == 4
      end
    end
  end

  describe Variable, :type => :ruby do
    before :each do
      @node = Variable.new(:name => "a")
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == "a"
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node.single_line_width.should == 1
      end
    end
  end

  describe Self, :type => :ruby do
    before :each do
      @node = Self.new
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          @node.to_ruby(@context_default).should == "self"
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node.single_line_width.should == 4
      end
    end
  end

  describe Literal, :type => :ruby do
    before :each do
      @node_nil     = Literal.new(:value => nil)
      @node_true    = Literal.new(:value => true)
      @node_false   = Literal.new(:value => false)
      @node_integer = Literal.new(:value => 42)
      @node_float   = Literal.new(:value => 42.0)
      @node_symbol  = Literal.new(:value => :abcd)
      @node_string  = Literal.new(:value => "abcd")
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for nil literals" do
          @node_nil.to_ruby(@context_default).should == "nil"
        end

        it "emits correct code for true literals" do
          @node_true.to_ruby(@context_default).should == "true"
        end

        it "emits correct code for false literals" do
          @node_false.to_ruby(@context_default).should == "false"
        end

        it "emits correct code for integer literals" do
          @node_integer.to_ruby(@context_default).should == "42"
        end

        it "emits correct code for float literals" do
          @node_float.to_ruby(@context_default).should == "42.0"
        end

        it "emits correct code for symbol literals" do
          @node_symbol.to_ruby(@context_default).should == ":abcd"
        end

        it "emits correct code for string literals" do
          @node_string.to_ruby(@context_default).should == "\"abcd\""
        end
      end
    end

    describe "#single_line_width" do
      it "emits correct code for nil literals" do
        @node_nil.single_line_width.should == 3
      end

      it "emits correct code for true literals" do
        @node_true.single_line_width.should == 4
      end

      it "emits correct code for false literals" do
        @node_false.single_line_width.should == 5
      end

      it "emits correct code for integer literals" do
        @node_integer.single_line_width.should == 2
      end

      it "emits correct code for float literals" do
        @node_float.single_line_width.should == 4
      end

      it "emits correct code for symbol literals" do
        @node_symbol.single_line_width.should == 5
      end

      it "emits correct code for string literals" do
        @node_string.single_line_width.should == 6
      end
    end
  end

  describe Array, :type => :ruby do
    before :each do
      @node_empty    = Array.new(:elements => [])
      @node_one      = Array.new(:elements => [@literal_42])
      @node_multiple = Array.new(
        :elements => [@literal_42, @literal_43, @literal_44]
      )
    end

    describe "#to_ruby" do
      it "emits a single-line array when the array fits available space and all elements are single-line" do
        @node_multiple.to_ruby(@context_default).should == "[42, 43, 44]"
      end

      it "emits a multi-line array when the array doesn't fit available space" do
        @node_multiple.to_ruby(@context_narrow).should == [
          "[",
          "  42,",
          "  43,",
          "  44",
          "]"
        ].join("\n")
      end

      it "emits a multi-line array when any element is multi-line" do
        # Using @statements is nonsense semantically, but it is a convenient
        # multi-line node.
        node1 = Array.new(:elements => [@statements, @literal_43, @literal_44])
        node2 = Array.new(:elements => [@literal_42, @statements, @literal_44])
        node3 = Array.new(:elements => [@literal_42, @literal_43, @statements])

        node1.to_ruby(@context_default).should == [
          "[",
          "  a = 42",
          "  b = 43",
          "  c = 44,",
          "  43,",
          "  44",
          "]"
        ].join("\n")
        node2.to_ruby(@context_default).should == [
          "[",
          "  42,",
          "  a = 42",
          "  b = 43",
          "  c = 44,",
          "  44",
          "]"
        ].join("\n")
        node3.to_ruby(@context_default).should == [
          "[",
          "  42,",
          "  43,",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "]"
        ].join("\n")
      end

      describe "for single-line arrays" do
        it "emits correct code for empty arrays" do
          @node_empty.to_ruby(@context_default).should == "[]"
        end

        it "emits correct code for arrays with one element" do
          @node_one.to_ruby(@context_default).should == "[42]"
        end

        it "emits correct code for arrays with multiple elements" do
          @node_multiple.to_ruby(@context_default).should == "[42, 43, 44]"
        end

        it "passes correct available space info to elements" do
          node = Array.new(
            :elements => [
              node_width_and_to_ruby_mock(:width => 80, :shift => 1),
              node_width_and_to_ruby_mock(:width => 80, :shift => 3),
              node_width_and_to_ruby_mock(:width => 80, :shift => 5)
            ]
          )

          node.to_ruby(@context_default)
        end
      end

      describe "for multi-line arrays" do
        it "emits correct code for empty arrays" do
          @node_empty.to_ruby(@context_narrow).should == "[]"
        end

        it "emits correct code for arrays with one element" do
          @node_one.to_ruby(@context_narrow).should == [
           "[",
           "  42",
           "]"
          ].join("\n")
        end

        it "emits correct code for arrays with multiple elements" do
          @node_multiple.to_ruby(@context_narrow).should == [
           "[",
           "  42,",
           "  43,",
           "  44",
           "]"
          ].join("\n")
        end

        it "passes correct available space info to elements" do
          node = Array.new(
            :elements => [
              node_width_and_to_ruby_mock(:width => -2, :shift => 0),
              node_width_and_to_ruby_mock(:width => -2, :shift => 0),
              node_width_and_to_ruby_mock(:width => -2, :shift => 0)
            ]
          )

          node.to_ruby(@context_narrow)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for empty arrays" do
        @node_empty.single_line_width.should == 2
      end

      it "returns correct value for arrays with one element" do
        @node_one.single_line_width.should == 4
      end

      it "returns correct value for arrays with multiple elements" do
        @node_multiple.single_line_width.should == 12
      end
    end
  end

  describe Hash, :type => :ruby do
    before :each do
      @node_empty = Hash.new(:entries => [])
      @node_one   = Hash.new(:entries => [@hash_entry_a_42])
      @node_multiple = Hash.new(
        :entries => [@hash_entry_a_42, @hash_entry_b_43, @hash_entry_c_44]
      )
    end

    describe "#to_ruby" do
      it "emits a single-line hash when the hash fits available space and all entries are single-line" do
        @node_multiple.to_ruby(@context_default).should ==
          "{ :a => 42, :b => 43, :c => 44 }"
      end

      it "emits a multi-line hash when the hash doesn't fit available space" do
        @node_multiple.to_ruby(@context_narrow).should == [
          "{",
          "  :a => 42,",
          "  :b => 43,",
          "  :c => 44",
          "}"
        ].join("\n")
      end

      it "emits a multi-line hash when any entry is multi-line" do
        # Using @statements is nonsense semantically, but it is a convenient
        # multi-line node.
        node1 = Hash.new(
          :entries => [
            @hash_entry_a_statements,
            @hash_entry_b_43,
            @hash_entry_c_44
          ]
        )
        node2 = Hash.new(
          :entries => [
            @hash_entry_a_42,
            @hash_entry_b_statements,
            @hash_entry_c_44
          ]
        )
        node3 = Hash.new(
          :entries => [
            @hash_entry_a_42,
            @hash_entry_b_43,
            @hash_entry_c_statements
          ]
        )

        node1.to_ruby(@context_default).should == [
          "{",
          "  :a => a = 42",
          "  b = 43",
          "  c = 44,",
          "  :b => 43,",
          "  :c => 44",
          "}"
        ].join("\n")
        node2.to_ruby(@context_default).should == [
          "{",
          "  :a => 42,",
          "  :b => a = 42",
          "  b = 43",
          "  c = 44,",
          "  :c => 44",
          "}"
        ].join("\n")
        node3.to_ruby(@context_default).should == [
          "{",
          "  :a => 42,",
          "  :b => 43,",
          "  :c => a = 42",
          "  b = 43",
          "  c = 44",
          "}"
        ].join("\n")
      end

      describe "for single-line hashes" do
        it "emits correct code for empty hashes" do
          @node_empty.to_ruby(@context_default).should == "{}"
        end

        it "emits correct code for hashes with one entry" do
          @node_one.to_ruby(@context_default).should == "{ :a => 42 }"
        end

        it "emits correct code for hashes with multiple entries" do
          @node_multiple.to_ruby(@context_default).should ==
            "{ :a => 42, :b => 43, :c => 44 }"
        end

        it "passes correct available space info to entries" do
          node = Hash.new(
            :entries => [
              node_width_and_to_ruby_mock(:width => 80, :shift => 2),
              node_width_and_to_ruby_mock(:width => 80, :shift => 4),
              node_width_and_to_ruby_mock(:width => 80, :shift => 6)
            ]
          )

          node.to_ruby(@context_default)
        end
      end

      describe "for multi-line hashes" do
        it "emits correct code for empty hashes" do
          @node_empty.to_ruby(@context_narrow).should == "{}"
        end

        it "emits correct code for hashes with one entry" do
          @node_one.to_ruby(@context_narrow).should == [
           "{",
           "  :a => 42",
           "}"
          ].join("\n")
        end

        it "emits correct code for hashes with multiple entries" do
          @node_multiple.to_ruby(@context_narrow).should == [
           "{",
           "  :a => 42,",
           "  :b => 43,",
           "  :c => 44",
           "}"
          ].join("\n")
        end

        it "aligns arrows" do
          node = Hash.new(
            :entries => [
              @hash_entry_a_42,
              @hash_entry_aa_43,
              @hash_entry_aaa_44
            ]
          )

          node.to_ruby(@context_narrow).should == [
           "{",
           "  :a   => 42,",
           "  :aa  => 43,",
           "  :aaa => 44",
           "}"
          ].join("\n")
        end

        it "passes correct available space info to entries" do
          node1 = node_width_and_to_ruby_mock(:width => -2, :shift => 0)
          node2 = node_width_and_to_ruby_mock(:width => -2, :shift => 0)
          node3 = node_width_and_to_ruby_mock(:width => -2, :shift => 0)

          node1.should_receive(:key_width) do |context|
            context.width.should == -2
            context.shift.should == 0
            0
          end
          node2.should_receive(:key_width) do |context|
            context.width.should == -2
            context.shift.should == 0
            0
          end
          node3.should_receive(:key_width) do |context|
            context.width.should == -2
            context.shift.should == 0
            0
          end

          node = Hash.new(:entries => [node1, node2, node3])

          node.to_ruby(@context_narrow)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value for empty hashes" do
        @node_empty.single_line_width.should == 2
      end

      it "returns correct value for hashes with one entry" do
        @node_one.single_line_width.should == 12
      end

      it "returns correct value for hashes with multiple entries" do
        @node_multiple.single_line_width.should == 32
      end
    end
  end

  describe HashEntry, :type => :ruby do
    before :each do
      @node = HashEntry.new(:key => @literal_a, :value => @literal_42)
    end

    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code with no max_key_width set" do
          @node.to_ruby(@context_default).should == ":a => 42"
        end

        it "emits correct code with max_key_width set" do
          @node.to_ruby(@context_max_key_width).should == ":a   => 42"
        end
      end

      describe "formatting" do
        it "passes correct available space info to key" do
          node = HashEntry.new(
            :key   => node_to_ruby_mock(:width => 80, :shift => 0),
            :value => @literal_42
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to value" do
          node = HashEntry.new(
            :key   => @literal_a,
            :value => node_to_ruby_mock(:width => 80, :shift => 6)
          )

          node.to_ruby(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node.single_line_width.should == 8
      end
    end
  end
end
