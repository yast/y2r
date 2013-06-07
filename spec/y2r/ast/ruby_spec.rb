# encoding: utf-8

require "spec_helper"

def node_to_ruby_mock(*expected_contexts)
  mock = double

  expected_contexts.each do |expected_context|
    mock.should_receive(:to_ruby) do |context|
      expected_context.each_pair do |key, value|
        context.send(key).should == value
      end
      ""
    end
  end

  mock
end

def node_to_ruby_enclosed_mock(*expected_contexts)
  mock = double

  expected_contexts.each do |expected_context|
    mock.should_receive(:to_ruby_enclosed) do |context|
      expected_context.each_pair do |key, value|
        context.send(key).should == value
      end
      ""
    end
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

      @context_default       = Context.new(:width => 80, :shift => 0)
      @context_narrow        = Context.new(:width => 0, :shift => 0)
      @context_max_key_width = Context.new(
        :width         => 0,
        :shift         => 0,
        :max_key_width => 4
      )
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
          it "passes correct available space info to #to_ruby" do
            node = NotEnclosedNode.new
            node.should_receive(:to_ruby) do |context|
              context.width.should == 80
              context.shift.should == 0
              "ruby"
            end

            node.to_ruby_enclosed(@context_default)
          end
        end

        describe "on nodes where #enclosed? returns true" do
          it "passes correct available space info to #to_ruby" do
            node = EnclosedNode.new
            node.should_receive(:to_ruby) do |context|
              context.width.should == 80
              context.shift.should == 1
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
        it "passes correct available space info to statements" do
          node = Program.new(
            :statements => node_to_ruby_mock(:width => 80, :shift => 0),
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
        it "passes correct available space info to statements" do
          node = Module.new(
            :name       => "M",
            :statements => node_to_ruby_mock(:width => 78, :shift => 0),
          )

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
        it "passes correct available space info to statements" do
          node = Statements.new(
            :statements => [node_to_ruby_mock(:width => 80, :shift => 0)]
          )

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
        it "passes correct available space info to statements" do
          node = Begin.new(
            :statements => node_to_ruby_mock(:width => 78, :shift => 0)
          )

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
        it "passes correct available space info to body" do
          node = Else.new(:body => node_to_ruby_mock(:width => 78, :shift => 0))

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
        it "passes correct available space info to value" do
          node = Next.new(
            :value => node_to_ruby_mock(:width => 80, :shift => 5)
          )

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
        it "passes correct available space info to value" do
          node = Return.new(
            :value => node_to_ruby_mock(:width => 80, :shift => 7)
          )

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
        it "passes correct available space info to expressions" do
          node = Expressions.new(
            :expressions => [
              node_to_ruby_mock(:width => 80, :shift => 1),
              node_to_ruby_mock(:width => 80, :shift => 3),
              node_to_ruby_mock(:width => 80, :shift => 5)
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
        it "passes correct available space info to lhs" do
          node = Assignment.new(
            :lhs => node_to_ruby_mock(:width => 80, :shift => 0),
            :rhs => @literal_42
          )

          node.to_ruby(@context_default)
        end

        describe "when assigning from a variable" do
          it "passes correct available space info to rhs" do
            rhs = Variable.new(:name => "a")
            rhs.should_receive(:to_ruby) do |context|
              context.width.should == 80
              context.shift.should == 14
              ""
            end

            node = Assignment.new(:lhs => @variable_a, :rhs => rhs)

            node.to_ruby(@context_default)
          end
        end

        describe "when assigning from a non-variable" do
          it "passes correct available space info to rhs" do
            node = Assignment.new(
              :lhs => @variable_a,
              :rhs => node_to_ruby_mock(:width => 80, :shift => 4)
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

      describe "formatting" do
        it "passes correct available space info to receiver" do
          node = MethodCall.new(
            :receiver => node_to_ruby_mock(:width => 80, :shift => 0),
            :name     => "m",
            :args     => [],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to args" do
          node = MethodCall.new(
            :receiver => @variable_a,
            :name     => "m",
            :args     => [
              node_to_ruby_mock(:width => 80, :shift => 3),
              node_to_ruby_mock(:width => 80, :shift => 5),
              node_to_ruby_mock(:width => 80, :shift => 7)
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
  end

  describe Block, :type => :ruby do
    describe "#to_ruby" do
      it "emits a single-line block when the block fits available space and the statments are single-line" do
        node = Block.new(:args => [], :statements => @assignment_a_42)

        node.to_ruby(@context_default).should == "{ a = 42 }"
      end

      it "emits a multi-line block when the block doesn't fit available space" do
        node = Block.new(:args => [], :statements => @assignment_a_42)

        node.to_ruby(@context_narrow).should == [
          "{",
          "  a = 42",
          "}"
        ].join("\n")
      end

      it "emits a multi-line block when the statements are multi-line" do
        node = Block.new(:args => [], :statements => @statements)

        node.to_ruby(@context_default).should == [
          "{",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "}"
        ].join("\n")
      end

      describe "for single-line blocks" do
        it "emits correct code for blocks with no arguments" do
          node = Block.new(:args => [], :statements => @assignment_a_42)

          node.to_ruby(@context_default).should == "{ a = 42 }"
        end

        it "emits correct code for blocks with one argument" do
          node = Block.new(
            :args       => [@variable_a],
            :statements => @assignment_a_42
          )

          node.to_ruby(@context_default).should == "{ |a| a = 42 }"
        end

        it "emits correct code for blocks with multiple arguments" do
          node = Block.new(
            :args       => [@variable_a, @variable_b, @variable_c],
            :statements => @assignment_a_42
          )

          node.to_ruby(@context_default).should == "{ |a, b, c| a = 42 }"
        end

        it "passes correct available space info to args" do
          node = Block.new(
            :args       => [
              node_to_ruby_mock(:width => 80, :shift => 3),
              node_to_ruby_mock(:width => 80, :shift => 5),
              node_to_ruby_mock(:width => 80, :shift => 7)
            ],
            :statements => @assignment_a_42
          )

          node.to_ruby(@context_default)
        end

        it "passes correct available space info to statements" do
          node = Block.new(
            :args       => [],
            :statements => node_to_ruby_mock(:width => 80, :shift => 2)
          )

          node.to_ruby(@context_default)
        end
      end

      describe "for multi-line blocks" do
        it "emits correct code for blocks with no arguments" do
          node = Block.new(:args => [], :statements => @statements)

          node.to_ruby(@context_narrow).should == [
            "{",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")
        end

        it "emits correct code for blocks with one argument" do
          node = Block.new(:args => [@variable_a], :statements => @statements)

          node.to_ruby(@context_narrow).should == [
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

          node.to_ruby(@context_narrow).should == [
            "{ |a, b, c|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")
        end

        it "passes correct available space info to args" do
          node = Block.new(
            :args       => [
              node_to_ruby_mock(
                { :width => 0, :shift => 3 },
                { :width => 0, :shift => 3 }
              ),
              node_to_ruby_mock(
                { :width => 0, :shift => 5 },
                { :width => 0, :shift => 5 }
              ),
              node_to_ruby_mock(
                { :width => 0, :shift => 7 },
                { :width => 0, :shift => 7 }
              )
            ],
            :statements => @statements
          )

          node.to_ruby(@context_narrow)
        end

        it "passes correct available space info to statements" do
          node = Block.new(
            :args       => [],
            :statements => node_to_ruby_mock(
              { :width =>  0, :shift => 2 },
              { :width => -2, :shift => 0 }
            )
          )

          node.to_ruby(@context_narrow)
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
        it "passes correct available space info to statements" do
          node = ConstAccess.new(
            :receiver => node_to_ruby_mock(:width => 80, :shift => 0),
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
      before :each do
        @node_empty    = Array.new(:elements => [])
        @node_one      = Array.new(:elements => [@literal_42])
        @node_multiple = Array.new(
          :elements => [@literal_42, @literal_43, @literal_44]
        )
      end

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
              node_to_ruby_mock(:width => 80, :shift => 1),
              node_to_ruby_mock(:width => 80, :shift => 3),
              node_to_ruby_mock(:width => 80, :shift => 5)
            ]
          )

          node.to_ruby(@context_default)
        end
      end

      describe "for multi-line arrays" do
        it "emits correct code for empty arrays" do
          @node_empty.to_ruby(@context_narrow).should == [
           "[",
           "]"
          ].join("\n")
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
              node_to_ruby_mock(
                { :width =>  0, :shift => 1 },
                { :width => -2, :shift => 0 }
              ),
              node_to_ruby_mock(
                { :width =>  0, :shift => 3 },
                { :width => -2, :shift => 0 }
              ),
              node_to_ruby_mock(
                { :width =>  0, :shift => 5 },
                { :width => -2, :shift => 0 }
              )
            ]
          )

          node.to_ruby(@context_narrow)
        end
      end
    end
  end

  describe Hash, :type => :ruby do
    describe "#to_ruby" do
      before :each do
        @node_empty = Hash.new(:entries => [])
        @node_one   = Hash.new(:entries => [@hash_entry_a_42])
        @node_multiple = Hash.new(
          :entries => [@hash_entry_a_42, @hash_entry_b_43, @hash_entry_c_44]
        )
      end

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
              node_to_ruby_mock(:width => 80, :shift => 2),
              node_to_ruby_mock(:width => 80, :shift => 4),
              node_to_ruby_mock(:width => 80, :shift => 6)
            ]
          )

          node.to_ruby(@context_default)
        end
      end

      describe "for multi-line hashes" do
        it "emits correct code for empty hashes" do
          @node_empty.to_ruby(@context_narrow).should == [
           "{",
           "}"
          ].join("\n")
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
          node1 = node_to_ruby_mock(
            { :width =>  0, :shift => 2 },
            { :width => -2, :shift => 0 }
          )
          node2 = node_to_ruby_mock(
            { :width =>  0, :shift => 4 },
            { :width => -2, :shift => 0 }
          )
          node3 = node_to_ruby_mock(
            { :width =>  0, :shift => 6 },
            { :width => -2, :shift => 0 }
          )

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
  end

  describe HashEntry, :type => :ruby do
    describe "#to_ruby" do
      describe "basics" do
        it "emits correct code with no max_key_width set" do
          node = HashEntry.new(:key => @literal_a, :value => @literal_42)

          node.to_ruby(@context_default).should == ":a => 42"
        end

        it "emits correct code with max_key_width set" do
          node = HashEntry.new(:key => @literal_a, :value => @literal_42)

          node.to_ruby(@context_max_key_width).should == ":a   => 42"
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
  end
end
