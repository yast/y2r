require "spec_helper"

module Y2R::AST::Ruby
  RSpec.configure do |c|
    c.before :each, :type => :ruby do
      @literal_true = Literal.new(:value => true)

      @literal_a = Literal.new(:value => :a)
      @literal_b = Literal.new(:value => :b)
      @literal_c = Literal.new(:value => :c)

      @literal_42 = Literal.new(:value => 42)
      @literal_43 = Literal.new(:value => 43)
      @literal_44 = Literal.new(:value => 44)

      @variable_a = Variable.new(:name => "a")
      @variable_b = Variable.new(:name => "b")
      @variable_c = Variable.new(:name => "c")

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

      @statements = Statements.new(
        :statements => [@assignment_a_42, @assignment_b_43, @assignment_c_44]
      )

      @begin = Begin.new(:statements => @statements)

      @arg_a = Arg.new(:name => "a", :default => nil)
      @arg_b = Arg.new(:name => "b", :default => nil)
      @arg_c = Arg.new(:name => "c", :default => nil)
    end
  end

  describe Class, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Class.new(:name => "C", :statements => @statements)

        node.to_ruby.should == [
          "class C",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end
    end
  end

  describe Module, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Module.new(:name  => "M", :statements => @statements)

        node.to_ruby.should == [
          "module M",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end
    end
  end

  describe Def, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for method definitions with no arguments" do
        node = Def.new(:name => "m", :args => [], :statements => @statements)

        node.to_ruby.should == [
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
          :args       => [@arg_a],
          :statements => @statements
        )

        node.to_ruby.should == [
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
          :args       => [@arg_a, @arg_b, @arg_c],
          :statements => @statements
        )

        node.to_ruby.should == [
          "def m(a, b, c)",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end
    end
  end

  describe Arg, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Arg.new(:name => "a")
      end
    end
  end

  describe Statements, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for statement lists with no statements" do
        node = Statements.new(:statements => [])

        node.to_ruby.should == ""
      end

      it "emits correct code for statement lists with one statement" do
        node = Statements.new(:statements => [@assignment_a_42])

        node.to_ruby.should == "a = 42"
      end

      it "emits correct code for statement lists with multiple statements" do
        node = Statements.new(
          :statements => [@assignment_a_42, @assignment_b_43, @assignment_c_44]
        )

        node.to_ruby.should == [
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

        node.to_ruby.should == [
          "a = 42",
          "b = 43",
          "c = 44",
        ].join("\n")
      end
    end
  end

  describe Begin, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Begin.new(:statements => @statements)

        node.to_ruby.should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end
    end
  end

  describe If, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for if statements without else" do
        node = If.new(
          :condition => @literal_true,
          :then      => @statements,
          :else      => nil
        )

        node.to_ruby.should == [
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

        node.to_ruby.should == [
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
  end

  describe Unless, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for unless statements without else" do
        node = Unless.new(
          :condition => @literal_true,
          :then      => @statements,
          :else      => nil
        )

        node.to_ruby.should == [
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

        node.to_ruby.should == [
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
  end

  describe While, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for common while statements" do
        node = While.new(:condition => @literal_true, :body => @statements)

        node.to_ruby.should == [
          "while true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "emits correct code for while statements wrapping begin...end" do
        node = While.new(:condition  => @literal_true, :body => @begin)

        node.to_ruby.should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end while true",
        ].join("\n")
      end
    end
  end

  describe Until, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for common until statements" do
        node = Until.new(:condition => @literal_true, :body => @statements)

        node.to_ruby.should == [
          "until true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "emits correct code for until statements wrapping begin...end" do
        node = Until.new(:condition  => @literal_true, :body => @begin)

        node.to_ruby.should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end until true",
        ].join("\n")
      end
    end
  end

  describe Break, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Break.new

        node.to_ruby.should == "break"
      end
    end
  end

  describe Next, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for nexts without a value" do
        node = Next.new(:value => nil)

        node.to_ruby.should == "next"
      end

      it "emits correct code for nexts with a value" do
        node = Next.new(:value => @literal_42)

        node.to_ruby.should == "next 42"
      end
    end
  end

  describe Return, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for returns without a value" do
        node = Return.new(:value => nil)

        node.to_ruby.should == "return"
      end

      it "emits correct code for returns with a value" do
        node = Return.new(:value => @literal_42)

        node.to_ruby.should == "return 42"
      end
    end
  end

  describe Assignment, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Assignment.new(:lhs => @variable_a, :rhs => @literal_42)

        node.to_ruby.should == "a = 42"
      end
    end
  end

  describe Ternary, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Ternary.new(
          :condition => @literal_true,
          :then      => @literal_42,
          :else      => @literal_43
        )

        node.to_ruby.should == "true ? 42 : 43"
      end
    end
  end

  describe MethodCall, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for method calls without a receiver" do
        node = MethodCall.new(
          :receiver => nil,
          :name     => "m",
          :args     => [],
          :block    => nil,
          :parens   => false
        )

        node.to_ruby.should == "m"
      end

      it "emits correct code for method calls with a receiver" do
        node = MethodCall.new(
          :receiver => @variable_a,
          :name     => "m",
          :args     => [],
          :block    => nil,
          :parens   => false
        )

        node.to_ruby.should == "a.m"
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

          node.to_ruby.should == "m"
        end

        it "emits correct code for method calls with one argument" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "m",
            :args     => [@literal_42],
            :block    => nil,
            :parens   => true
          )

          node.to_ruby.should == "m(42)"
        end

        it "emits correct code for method calls with multiple arguments" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "m",
            :args     => [@literal_42, @literal_43, @literal_44],
            :block    => nil,
            :parens   => true
          )

          node.to_ruby.should == "m(42, 43, 44)"
        end

        it "emits correct code for method calls with no receiver, const-like name and no arguments" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "M",
            :args     => [],
            :block    => nil,
            :parens   => true
          )

          node.to_ruby.should == "M()"
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

          node.to_ruby.should == "m"
        end

        it "emits correct code for method calls with one argument" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "m",
            :args     => [@literal_42],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby.should == "m 42"
        end

        it "emits correct code for method calls with multiple arguments" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "m",
            :args     => [@literal_42, @literal_43, @literal_44],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby.should == "m 42, 43, 44"
        end

        it "emits correct code for method calls with no receiver, const-like name and no arguments" do
          node = MethodCall.new(
            :receiver => nil,
            :name     => "M",
            :args     => [],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby.should == "M()"
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

        node.to_ruby.should == "m"
      end

      it "emits correct code for method calls with a block" do
        node = MethodCall.new(
          :receiver => nil,
          :name     => "m",
          :args     => [],
          :block    => Block.new(:args => [], :statements => @statements),
          :parens   => false
        )

        node.to_ruby.should == [
          "m {",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "}"
        ].join("\n")
      end
    end
  end

  describe Block, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for blocks with no arguments" do
        node = Block.new(:args => [], :statements => @statements)

        node.to_ruby.should == [
          "{",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "}"
        ].join("\n")
      end

      it "emits correct code for blocks with one argument" do
        node = Block.new(:args => [@arg_a], :statements => @statements)

        node.to_ruby.should == [
          "{ |a|",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "}"
        ].join("\n")
      end

      it "emits correct code for blocks with multiple arguments" do
        node = Block.new(
          :args       => [@arg_a, @arg_b, @arg_c],
          :statements => @statements
        )

        node.to_ruby.should == [
          "{ |a, b, c|",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "}"
        ].join("\n")
      end
    end
  end

  describe ConstAccess, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for const accesses without a receiver" do
        node = ConstAccess.new(:receiver => nil, :name => "C")

        node.to_ruby.should == "C"
      end

      it "emits correct code for const accesses with a receiver" do
        node = ConstAccess.new(:receiver => @variable_a, :name => "C")

        node.to_ruby.should == "a::C"
      end
    end
  end

  describe Variable, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Variable.new(:name => "a")

        node.to_ruby.should == "a"
      end
    end
  end

  describe Self, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = Self.new

        node.to_ruby.should == "self"
      end
    end
  end

  describe Literal, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for nil literals" do
        node = Literal.new(:value => nil)

        node.to_ruby.should == "nil"
      end

      it "emits correct code for true literals" do
        node = Literal.new(:value => true)

        node.to_ruby.should == "true"
      end

      it "emits correct code for false literals" do
        node = Literal.new(:value => false)

        node.to_ruby.should == "false"
      end

      it "emits correct code for integer literals" do
        node = Literal.new(:value => 42)

        node.to_ruby.should == "42"
      end

      it "emits correct code for float literals" do
        node = Literal.new(:value => 42.0)

        node.to_ruby.should == "42.0"
      end

      it "emits correct code for symbol literals" do
        node = Literal.new(:value => :abcd)

        node.to_ruby.should == ":abcd"
      end

      it "emits correct code for string literals" do
        node = Literal.new(:value => "abcd")

        node.to_ruby.should == "\"abcd\""
      end
    end
  end

  describe Array, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for empty arrays" do
        node = Array.new(:elements => [])

        node.to_ruby.should == "[]"
      end

      it "emits correct code for arrays with one element" do
        node = Array.new(:elements => [@literal_42])

        node.to_ruby.should == "[42]"
      end

      it "emits correct code for arrays with multiple elements" do
        node = Array.new(
          :elements => [@literal_42, @literal_43, @literal_44]
        )

        node.to_ruby.should == "[42, 43, 44]"
      end
    end
  end

  describe Hash, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code for empty hashes" do
        node = Hash.new(:entries => [])

        node.to_ruby.should == "{}"
      end

      it "emits correct code for hashes with one entry" do
        node = Hash.new(
          :entries => [HashEntry.new(:key => @literal_a, :value => @literal_42)]
        )

        node.to_ruby.should == "{ :a => 42 }"
      end

      it "emits correct code for hashes with multiple entries" do
        node = Hash.new(
          :entries => [
            HashEntry.new(:key => @literal_a, :value => @literal_42),
            HashEntry.new(:key => @literal_b, :value => @literal_43),
            HashEntry.new(:key => @literal_c, :value => @literal_44)
          ]
        )

        node.to_ruby.should == "{ :a => 42, :b => 43, :c => 44 }"
      end
    end
  end

  describe HashEntry, :type => :ruby do
    describe "#to_ruby" do
      it "emits correct code" do
        node = HashEntry.new(:key => @literal_a, :value => @literal_42)

        node.to_ruby.should == ":a => 42"
      end
    end
  end
end
