# encoding: utf-8

require "spec_helper"

def node_width_mock(width)
  mock = double
  mock.should_receive(:to_ruby) do |context|
    context.width.should == width
    ""
  end
  mock
end

def node_width_mock_enclosed(width)
  mock = double
  mock.should_receive(:to_ruby_enclosed) do |context|
    context.width.should == width
    ""
  end
  mock
end

module Y2R::AST::Ruby
  RSpec.configure do |c|
    c.before :each, :type => :ruby do
      @literal_true  = Literal.new(:value => true)
      @literal_false = Literal.new(:value => false)

      @literal_a = Literal.new(:value => :a)
      @literal_b = Literal.new(:value => :b)
      @literal_c = Literal.new(:value => :c)

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

      @begin = Begin.new(:statements => @statements)

      @when_42 = When.new(:values => [@literal_42], :body => @statements)
      @when_43 = When.new(:values => [@literal_43], :body => @statements)
      @when_44 = When.new(:values => [@literal_44], :body => @statements)

      @else = Else.new(:body => @statements)

      @context_default = Context.new(:width => 80)
    end
  end

  describe Node, :type => :ruby do
    describe "#to_ruby_enclosed" do
      class NotEnclosedNode < Node
        def enclose?
          false
        end

        def to_ruby(context)
          "ruby"
        end
      end

      class EnclosedNode < Node
        def enclose?
          true
        end

        def to_ruby(context)
          "ruby"
        end
      end

      describe "basics" do
        describe "on nodes where #enclosed? returns false" do
          it "returns code that is not enclosed in parens" do
            node = NotEnclosedNode.new

            node.to_ruby_enclosed(@context_default).should == "ruby"
          end
        end

        describe "on nodes where #enclosed? returns true" do
          it "returns code that is enclosed in parens" do
            node = EnclosedNode.new

            node.to_ruby_enclosed(@context_default).should == "(ruby)"
          end
        end
      end

      describe "formatting" do
        describe "on nodes where #enclosed? returns false" do
          it "passes correct available width to #to_ruby" do
            node = NotEnclosedNode.new
            node.should_receive(:to_ruby) do |context|
              context.width.should == 80
              "ruby"
            end

            node.to_ruby_enclosed(@context_default)
          end
        end

        describe "on nodes where #enclosed? returns true" do
          it "passes correct available width to #to_ruby" do
            node = EnclosedNode.new
            node.should_receive(:to_ruby) do |context|
              context.width.should == 79
              "ruby"
            end

            node.to_ruby_enclosed(@context_default)
          end
        end
      end
    end
  end

  describe Program, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code without a comment" do
          node = Program.new(:statements => @statements, :comment => nil)

          node.to_ruby(@context_default).should == [
            "# encoding: utf-8",
            "",
            "a = 42",
            "b = 43",
            "c = 44"
          ].join("\n")
        end

        it "emits correct code with a comment" do
          node = Program.new(:statements => @statements, :comment => "comment")

          node.to_ruby(@context_default).should == [
            "# encoding: utf-8",
            "# comment",
            "",
            "a = 42",
            "b = 43",
            "c = 44"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to statements" do
          node = Program.new(
            :statements => node_width_mock(80),
            :comment    => nil
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Class, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = Class.new(
            :name       => "C",
            :superclass => @variable_S,
            :statements => @statements
          )

          node.to_ruby(@context_default).should == [
            "class C < S",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to superclass" do
          node = Class.new(
            :name       => "C",
            :superclass => node_width_mock(70),
            :statements => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to statements" do
          node = Class.new(
            :name       => "C",
            :superclass => @variable_S,
            :statements => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Module, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = Module.new(:name  => "M", :statements => @statements)

          node.to_ruby(@context_default).should == [
            "module M",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to statements" do
          node = Module.new(:name => "M", :statements => node_width_mock(78))

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Def, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for method definitions with no arguments" do
          node = Def.new(:name => "m", :args => [], :statements => @statements)

          node.to_ruby(@context_default).should == [
            "def m",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for method definitions with one argument" do
          node = Def.new(
            :name       => "m",
            :args       => [@variable_a],
            :statements => @statements
          )

          node.to_ruby(@context_default).should == [
            "def m(a)",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for method definitions with multiple arguments" do
          node = Def.new(
            :name       => "m",
            :args       => [@variable_a, @variable_b, @variable_c],
            :statements => @statements
          )

          node.to_ruby(@context_default).should == [
            "def m(a, b, c)",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to args" do
          node = Def.new(
            :name       => "m",
            :args       => [
              node_width_mock(74),
              node_width_mock(72),
              node_width_mock(70)
            ],
            :statements => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to statements" do
          node = Def.new(
            :name       => "m",
            :args       => [],
            :statements => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Statements, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for statement lists with no statements" do
          node = Statements.new(:statements => [])

          node.to_ruby(@context_default).should == ""
        end

        it "emits correct code for statement lists with one statement" do
          node = Statements.new(:statements => [@assignment_a_42])

          node.to_ruby(@context_default).should == "a = 42"
        end

        it "emits correct code for statement lists with multiple statements" do
          node = Statements.new(
            :statements => [
              @assignment_a_42,
              @assignment_b_43,
              @assignment_c_44
            ]
          )

          node.to_ruby(@context_default).should == [
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
      end

      describe "formatting" do
        it "passes correct available width to statements" do
          node = Statements.new(:statements => [node_width_mock(80)])

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Begin, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = Begin.new(:statements => @statements)

          node.to_ruby(@context_default).should == [
            "begin",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to statements" do
          node = Begin.new(:statements => node_width_mock(78))

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe If, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for if statements without else" do
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

        it "emits correct code for if statements with else" do
          node = If.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby(@context_default).should == [
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
      end

      describe "formatting" do
        it "passes correct available width to condition" do
          node = If.new(
            :condition => node_width_mock(77),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to then" do
          node = If.new(
            :condition => @literal_true,
            :then      => node_width_mock(78),
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to else" do
          node = If.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Unless, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for unless statements without else" do
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

        it "emits correct code for unless statements with else" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby(@context_default).should == [
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
      end

      describe "formatting" do
        it "passes correct available width to condition" do
          node = Unless.new(
            :condition => node_width_mock(73),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to then" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => node_width_mock(78),
            :else      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to else" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Case, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for empty case statements" do
          node = Case.new(
            :expression => @literal_42,
            :whens      => [],
            :else       => nil
          )

          node.to_ruby(@context_default).should == [
            "case 42",
            "end"
          ].join("\n")
        end

        it "emits correct code for case statements with one when clause and no else clause" do
          node = Case.new(
            :expression => @literal_42,
            :whens      => [@when_42],
            :else       => nil
          )

          node.to_ruby(@context_default).should == [
            "case 42",
            "  when 42",
            "    a = 42",
            "    b = 43",
            "    c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for case statements with one when clause and an else clause" do
          node = Case.new(
            :expression => @literal_42,
            :whens      => [@when_42],
            :else       => @else
          )

          node.to_ruby(@context_default).should == [
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
          node = Case.new(
            :expression => @literal_42,
            :whens      => [@when_42, @when_43, @when_44],
            :else       => nil
          )

          node.to_ruby(@context_default).should == [
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
          node = Case.new(
            :expression => @literal_42,
            :whens      => [@when_42, @when_43, @when_44],
            :else       => @else
          )

          node.to_ruby(@context_default).should == [
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
        it "passes correct available width to expression" do
          node = Case.new(
            :expression => node_width_mock(75),
            :whens      => [],
            :else       => nil
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to whens" do
          node = Case.new(
            :expression => @literal_42,
            :whens      => [node_width_mock(78)],
            :else       => nil
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to else" do
          node = Case.new(
            :expression => @literal_42,
            :whens      => [],
            :else       => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe When, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for when clauses with one value" do
          node = When.new(:values => [@literal_42], :body => @statements)

          node.to_ruby(@context_default).should == [
            "when 42",
            "  a = 42",
            "  b = 43",
            "  c = 44"
          ].join("\n")
        end

        it "emits correct code for when clauses with multiple values" do
          node = When.new(
            :values => [@literal_42, @literal_43, @literal_44],
            :body   => @statements
          )

          node.to_ruby(@context_default).should == [
            "when 42, 43, 44",
            "  a = 42",
            "  b = 43",
            "  c = 44"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to values" do
          node = When.new(
            :values => [
              node_width_mock(75),
              node_width_mock(73),
              node_width_mock(71)
            ],
            :body   => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to body" do
          node = When.new(
            :values => [@literal_42],
            :body   => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Else, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = Else.new(:body => @statements)

          node.to_ruby(@context_default).should == [
            "else",
            "  a = 42",
            "  b = 43",
            "  c = 44"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to body" do
          node = Else.new(:body => node_width_mock(78))

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe While, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for common while statements" do
          node = While.new(:condition => @literal_true, :body => @statements)

          node.to_ruby(@context_default).should == [
            "while true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for while statements wrapping begin...end" do
          node = While.new(:condition  => @literal_true, :body => @begin)

          node.to_ruby(@context_default).should == [
            "begin",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end while true",
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to condition" do
          node = While.new(
            :condition => node_width_mock(74),
            :body      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to body" do
          node = While.new(
            :condition => @literal_true,
            :body      => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Until, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for common until statements" do
          node = Until.new(:condition => @literal_true, :body => @statements)

          node.to_ruby(@context_default).should == [
            "until true",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        it "emits correct code for until statements wrapping begin...end" do
          node = Until.new(:condition  => @literal_true, :body => @begin)

          node.to_ruby(@context_default).should == [
            "begin",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end until true",
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to condition" do
          node = Until.new(
            :condition => node_width_mock(74),
            :body      => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to body" do
          node = Until.new(
            :condition => @literal_true,
            :body      => node_width_mock(78)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Break, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = Break.new

          node.to_ruby(@context_default).should == "break"
        end
      end
    end
  end

  describe Next, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for nexts without a value" do
          node = Next.new(:value => nil)

          node.to_ruby(@context_default).should == "next"
        end

        it "emits correct code for nexts with a value" do
          node = Next.new(:value => @literal_42)

          node.to_ruby(@context_default).should == "next 42"
        end
      end

      describe "formatting" do
        it "passes correct available width to value" do
          node = Next.new(:value => node_width_mock(75))

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Return, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for returns without a value" do
          node = Return.new(:value => nil)

          node.to_ruby(@context_default).should == "return"
        end

        it "emits correct code for returns with a value" do
          node = Return.new(:value => @literal_42)

          node.to_ruby(@context_default).should == "return 42"
        end
      end

      describe "formatting" do
        it "passes correct available width to value" do
          node = Return.new(:value => node_width_mock(73))

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Expressions, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for expression lists with no expressions" do
          node = Expressions.new(:expressions => [])

          node.to_ruby(@context_default).should == "()"
        end

        it "emits correct code for expression lists with one expression" do
          node = Expressions.new(:expressions => [@literal_42])

          node.to_ruby(@context_default).should == "(42)"
        end

        it "emits correct code for expression lists with multiple expressions" do
          node = Expressions.new(
            :expressions => [@literal_42, @literal_43, @literal_44]
          )

          node.to_ruby(@context_default).should == "(42; 43; 44)"
        end
      end

      describe "formatting" do
        it "passes correct available width to expressions" do
          node = Expressions.new(
            :expressions => [
              node_width_mock(79),
              node_width_mock(77),
              node_width_mock(75)
            ]
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Assignment, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        describe "when assigning from a non-variable" do
          it "emits correct code" do
            node = Assignment.new(:lhs => @variable_a, :rhs => @literal_42)

            node.to_ruby(@context_default).should == "a = 42"
          end
        end

        describe "when assigning from a variable" do
          it "emits correct code" do
            node = Assignment.new(:lhs => @variable_a, :rhs => @variable_b)

            node.to_ruby(@context_default).should == "a = deep_copy(b)"
          end
        end
      end

      describe "formatting" do
        it "passes correct available width to lhs" do
          node = Assignment.new(
            :lhs => node_width_mock(80),
            :rhs => @literal_42
          )

          node.to_ruby(@context_default)
        end

        describe "when assigning from a variable" do
          it "passes correct available width to rhs" do
            rhs = Variable.new(:name => "a")
            rhs.should_receive(:to_ruby) do |context|
              context.width.should == 66
              ""
            end

            node = Assignment.new(:lhs => @variable_a, :rhs => rhs)

            node.to_ruby(@context_default)
          end
        end

        describe "when assigning from a non-variable" do
          it "passes correct available width to rhs" do
            node = Assignment.new(
              :lhs => @variable_a,
              :rhs => node_width_mock(76)
            )

            node.to_ruby(@context_default)
          end
        end
      end
    end
  end

  describe UnaryOperator, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = UnaryOperator.new(
            :op         => "+",
            :expression => @literal_42,
          )

          node.to_ruby(@context_default).should == "+42"
        end

        it "encloses operand in parens when needed" do
          node = UnaryOperator.new(
            :op         => "+",
            :expression => @binary_operator_42_plus_43,
          )

          node.to_ruby(@context_default).should == "+(42 + 43)"
        end
      end

      describe "formatting" do
        it "passes correct available width to expression" do
          node = UnaryOperator.new(
            :op         => "+",
            :expression => node_width_mock_enclosed(79),
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe BinaryOperator, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @literal_42,
            :rhs => @literal_43
          )

          node.to_ruby(@context_default).should == "42 + 43"
        end

        it "encloses operands in parens when needed" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @binary_operator_42_plus_43,
            :rhs => @binary_operator_44_plus_45
          )

          node.to_ruby(@context_default).should == "(42 + 43) + (44 + 45)"
        end
      end

      describe "formatting" do
        it "passes correct available width to lhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => node_width_mock_enclosed(80),
            :rhs => @literal_43
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to rhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @literal_42,
            :rhs => node_width_mock_enclosed(75)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe TernaryOperator, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => @literal_42,
            :else      => @literal_43
          )

          node.to_ruby(@context_default).should == "true ? 42 : 43"
        end

        it "encloses operands in parens when needed" do
          node = TernaryOperator.new(
            :condition  => @binary_operator_true_or_false,
            :then       => @binary_operator_42_plus_43,
            :else       => @binary_operator_44_plus_45
          )

          node.to_ruby(@context_default).should ==
            "(true || false) ? (42 + 43) : (44 + 45)"
        end
      end

      describe "formatting" do
        it "passes correct available width to condition" do
          node = TernaryOperator.new(
            :condition => node_width_mock_enclosed(80),
            :then      => @literal_42,
            :else      => @literal_43
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to then" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => node_width_mock_enclosed(73),
            :else      => @literal_43
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to else" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => @literal_42,
            :else      => node_width_mock_enclosed(68)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe MethodCall, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for method calls without a receiver" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "m",
            :args     => [],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby(@context_default).should == "m"
        end

        it "emits correct code for method calls with a receiver" do
          node = MethodCall.new(
            :receiver => @variable_a,
            :name     => "m",
            :args     => [],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby(@context_default).should == "a.m"
        end

        describe "on method calls with :parens => true" do
          it "emits correct code for method calls with no arguments" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "m",
              :args     => [],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby(@context_default).should == "m"
          end

          it "emits correct code for method calls with one argument" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "m",
              :args     => [@literal_42],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby(@context_default).should == "m(42)"
          end

          it "emits correct code for method calls with multiple arguments" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "m",
              :args     => [@literal_42, @literal_43, @literal_44],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby(@context_default).should == "m(42, 43, 44)"
          end

          it "emits correct code for method calls with no receiver, const-like name and no arguments" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "M",
              :args     => [],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby(@context_default).should == "M()"
          end
        end

        describe "on method calls with :parens => false" do
          it "emits correct code for method calls with no arguments" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "m",
              :args     => [],
              :block    => nil,
              :parens   => false
            )

            node.to_ruby(@context_default).should == "m"
          end

          it "emits correct code for method calls with one argument" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "m",
              :args     => [@literal_42],
              :block    => nil,
              :parens   => false
            )

            node.to_ruby(@context_default).should == "m 42"
          end

          it "emits correct code for method calls with multiple arguments" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "m",
              :args     => [@literal_42, @literal_43, @literal_44],
              :block    => nil,
              :parens   => false
            )

            node.to_ruby(@context_default).should == "m 42, 43, 44"
          end

          it "emits correct code for method calls with no receiver, const-like name and no arguments" do
            node = MethodCall.new(
              :receiver => nil,
              :name     => "M",
              :args     => [],
              :block    => nil,
              :parens   => false
            )

            node.to_ruby(@context_default).should == "M()"
          end
        end

        it "emits correct code for method calls without a block" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "m",
            :args     => [],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby(@context_default).should == "m"
        end

        it "emits correct code for method calls with a block" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "m",
            :args     => [],
            :block    => Block.new(:args => [], :statements => @statements),
            :parens   => false
          )

          node.to_ruby(@context_default).should == [
            "m {",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")
        end
      end
    end
  end

  describe Block, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for blocks with no arguments" do
          node = Block.new(:args => [], :statements => @statements)

          node.to_ruby(@context_default).should == [
            "{",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")
        end

        it "emits correct code for blocks with one argument" do
          node = Block.new(:args => [@variable_a], :statements => @statements)

          node.to_ruby(@context_default).should == [
            "{ |a|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")
        end

        it "emits correct code for blocks with multiple arguments" do
          node = Block.new(
            :args       => [@variable_a, @variable_b, @variable_c],
            :statements => @statements
          )

          node.to_ruby(@context_default).should == [
            "{ |a, b, c|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")
        end
      end

      describe "formatting" do
        it "passes correct available width to args" do
          node = Block.new(
            :args       => [
              node_width_mock(77),
              node_width_mock(75),
              node_width_mock(73)
            ],
            :statements => @statements
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to statements" do
          node = Block.new(:args => [], :statements => node_width_mock(78))

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe ConstAccess, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for const accesses without a receiver" do
          node = ConstAccess.new(:receiver => nil, :name => "C")

          node.to_ruby(@context_default).should == "C"
        end

        it "emits correct code for const accesses with a receiver" do
          node = ConstAccess.new(:receiver => @variable_a, :name => "C")

          node.to_ruby(@context_default).should == "a::C"
        end
      end

      describe "formatting" do
        it "passes correct available width to statements" do
          node = ConstAccess.new(
            :receiver => node_width_mock(80),
            :name     => "C"
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Variable, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = Variable.new(:name => "a")

          node.to_ruby(@context_default).should == "a"
        end
      end
    end
  end

  describe Self, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = Self.new

          node.to_ruby(@context_default).should == "self"
        end
      end
    end
  end

  describe Literal, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for nil literals" do
          node = Literal.new(:value => nil)

          node.to_ruby(@context_default).should == "nil"
        end

        it "emits correct code for true literals" do
          node = Literal.new(:value => true)

          node.to_ruby(@context_default).should == "true"
        end

        it "emits correct code for false literals" do
          node = Literal.new(:value => false)

          node.to_ruby(@context_default).should == "false"
        end

        it "emits correct code for integer literals" do
          node = Literal.new(:value => 42)

          node.to_ruby(@context_default).should == "42"
        end

        it "emits correct code for float literals" do
          node = Literal.new(:value => 42.0)

          node.to_ruby(@context_default).should == "42.0"
        end

        it "emits correct code for symbol literals" do
          node = Literal.new(:value => :abcd)

          node.to_ruby(@context_default).should == ":abcd"
        end

        it "emits correct code for string literals" do
          node = Literal.new(:value => "abcd")

          node.to_ruby(@context_default).should == "\"abcd\""
        end
      end
    end
  end

  describe Array, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for empty arrays" do
          node = Array.new(:elements => [])

          node.to_ruby(@context_default).should == "[]"
        end

        it "emits correct code for arrays with one element" do
          node = Array.new(:elements => [@literal_42])

          node.to_ruby(@context_default).should == "[42]"
        end

        it "emits correct code for arrays with multiple elements" do
          node = Array.new(
            :elements => [@literal_42, @literal_43, @literal_44]
          )

          node.to_ruby(@context_default).should == "[42, 43, 44]"
        end
      end

      describe "formatting" do
        it "passes correct available width to elements" do
          node = Array.new(
            :elements => [
              node_width_mock(79),
              node_width_mock(77),
              node_width_mock(75)
            ]
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe Hash, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code for empty hashes" do
          node = Hash.new(:entries => [])

          node.to_ruby(@context_default).should == "{}"
        end

        it "emits correct code for hashes with one entry" do
          node = Hash.new(
            :entries => [
              HashEntry.new(:key => @literal_a, :value => @literal_42)
            ]
          )

          node.to_ruby(@context_default).should == "{ :a => 42 }"
        end

        it "emits correct code for hashes with multiple entries" do
          node = Hash.new(
            :entries => [
              HashEntry.new(:key => @literal_a, :value => @literal_42),
              HashEntry.new(:key => @literal_b, :value => @literal_43),
              HashEntry.new(:key => @literal_c, :value => @literal_44)
            ]
          )

          node.to_ruby(@context_default).should ==
            "{ :a => 42, :b => 43, :c => 44 }"
        end
      end

      describe "formatting" do
        it "passes correct available width to entries" do
          node = Hash.new(
            :entries => [
              node_width_mock(78),
              node_width_mock(76),
              node_width_mock(74)
            ]
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end

  describe HashEntry, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code" do
          node = HashEntry.new(:key => @literal_a, :value => @literal_42)

          node.to_ruby(@context_default).should == ":a => 42"
        end
      end

      describe "formatting" do
        it "passes correct available width to key" do
          node = HashEntry.new(
            :key   => node_width_mock_enclosed(80),
            :value => @literal_42
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available width to value" do
          node = HashEntry.new(
            :key   => @literal_a,
            :value => node_width_mock_enclosed(74)
          )

          node.to_ruby(@context_default)
        end
      end
    end
  end
end
