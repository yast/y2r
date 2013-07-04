# encoding: utf-8

require "spec_helper"

def check_context(node, expected_context)
  node_copy = node.dup

  node_copy.should_receive(:to_ruby) do |context|
    expected_context.each_pair do |key, value|
      context.send(key).should == value
    end

    node.to_ruby(context)
  end

  node_copy
end

def check_context_enclosed(node, expected_context)
  node_copy = node.dup

  node_copy.should_receive(:to_ruby_enclosed) do |context|
    expected_context.each_pair do |key, value|
      context.send(key).should == value
    end

    node.to_ruby(context)
  end

  node_copy
end

module Y2R::AST::Ruby
  RSpec.configure do |c|
    c.before :each, :type => :ruby do
      @literal_true  = Literal.new(:value => true)
      @literal_false = Literal.new(:value => false)

      @literal_true_comment_before = Literal.new(
        :value          => true,
        :comment_before => "# before"
      )
      @literal_true_comment_after = Literal.new(
        :value         => true,
        :comment_after => "# after"
      )

      @literal_a   = Literal.new(:value => :a)
      @literal_aa  = Literal.new(:value => :aa)
      @literal_aaa = Literal.new(:value => :aaa)
      @literal_b   = Literal.new(:value => :b)
      @literal_c   = Literal.new(:value => :c)

      @literal_a_comment_before = Literal.new(
        :value          => :a,
        :comment_before => "# before"
      )
      @literal_a_comment_after = Literal.new(
        :value         => :a,
        :comment_after => "# after"
      )

      @literal_42 = Literal.new(:value => 42)
      @literal_43 = Literal.new(:value => 43)
      @literal_44 = Literal.new(:value => 44)
      @literal_45 = Literal.new(:value => 45)

      @literal_42_comment_before = Literal.new(
        :value          => 42,
        :comment_before => "# before"
      )
      @literal_43_comment_before = Literal.new(
        :value          => 43,
        :comment_before => "# before"
      )
      @literal_44_comment_before = Literal.new(
        :value          => 44,
        :comment_before => "# before"
      )

      @literal_42_comment_after = Literal.new(
        :value         => 42,
        :comment_after => "# after"
      )
      @literal_43_comment_after = Literal.new(
        :value         => 43,
        :comment_after => "# after"
      )
      @literal_44_comment_after = Literal.new(
        :value         => 44,
        :comment_after => "# after"
      )

      @variable_a = Variable.new(:name => "a")
      @variable_b = Variable.new(:name => "b")
      @variable_c = Variable.new(:name => "c")
      @variable_S = Variable.new(:name => "S")

      @variable_a_comment_before = Variable.new(
        :name           => "a",
        :comment_before => "# before"
      )
      @variable_a_comment_after = Variable.new(
        :name          => "a",
        :comment_after => "# after"
      )

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
      @hash_entry_c_44 = HashEntry.new(
        :key   => @literal_c,
        :value => @literal_44
      )

      @hash_entry_a_42_comment_before = HashEntry.new(
        :key            => @literal_a,
        :value          => @literal_42,
        :comment_before => "# before"
      )
      @hash_entry_b_43_comment_before = HashEntry.new(
        :key            => @literal_b,
        :value          => @literal_43,
        :comment_before => "# before"
      )
      @hash_entry_c_44_comment_before = HashEntry.new(
        :key            => @literal_c,
        :value          => @literal_44,
        :comment_before => "# before"
      )

      @hash_entry_a_42_comment_after = HashEntry.new(
        :key           => @literal_a,
        :value         => @literal_42,
        :comment_after => "# after"
      )
      @hash_entry_b_43_comment_after = HashEntry.new(
        :key           => @literal_b,
        :value         => @literal_43,
        :comment_after => "# after"
      )
      @hash_entry_c_44_comment_after = HashEntry.new(
        :key           => @literal_c,
        :value         => @literal_44,
        :comment_after => "# after"
      )

      @hash_entry_a_statements = HashEntry.new(
        :key   => @literal_a,
        :value => @statements
      )
      @hash_entry_b_statements = HashEntry.new(
        :key   => @literal_b,
        :value => @statements
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
    class CommentedNode < Node
      def to_ruby_no_comments(context)
        "ruby"
      end

      def single_line_width_no_comments
        4
      end
    end

    class NotEnclosedNode < Node
      def enclose?
        false
      end

      def to_ruby_no_comments(context)
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

      def to_ruby_no_comments(context)
        "ruby"
      end

      def single_line_width
        4
      end
    end

    before :each do
      @node_not_enclosed = NotEnclosedNode.new
      @node_enclosed     = EnclosedNode.new

      @node_comment_none   = CommentedNode.new
      @node_comment_before = CommentedNode.new(:comment_before => "# before")
      @node_comment_after  = CommentedNode.new(:comment_after => "# after")
    end

    describe "#to_ruby" do
      describe "on nodes without any comments" do
        it "returns code without any comments" do
          @node_comment_none.to_ruby(@context_default).should == "ruby"
        end
      end

      describe "on nodes with comment before" do
        it "returns code with comment before" do
          @node_comment_before.to_ruby(@context_default).should == [
            "# before",
            "ruby"
          ].join("\n")
        end
      end

      describe "on nodes with comment after" do
        it "returns code with comment after" do
          @node_comment_after.to_ruby(@context_default).should == "ruby # after"
        end
      end
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
            @node_enclosed.should_receive(:to_ruby_no_comments) do |context|
              context.width.should == 80
              context.shift.should == 1
              "ruby"
            end

            @node_enclosed.to_ruby_enclosed(@context_default)
          end
        end
      end
    end

    describe "#single_line_width" do
      describe "on nodes without any comments" do
        it "returns width without any comments" do
          @node_comment_none.single_line_width.should == 4
        end
      end

      describe "on nodes with comment before" do
        it "returns width with comment before" do
          @node_comment_before.single_line_width.should == Float::INFINITY
        end
      end

      describe "on nodes with comment after" do
        it "returns width with comment after" do
          @node_comment_after.single_line_width.should == 12
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
      @node_comment_none = Program.new(
        :statements => @statements,
        :filename   => "file.ycp"
      )
      @node_comment_before = Program.new(
        :statements     => @statements,
        :filename       => "file.ycp",
        :comment_before => "# before"
      )
      @node_comment_after = Program.new(
        :statements    => @statements,
        :filename      => "file.ycp",
        :comment_after => "# after"
      )
    end

    describe "#to_ruby" do
      it "emits correct code" do
        @node_comment_none.to_ruby(@context_default).should == [
          "# encoding: utf-8",
          "",
          "# Translated by Y2R (https://github.com/yast/y2r).",
          "#",
          "# Original file: file.ycp",
          "",
          "a = 42",
          "b = 43",
          "c = 44"
        ].join("\n")

        @node_comment_before.to_ruby(@context_default).should == [
          "# encoding: utf-8",
          "",
          "# Translated by Y2R (https://github.com/yast/y2r).",
          "#",
          "# Original file: file.ycp",
          "",
          "# before",
          "a = 42",
          "b = 43",
          "c = 44"
        ].join("\n")

        @node_comment_after.to_ruby(@context_default).should == [
          "# encoding: utf-8",
          "",
          "# Translated by Y2R (https://github.com/yast/y2r).",
          "#",
          "# Original file: file.ycp",
          "",
          "a = 42",
          "b = 43",
          "c = 44 # after"
        ].join("\n")
      end

      it "passes correct available space info to statements" do
        node = Program.new(
          :filename   => "file.ycp",
          :statements => check_context(@statements, :width => 80, :shift => 0)
        )

        node.to_ruby(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_comment_none.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
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

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == [
          "class C < S",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "passes correct available space info to superclass" do
        node = Class.new(
          :name       => "C",
          :superclass => check_context(@variable_S, :width => 80, :shift => 10),
          :statements => @statements
        )

        node.to_ruby_no_comments(@context_default)
      end

      it "passes correct available space info to statements" do
        node = Class.new(
          :name       => "C",
          :superclass => @variable_S,
          :statements => check_context(@statements, :width => 78, :shift => 0),
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == Float::INFINITY
      end
    end
  end

  describe Module, :type => :ruby do
    before :each do
      @node = Module.new(:name  => "M", :statements => @statements)
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == [
          "module M",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "passes correct available space info to statements" do
        node = Module.new(
          :name       => "M",
          :statements => check_context(@statements, :width => 78, :shift => 0),
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == Float::INFINITY
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

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_no_args.to_ruby_no_comments(@context_default).should == [
          "def m",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_one_arg.to_ruby_no_comments(@context_default).should == [
          "def m(a)",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_multiple_args.to_ruby_no_comments(@context_default).should == [
          "def m(a, b, c)",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "passes correct available space info to args" do
        node = Def.new(
          :name       => "m",
          :args       => [
            check_context(@variable_a, :width => 80, :shift => 6),
            check_context(@variable_b, :width => 80, :shift => 9),
            check_context(@variable_c, :width => 80, :shift => 12),
          ],
          :statements => @statements
        )

        node.to_ruby_no_comments(@context_default)
      end

      it "passes correct available space info to statements" do
        node = Def.new(
          :name       => "m",
          :args       => [],
          :statements => check_context(@statements, :width => 78, :shift => 0),
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_no_args.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_one_arg.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multiple_args.single_line_width_no_comments.should ==
          Float::INFINITY
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

      @node_with_nils = Statements.new(
        :statements => [
          @assignment_a_42,
          nil,
          @assignment_b_43,
          nil,
          @assignment_c_44
        ]
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_empty.to_ruby_no_comments(@context_default).should == ""

        @node_one.to_ruby_no_comments(@context_default).should == "a = 42"

        @node_multiple.to_ruby_no_comments(@context_default).should == [
          "a = 42",
          "b = 43",
          "c = 44",
        ].join("\n")

        @node_with_nils.to_ruby_no_comments(@context_default).should == [
          "a = 42",
          "b = 43",
          "c = 44",
        ].join("\n")
      end

      it "passes correct available space info to statements" do
        node = Statements.new(
          :statements => [
            check_context(@assignment_a_42, :width => 80, :shift => 0),
            check_context(@assignment_b_43, :width => 80, :shift => 0),
            check_context(@assignment_c_44, :width => 80, :shift => 0)
          ]
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_empty.single_line_width_no_comments.should    == 0
        @node_one.single_line_width_no_comments.should      == 6
        @node_multiple.single_line_width_no_comments.should == Float::INFINITY

        @node_with_nils.single_line_width_no_comments.should == Float::INFINITY
      end
    end
  end

  describe Begin, :type => :ruby do
    before :each do
      @node = Begin.new(:statements => @statements)
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "passes correct available space info to statements" do
        node = Begin.new(
          :statements => check_context(@statements, :width => 78, :shift => 0)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == Float::INFINITY
      end
    end
  end

  describe If, :type => :ruby do
    before :each do
      @node_single = If.new(
        :condition => @literal_true,
        :then      => @assignment_a_42,
        :else      => nil
      )

      @node_multi_without_else = If.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => nil
      )
      @node_multi_with_else = If.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => @statements
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_single.to_ruby_no_comments(@context_default).should ==
          "a = 42 if true"

        @node_multi_without_else.to_ruby_no_comments(@context_narrow).should == [
          "if true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_multi_with_else.to_ruby_no_comments(@context_default).should == [
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

      describe "for single-line if statements" do
        it "passes correct available space info to condition" do
          node = If.new(
            :condition => check_context(
              @literal_true,
              :width => 80,
              :shift => 10
            ),
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to then" do
          node = If.new(
            :condition => @literal_true,
            :then      => check_context(
              @assignment_a_42,
              :width => 80,
              :shift => 0
            ),
            :else      => nil
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "for multi-line if statements" do
        it "passes correct available space info to condition" do
          node = If.new(
            :condition => check_context(
              @literal_true,
              :width => 80,
              :shift => 3
            ),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to then" do
          node = If.new(
            :condition => @literal_true,
            :then      => check_context(@statements, :width => 78, :shift => 0),
            :else      => @statements
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to else" do
          node = If.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => check_context(@statements, :width => 78, :shift => 0)
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_single.single_line_width_no_comments.should == 14

        @node_multi_without_else.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multi_with_else.single_line_width_no_comments.should ==
          Float::INFINITY
      end
    end
  end

  describe Unless, :type => :ruby do
    before :each do
      @node_single = Unless.new(
        :condition => @literal_true,
        :then      => @assignment_a_42,
        :else      => nil
      )

      @node_multi_without_else = Unless.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => nil
      )
      @node_multi_with_else = Unless.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => @statements
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_single.to_ruby_no_comments(@context_default).should ==
          "a = 42 unless true"

        @node_multi_without_else.to_ruby_no_comments(@context_narrow).should == [
          "unless true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_multi_with_else.to_ruby_no_comments(@context_default).should == [
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

      describe "for single-line unless statements" do
        it "passes correct available space info to condition" do
          node = Unless.new(
            :condition => check_context(
              @literal_true,
              :width => 80,
              :shift => 14
            ),
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to then" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => check_context(
              @assignment_a_42,
              :width => 80,
              :shift => 0
            ),
            :else      => nil
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "for multi-line unless statements" do
        it "passes correct available space info to condition" do
          node = Unless.new(
            :condition => check_context(
              @literal_true,
              :width => 80,
              :shift => 7
            ),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to then" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => check_context(@statements, :width => 78, :shift => 0),
            :else      => @statements
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to else" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => check_context(@statements, :width => 78, :shift => 0)
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_single.single_line_width_no_comments.should == 18

        @node_multi_without_else.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multi_with_else.single_line_width_no_comments.should ==
          Float::INFINITY
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

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_empty.to_ruby_no_comments(@context_default).should == [
          "case 42",
          "end"
        ].join("\n")

        @node_one_when_without_else.to_ruby_no_comments(@context_default).should == [
          "case 42",
          "  when 42",
          "    a = 42",
          "    b = 43",
          "    c = 44",
          "end"
        ].join("\n")

        @node_one_when_with_else.to_ruby_no_comments(@context_default).should == [
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

        @node_multiple_whens_without_else.to_ruby_no_comments(@context_default).should == [
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

        @node_multiple_whens_with_else.to_ruby_no_comments(@context_default).should == [
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

      it "passes correct available space info to expression" do
        node = Case.new(
          :expression => check_context(@literal_42, :width => 80, :shift => 5),
          :whens      => [],
          :else       => nil
        )

        node.to_ruby_no_comments(@context_default)
      end

      it "passes correct available space info to whens" do
        node = Case.new(
          :expression => @literal_42,
          :whens      => [
            check_context(@when_42, :width => 78, :shift => 0),
            check_context(@when_43, :width => 78, :shift => 0),
            check_context(@when_44, :width => 78, :shift => 0)
          ],
          :else       => nil
        )

        node.to_ruby_no_comments(@context_default)
      end

      it "passes correct available space info to else" do
        node = Case.new(
          :expression => @literal_42,
          :whens      => [],
          :else       => check_context(@else, :width => 78, :shift => 0)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_empty.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_one_when_without_else.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_one_when_with_else.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multiple_whens_without_else.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multiple_whens_with_else.single_line_width_no_comments.should ==
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

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_one_value.to_ruby_no_comments(@context_default).should == [
          "when 42",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")

        @node_multiple_values.to_ruby_no_comments(@context_default).should == [
          "when 42, 43, 44",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")
      end

      it "passes correct available space info to values" do
        node = When.new(
          :values => [
            check_context(@literal_42, :width => 80, :shift => 5),
            check_context(@literal_43, :width => 80, :shift => 9),
            check_context(@literal_44, :width => 80, :shift => 13)
          ],
          :body   => @statements
        )

        node.to_ruby_no_comments(@context_default)
      end

      it "passes correct available space info to body" do
        node = When.new(
          :values => [@literal_42],
          :body   => check_context(@statements, :width => 78, :shift => 0)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_one_value.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multiple_values.single_line_width_no_comments.should ==
          Float::INFINITY
      end
    end
  end

  describe Else, :type => :ruby do
    before :each do
      @node = Else.new(:body => @statements)
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == [
          "else",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")
      end

      it "passes correct available space info to body" do
        node = Else.new(
          :body => check_context(@statements, :width => 78, :shift => 0)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == Float::INFINITY
      end
    end
  end

  describe While, :type => :ruby do
    before :each do
      @node_common  = While.new(
        :condition => @literal_true,
        :body      => @statements
      )
      @node_wrapper = While.new(:condition => @literal_true, :body => @begin)
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_common.to_ruby_no_comments(@context_default).should == [
          "while true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_wrapper.to_ruby_no_comments(@context_default).should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end while true",
        ].join("\n")
      end

      it "passes correct available space info to condition" do
        node = While.new(
          :condition => check_context(@literal_true, :width => 80, :shift => 6),
          :body      => @statements
        )

        node.to_ruby_no_comments(@context_default)
      end

      it "passes correct available space info to body" do
        node = While.new(
          :condition => @literal_true,
          :body      => check_context(@statements, :width => 78, :shift => 0)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_common.single_line_width_no_comments.should  == Float::INFINITY
        @node_wrapper.single_line_width_no_comments.should == Float::INFINITY
      end
    end
  end

  describe Until, :type => :ruby do
    before :each do
      @node_common  = Until.new(
        :condition => @literal_true,
        :body      => @statements
      )
      @node_wrapper = Until.new(:condition => @literal_true, :body => @begin)
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_common.to_ruby_no_comments(@context_default).should == [
          "until true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_wrapper.to_ruby_no_comments(@context_default).should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end until true",
        ].join("\n")
      end

      it "passes correct available space info to condition" do
        node = Until.new(
          :condition => check_context(@literal_true, :width => 80, :shift => 6),
          :body      => @statements
        )

        node.to_ruby_no_comments(@context_default)
      end

      it "passes correct available space info to body" do
        node = Until.new(
          :condition => @literal_true,
          :body      => check_context(@statements, :width => 78, :shift => 0)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_common.single_line_width_no_comments.should  == Float::INFINITY
        @node_wrapper.single_line_width_no_comments.should == Float::INFINITY
      end
    end
  end

  describe Break, :type => :ruby do
    before :each do
      @node = Break.new
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == "break"
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == 5
      end
    end
  end

  describe Next, :type => :ruby do
    before :each do
      @node_without_value = Next.new(:value => nil)
      @node_with_value    = Next.new(:value => @literal_42)
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_without_value.to_ruby_no_comments(@context_default).should ==
          "next"

        @node_with_value.to_ruby_no_comments(@context_default).should ==
          "next 42"
      end

      it "passes correct available space info to value" do
        node = Next.new(
          :value => check_context(@literal_42, :width => 80, :shift => 5)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_without_value.single_line_width_no_comments.should == 4
        @node_with_value.single_line_width_no_comments.should    == 7
      end
    end
  end

  describe Return, :type => :ruby do
    before :each do
      @node_without_value = Return.new(:value => nil)
      @node_with_value    = Return.new(:value => @literal_42)
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_without_value.to_ruby_no_comments(@context_default).should ==
          "return"

        @node_with_value.to_ruby_no_comments(@context_default).should ==
          "return 42"
      end

      it "passes correct available space info to value" do
        node = Return.new(
          :value => check_context(@literal_42, :width => 80, :shift => 7)
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_without_value.single_line_width_no_comments.should == 6
        @node_with_value.single_line_width_no_comments.should    == 9
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

      @node_multiline = Expressions.new(
        :expressions => [@statements, @statements, @statements]
      )

      @node_comments_before = Expressions.new(
        :expressions => [
          @literal_42_comment_before,
          @literal_43_comment_before,
          @literal_44_comment_before
        ]
      )
      @node_comments_after = Expressions.new(
        :expressions => [
          @literal_42_comment_after,
          @literal_43_comment_after,
          @literal_44_comment_after
        ]
      )
    end

    describe "#to_ruby_no_comments" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_empty.to_ruby_no_comments(@context_default).should == "()"

          @node_one.to_ruby_no_comments(@context_default).should == "(42)"

          @node_multiple.to_ruby_no_comments(@context_default).should ==
            "(42; 43; 44)"

          @node_multiline.to_ruby_no_comments(@context_default).should == [
            "(",
            "  a = 42",
            "  b = 43",
            "  c = 44;",
            "  a = 42",
            "  b = 43",
            "  c = 44;",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            ")"
          ].join("\n")

          @node_comments_before.to_ruby_no_comments(@context_default).should == [
           "(",
           "  # before",
           "  42;",
           "  # before",
           "  43;",
           "  # before",
           "  44",
           ")"
          ].join("\n")

          @node_comments_after.to_ruby_no_comments(@context_default).should == [
           "(",
           "  42; # after",
           "  43; # after",
           "  44 # after",
           ")"
          ].join("\n")
        end

        it "passes correct available space info to expressions" do
          node = Expressions.new(
            :expressions => [
              check_context(@literal_42, :width => 80, :shift => 1),
              check_context(@literal_43, :width => 80, :shift => 5),
              check_context(@literal_44, :width => 80, :shift => 9)
            ]
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_empty.to_ruby_no_comments(@context_narrow).should == "()"

          @node_one.to_ruby_no_comments(@context_narrow).should == [
            "(",
            "  42",
            ")"
          ].join("\n")

          @node_multiple.to_ruby_no_comments(@context_narrow).should == [
            "(",
            "  42;",
            "  43;",
            "  44",
            ")"
          ].join("\n")

          @node_multiline.to_ruby_no_comments(@context_narrow).should == [
            "(",
            "  a = 42",
            "  b = 43",
            "  c = 44;",
            "  a = 42",
            "  b = 43",
            "  c = 44;",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            ")"
          ].join("\n")

          @node_comments_before.to_ruby_no_comments(@context_narrow).should == [
           "(",
           "  # before",
           "  42;",
           "  # before",
           "  43;",
           "  # before",
           "  44",
           ")"
          ].join("\n")

          @node_comments_after.to_ruby_no_comments(@context_narrow).should == [
           "(",
           "  42; # after",
           "  43; # after",
           "  44 # after",
           ")"
          ].join("\n")
        end

        it "passes correct available space info to expressions" do
          node = Expressions.new(
            :expressions => [
              check_context(@literal_42, :width => -2, :shift => 0),
              check_context(@literal_43, :width => -2, :shift => 0),
              check_context(@literal_44, :width => -2, :shift => 0)
            ]
          )

          node.to_ruby_no_comments(@context_narrow)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_empty.single_line_width_no_comments.should    == 2
        @node_one.single_line_width_no_comments.should      == 4
        @node_multiple.single_line_width_no_comments.should == 12

        @node_multiline.single_line_width_no_comments.should == Float::INFINITY

        @node_comments_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_comments_after.single_line_width_no_comments.should ==
          Float::INFINITY
      end
    end
  end

  describe Assignment, :type => :ruby do
    before :each do
      @node = Assignment.new(
        :lhs => @variable_a,
        :rhs => @literal_42
      )

      @node_lhs_comment_before = Assignment.new(
        :lhs => @variable_a_comment_before,
        :rhs => @literal_42
      )
      @node_lhs_comment_after = Assignment.new(
        :lhs => @variable_a_comment_after,
        :rhs => @literal_42
      )
      @node_rhs_comment_before = Assignment.new(
        :lhs => @variable_a,
        :rhs => @literal_42_comment_before
      )
      @node_rhs_comment_after = Assignment.new(
        :lhs => @variable_a,
        :rhs => @literal_42_comment_after
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == "a = 42"

        @node_lhs_comment_before.to_ruby_no_comments(@context_default).should == [
          "# before",
          "a = 42"
        ].join("\n")

        @node_lhs_comment_after.to_ruby_no_comments(@context_default).should == [
          "a = # after",
          "  42"
        ].join("\n")

        @node_rhs_comment_before.to_ruby_no_comments(@context_default).should == [
          "a =",
          "  # before",
          "  42"
        ].join("\n")

        @node_rhs_comment_after.to_ruby_no_comments(@context_default).should ==
          "a = 42 # after"
      end

      describe "for single-line assignments" do
        it "passes correct available space info to lhs" do
          node = Assignment.new(
            :lhs => check_context(@variable_a, :width => 80, :shift => 0),
            :rhs => @literal_42
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to rhs" do
          node = Assignment.new(
            :lhs => @variable_a,
            :rhs => check_context(@literal_42, :width => 80, :shift => 4)
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "for multi-line assignments" do
        it "passes correct available space info to lhs" do
          node = Assignment.new(
            :lhs => check_context(
              @variable_a_comment_after,
              :width => 80,
              :shift => 0
            ),
            :rhs => @literal_42
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to rhs" do
          node = Assignment.new(
            :lhs => @variable_a,
            :rhs => check_context(
              @literal_42_comment_before,
              :width => 78,
              :shift => 0
            )
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == 6

        @node_lhs_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_lhs_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_rhs_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_rhs_comment_after.single_line_width_no_comments.should ==
          14
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

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_without_parens.to_ruby_no_comments(@context_default).should ==
          "+42"

        @node_with_parens.to_ruby_no_comments(@context_default).should ==
          "+(42 + 43)"
      end

      it "passes correct available space info to expression" do
        node = UnaryOperator.new(
          :op         => "+",
          :expression => check_context_enclosed(
            @literal_42,
            :width => 80,
            :shift => 1
          ),
        )

        node.to_ruby_no_comments(@context_default)
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_without_parens.single_line_width_no_comments.should == 3
        @node_with_parens.single_line_width_no_comments.should    == 10
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

      @node_lhs_comment_before = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_42_comment_before,
        :rhs => @literal_43
      )
      @node_lhs_comment_after = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_42_comment_after,
        :rhs => @literal_43
      )
      @node_rhs_comment_before = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_42,
        :rhs => @literal_43_comment_before
      )
      @node_rhs_comment_after = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_42,
        :rhs => @literal_43_comment_after
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_without_parens.to_ruby_no_comments(@context_default).should ==
          "42 + 43"

        @node_with_parens.to_ruby_no_comments(@context_default).should ==
          "(42 + 43) + (44 + 45)"

        @node_lhs_comment_before.to_ruby_no_comments(@context_default).should == [
          "# before",
          "42 + 43"
        ].join("\n")

        @node_lhs_comment_after.to_ruby_no_comments(@context_default).should == [
          "42 + # after",
          "  43"
        ].join("\n")

        @node_rhs_comment_before.to_ruby_no_comments(@context_default).should == [
          "42 +",
          "  # before",
          "  43"
        ].join("\n")

        @node_rhs_comment_after.to_ruby_no_comments(@context_default).should ==
          "42 + 43 # after"
      end

      describe "for single-line binary operators" do
        it "passes correct available space info to lhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => check_context_enclosed(
              @literal_42,
              :width => 80,
              :shift => 0
            ),
            :rhs => @literal_43
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to rhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @literal_42,
            :rhs => check_context_enclosed(
              @literal_43,
              :width => 80,
              :shift => 5
            )
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "for multi-line binary operators" do
        it "passes correct available space info to lhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => check_context_enclosed(
              @literal_42_comment_after,
              :width => 80,
              :shift => 0
            ),
            :rhs => @literal_43
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to rhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @literal_42,
            :rhs => check_context_enclosed(
              @literal_43_comment_before,
              :width => 78,
              :shift => 0
            )
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_without_parens.single_line_width_no_comments.should == 7
        @node_with_parens.single_line_width_no_comments.should    == 21

        @node_lhs_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_lhs_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_rhs_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_rhs_comment_after.single_line_width_no_comments.should ==
          15
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

      @node_condition_comment_before = TernaryOperator.new(
        :condition => @literal_true_comment_before,
        :then      => @literal_42,
        :else      => @literal_43
      )
      @node_condition_comment_after = TernaryOperator.new(
        :condition => @literal_true_comment_after,
        :then      => @literal_42,
        :else      => @literal_43
      )
      @node_then_comment_before = TernaryOperator.new(
        :condition => @literal_true,
        :then      => @literal_42_comment_before,
        :else      => @literal_43
      )
      @node_then_comment_after = TernaryOperator.new(
        :condition => @literal_true,
        :then      => @literal_42_comment_after,
        :else      => @literal_43
      )
      @node_else_comment_before = TernaryOperator.new(
        :condition => @literal_true,
        :then      => @literal_42,
        :else      => @literal_43_comment_before
      )
      @node_else_comment_after = TernaryOperator.new(
        :condition => @literal_true,
        :then      => @literal_42,
        :else      => @literal_43_comment_after
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_without_parens.to_ruby_no_comments(@context_default).should ==
          "true ? 42 : 43"

        @node_with_parens.to_ruby_no_comments(@context_default).should ==
          "(true || false) ? (42 + 43) : (44 + 45)"

        @node_condition_comment_before.to_ruby_no_comments(@context_default).should == [
          "# before",
          "true ? 42 : 43"
        ].join("\n")

        @node_condition_comment_after.to_ruby_no_comments(@context_default).should == [
          "true ? # after",
          "  42 :",
          "  43"
        ].join("\n")

        @node_then_comment_before.to_ruby_no_comments(@context_default).should == [
          "true ?",
          "  # before",
          "  42 :",
          "  43"
        ].join("\n")

        @node_then_comment_after.to_ruby_no_comments(@context_default).should == [
          "true ?",
          "  42 : # after",
          "  43"
        ].join("\n")

        @node_else_comment_before.to_ruby_no_comments(@context_default).should == [
          "true ?",
          "  42 :",
          "  # before",
          "  43"
        ].join("\n")

        @node_else_comment_after.to_ruby_no_comments(@context_default).should ==
          "true ? 42 : 43 # after"
      end

      describe "for single-line ternary operators" do
        it "passes correct available space info to condition" do
          node = TernaryOperator.new(
            :condition => check_context_enclosed(
              @literal_true,
              :width => 80,
              :shift => 0
            ),
            :then      => @literal_42,
            :else      => @literal_43
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to then" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => check_context_enclosed(
              @literal_42,
              :width => 80,
              :shift => 7
            ),
            :else      => @literal_43
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to else" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => @literal_42,
            :else      => check_context_enclosed(
              @literal_43,
              :width => 80,
              :shift => 12
            ),
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "for multi-line ternary operators" do
        it "passes correct available space info to condition" do
          node = TernaryOperator.new(
            :condition => check_context_enclosed(
              @literal_true_comment_after,
              :width => 80,
              :shift => 0
            ),
            :then      => @literal_42,
            :else      => @literal_43
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to then" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => check_context_enclosed(
              @literal_42_comment_before,
              :width => 78,
              :shift => 0
            ),
            :else      => @literal_43
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to else" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => @literal_42,
            :else      => check_context_enclosed(
              @literal_43_comment_before,
              :width => 78,
              :shift => 0
            ),
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_without_parens.single_line_width_no_comments.should == 14
        @node_with_parens.single_line_width_no_comments.should    == 39

        @node_condition_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_condition_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_then_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_then_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_else_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_else_comment_after.single_line_width_no_comments.should ==
          22
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

      @node_receiver_comment_after = MethodCall.new(
        :receiver => @variable_a_comment_after,
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
      @node_parens_args_comments_before = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [
          @literal_42_comment_before,
          @literal_43_comment_before,
          @literal_44_comment_before
        ],
        :block    => nil,
        :parens   => true
      )
      @node_parens_args_comments_after = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [
          @literal_42_comment_after,
          @literal_43_comment_after,
          @literal_44_comment_after
        ],
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

    describe "#to_ruby_no_comments" do
      it "emits correct code for method calls without a receiver" do
        @node_without_receiver.to_ruby_no_comments(@context_default).should ==
          "m"
      end

      it "emits correct code for method calls with a receiver" do
        @node_with_receiver.to_ruby_no_comments(@context_default).should ==
          "a.m"
      end

      it "emits correct code for method calls when receiver has comment after" do
        @node_receiver_comment_after.to_ruby_no_comments(@context_default).should == [
          "a. # after",
          "  m"
        ].join("\n")
      end

      it "passes correct available space info to receiver" do
        node = MethodCall.new(
          :receiver => check_context(@variable_a, :width => 80, :shift => 0),
          :name     => "m",
          :args     => [],
          :block    => nil,
          :parens   => false
        )

        node.to_ruby_no_comments(@context_default)
      end

      describe "on method calls with :parens => true" do
        describe "for single-line method calls" do
          it "emits correct code for method calls with no arguments" do
            @node_parens_no_args.to_ruby_no_comments(@context_default).should ==
              "m"
          end

          it "emits correct code for method calls with one argument" do
            @node_parens_one_arg.to_ruby_no_comments(@context_default).should ==
              "m(42)"
          end

          it "emits correct code for method calls with multiple arguments" do
            @node_parens_multiple_args.to_ruby_no_comments(@context_default).should ==
              "m(42, 43, 44)"
          end

          it "emits correct code for method calls with no receiver, const-like name and no arguments" do
            @node_parens_const.to_ruby_no_comments(@context_default).should ==
              "M()"
          end

          it "passes correct available space info to args" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [
                check_context(@literal_42, :width => 80, :shift => 3),
                check_context(@literal_43, :width => 80, :shift => 7),
                check_context(@literal_44, :width => 80, :shift => 11)
              ],
              :block    => nil,
              :parens   => false
            )

            node.to_ruby_no_comments(@context_default)
          end

          it "passes correct available space info to block" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [],
              :block    => check_context(
                Block.new(:args => [], :statements => @statements),
                :width => 80,
                :shift => 3
              ),
              :parens   => false
            )

            node.to_ruby_no_comments(@context_default)
          end
        end

        describe "for multi-line method calls" do
          it "emits correct code for method calls with no arguments" do
            @node_parens_no_args.to_ruby_no_comments(@context_narrow).should == [
              "m(",
              ")"
            ].join("\n")
          end

          it "emits correct code for method calls with one argument" do
            @node_parens_one_arg.to_ruby_no_comments(@context_narrow).should == [
              "m(",
              "  42",
              ")"
            ].join("\n")
          end

          it "emits correct code for method calls with multiple arguments" do
            @node_parens_multiple_args.to_ruby_no_comments(@context_narrow).should == [
              "m(",
              "  42,",
              "  43,",
              "  44",
              ")"
            ].join("\n")
          end

          it "emits correct code for method calls with no receiver, const-like name and no arguments" do
            @node_parens_const.to_ruby_no_comments(@context_narrow).should == [
              "M(",
              ")"
            ].join("\n")
          end

          it "emits correct code for method calls with arguments with comment before" do
            @node_parens_args_comments_before.to_ruby_no_comments(@context_default).should == [
             "m(",
             "  # before",
             "  42,",
             "  # before",
             "  43,",
             "  # before",
             "  44",
             ")"
            ].join("\n")
          end

          it "emits correct code for method calls with arguments with comment after" do
            @node_parens_args_comments_after.to_ruby_no_comments(@context_default).should == [
             "m(",
             "  42, # after",
             "  43, # after",
             "  44 # after",
             ")"
            ].join("\n")
          end

          it "passes correct available space info to args" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [
                check_context(@literal_42, :width => -2, :shift => 0),
                check_context(@literal_43, :width => -2, :shift => 0),
                check_context(@literal_44, :width => -2, :shift => 0)
              ],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby_no_comments(@context_narrow)
          end

          it "passes correct available space info to block" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [],
              :block    => check_context(
                Block.new(:args => [], :statements => @statements),
                :width => 0,
                :shift => 1
              ),
              :parens   => true
            )

            node.to_ruby_no_comments(@context_narrow)
          end
        end

        it "emits correct code for method calls without a block" do
          @node_parens_without_block.to_ruby_no_comments(@context_default).should ==
            "m"
        end

        it "emits correct code for method calls with a block" do
          @node_parens_with_block.to_ruby_no_comments(@context_default).should == [
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
          @node_no_parens_no_args.to_ruby_no_comments(@context_default).should ==
            "m"
        end

        it "emits correct code for method calls with one argument" do
          @node_no_parens_one_arg.to_ruby_no_comments(@context_default).should ==
            "m 42"
        end

        it "emits correct code for method calls with multiple arguments" do
          @node_no_parens_multiple_args.to_ruby_no_comments(@context_default).should ==
            "m 42, 43, 44"
        end

        it "emits correct code for method calls with no receiver, const-like name and no arguments" do
          @node_no_parens_const.to_ruby_no_comments(@context_default).should ==
            "M()"
        end

        it "emits correct code for method calls without a block" do
          @node_no_parens_without_block.to_ruby_no_comments(@context_default).should ==
            "m"
        end

        it "emits correct code for method calls with a block" do
          @node_no_parens_with_block.to_ruby_no_comments(@context_default).should == [
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
              check_context(@literal_42, :width => 80, :shift => 3),
              check_context(@literal_43, :width => 80, :shift => 7),
              check_context(@literal_44, :width => 80, :shift => 11)
            ],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to block" do
          node = MethodCall.new(
            :receiver => @variable_a,
            :name     => "m",
            :args     => [],
            :block    => check_context(
              Block.new(:args => [], :statements => @statements),
              :width => 80,
              :shift => 3
            ),
            :parens   => false
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value for method calls without a receiver" do
        @node_without_receiver.single_line_width_no_comments.should == 1
      end

      it "returns correct value for method calls with a receiver" do
        @node_with_receiver.single_line_width_no_comments.should == 3
      end

      it "returns infinity for method calls when receiver has comment after" do
        @node_receiver_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
      end

      describe "on method calls with :parens => true" do
        it "returns correct value for method calls with no arguments" do
          @node_parens_no_args.single_line_width_no_comments.should == 1
        end

        it "returns correct value for method calls with one argument" do
          @node_parens_one_arg.single_line_width_no_comments.should == 5
        end

        it "returns correct value for method calls with multiple arguments" do
          @node_parens_multiple_args.single_line_width_no_comments.should == 13
        end

        it "returns correct value for method calls with no receiver, const-like name and no arguments" do
          @node_parens_const.single_line_width_no_comments.should == 3
        end

        it "return infinity for method calls with arguments with comment before" do
          @node_parens_args_comments_before.single_line_width_no_comments.should ==
            Float::INFINITY
        end

        it "return infinity for method calls with arguments with comment after" do
          @node_parens_args_comments_after.single_line_width_no_comments.should ==
            Float::INFINITY
        end

        it "returns correct value for method calls without a block" do
          @node_parens_without_block.single_line_width_no_comments.should == 1
        end

        it "returns correct value for method calls with a block" do
          @node_parens_with_block.single_line_width_no_comments.should == 1
        end
      end

      describe "on method calls with :parens => false" do
        it "returns correct value for method calls with no arguments" do
          @node_no_parens_no_args.single_line_width_no_comments.should == 1
        end

        it "returns correct value for method calls with one argument" do
          @node_no_parens_one_arg.single_line_width_no_comments.should == 4
        end

        it "returns correct value for method calls with multiple arguments" do
          @node_no_parens_multiple_args.single_line_width_no_comments.should ==
            12
        end

        it "returns correct value for method calls with no receiver, const-like name and no arguments" do
          @node_no_parens_const.single_line_width_no_comments.should == 3
        end

        it "returns correct value for method calls without a block" do
          @node_no_parens_without_block.single_line_width_no_comments.should ==
            1
        end

        it "returns correct value for method calls with a block" do
          @node_no_parens_with_block.single_line_width_no_comments.should == 1
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

    describe "#to_ruby_no_comments" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_single_no_args.to_ruby_no_comments(@context_default).should ==
            "{ a = 42 }"
          @node_single_one_arg.to_ruby_no_comments(@context_default).should ==

            "{ |a| a = 42 }"
          @node_single_multiple_args.to_ruby_no_comments(@context_default).should ==

            "{ |a, b, c| a = 42 }"

          @node_multi_no_args.to_ruby_no_comments(@context_narrow).should == [
            "do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_one_arg.to_ruby_no_comments(@context_narrow).should == [
            "do |a|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_multiple_args.to_ruby_no_comments(@context_narrow).should == [
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
              check_context(@variable_a, :width => 80, :shift => 3),
              check_context(@variable_b, :width => 80, :shift => 6),
              check_context(@variable_c, :width => 80, :shift => 9)
            ],
            :statements => @assignment_a_42
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to statements" do
          node = Block.new(
            :args       => [],
            :statements => check_context(
              @assignment_a_42,
              :width => 80,
              :shift => 2
            )
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_single_no_args.to_ruby_no_comments(@context_narrow).should == [
            "do",
            "  a = 42",
            "end"
          ].join("\n")

          @node_single_one_arg.to_ruby_no_comments(@context_narrow).should == [
            "do |a|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_single_multiple_args.to_ruby_no_comments(@context_narrow).should == [
            "do |a, b, c|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_multi_no_args.to_ruby_no_comments(@context_narrow).should == [
            "do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_one_arg.to_ruby_no_comments(@context_narrow).should == [
            "do |a|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_multiple_args.to_ruby_no_comments(@context_narrow).should == [
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
              check_context(@variable_a, :width => 0, :shift => 4),
              check_context(@variable_b, :width => 0, :shift => 7),
              check_context(@variable_c, :width => 0, :shift => 10)
            ],
            :statements => @assignment_a_42
          )

          node.to_ruby_no_comments(@context_narrow)
        end

        it "passes correct available space info to statements" do
          node = Block.new(
            :args       => [],
            :statements => check_context(
              @assignment_a_42,
              :width => -2,
              :shift => 0
            )
          )

          node.to_ruby_no_comments(@context_narrow)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_single_no_args.single_line_width_no_comments.should       == 10
        @node_single_one_arg.single_line_width_no_comments.should       == 14
        @node_single_multiple_args.single_line_width_no_comments.should == 20

        @node_multi_no_args.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multi_one_arg.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_multi_multiple_args.single_line_width_no_comments.should ==
          Float::INFINITY
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

      @node_receiver_comment_before = ConstAccess.new(
        :receiver => @variable_a_comment_before,
        :name     => "C"
      )
      @node_receiver_comment_after = ConstAccess.new(
        :receiver => @variable_a_comment_after,
        :name     => "C"
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node_without_receiver.to_ruby_no_comments(@context_default).should ==
          "C"

        @node_with_receiver.to_ruby_no_comments(@context_default).should ==
          "a::C"

        @node_receiver_comment_before.to_ruby_no_comments(@context_default).should == [
          "# before",
          "a::C"
        ].join("\n")

        @node_receiver_comment_after.to_ruby_no_comments(@context_default).should == [
          "a:: # after",
          "  C"
        ].join("\n")
      end

      describe "for single-line const accesses" do
        it "passes correct available space info to receiver" do
          node = ConstAccess.new(
            :receiver => check_context(@variable_a, :width => 80, :shift => 0),
            :name     => "C"
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "for multi-line const accesses" do
        it "passes correct available space info to receiver" do
          node = ConstAccess.new(
            :receiver => check_context(
              @variable_a_comment_after,
              :width => 80,
              :shift => 0
            ),
            :name     => "C"
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_without_receiver.single_line_width_no_comments.should == 1
        @node_with_receiver.single_line_width_no_comments.should    == 4

        @node_receiver_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_receiver_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
      end
    end
  end

  describe Variable, :type => :ruby do
    before :each do
      @node = Variable.new(:name => "a")
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == "a"
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == 1
      end
    end
  end

  describe Self, :type => :ruby do
    before :each do
      @node = Self.new
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == "self"
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == 4
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

    describe "#to_ruby_no_comments" do
      describe "basics" do
        it "emits correct code" do
          @node_nil.to_ruby_no_comments(@context_default).should     == "nil"
          @node_true.to_ruby_no_comments(@context_default).should    == "true"
          @node_false.to_ruby_no_comments(@context_default).should   == "false"
          @node_integer.to_ruby_no_comments(@context_default).should == "42"
          @node_float.to_ruby_no_comments(@context_default).should   == "42.0"
          @node_symbol.to_ruby_no_comments(@context_default).should  == ":abcd"
          @node_string.to_ruby_no_comments(@context_default).should  == "\"abcd\""
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_nil.single_line_width_no_comments.should     == 3
        @node_true.single_line_width_no_comments.should    == 4
        @node_false.single_line_width_no_comments.should   == 5
        @node_integer.single_line_width_no_comments.should == 2
        @node_float.single_line_width_no_comments.should   == 4
        @node_symbol.single_line_width_no_comments.should  == 5
        @node_string.single_line_width_no_comments.should  == 6
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

      @node_multiline = Array.new(
        :elements => [@statements, @statements, @statements]
      )

      @node_comments_before = Array.new(
        :elements => [
          @literal_42_comment_before,
          @literal_43_comment_before,
          @literal_44_comment_before
        ]
      )
      @node_comments_after = Array.new(
        :elements => [
          @literal_42_comment_after,
          @literal_43_comment_after,
          @literal_44_comment_after
        ]
      )
    end

    describe "#to_ruby_no_comments" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_empty.to_ruby_no_comments(@context_default).should == "[]"

          @node_one.to_ruby_no_comments(@context_default).should == "[42]"

          @node_multiple.to_ruby_no_comments(@context_default).should ==
            "[42, 43, 44]"

          @node_multiline.to_ruby_no_comments(@context_default).should == [
            "[",
            "  a = 42",
            "  b = 43",
            "  c = 44,",
            "  a = 42",
            "  b = 43",
            "  c = 44,",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "]"
          ].join("\n")

          @node_comments_before.to_ruby_no_comments(@context_default).should == [
           "[",
           "  # before",
           "  42,",
           "  # before",
           "  43,",
           "  # before",
           "  44",
           "]"
          ].join("\n")

          @node_comments_after.to_ruby_no_comments(@context_default).should == [
           "[",
           "  42, # after",
           "  43, # after",
           "  44 # after",
           "]"
          ].join("\n")
        end

        it "passes correct available space info to elements" do
          node = Array.new(
            :elements => [
              check_context(@literal_42, :width => 80, :shift => 1),
              check_context(@literal_43, :width => 80, :shift => 5),
              check_context(@literal_44, :width => 80, :shift => 9)
            ]
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_empty.to_ruby_no_comments(@context_narrow).should == "[]"

          @node_one.to_ruby_no_comments(@context_narrow).should == [
            "[",
            "  42",
            "]"
          ].join("\n")

          @node_multiple.to_ruby_no_comments(@context_narrow).should == [
            "[",
            "  42,",
            "  43,",
            "  44",
            "]"
          ].join("\n")

          @node_multiline.to_ruby_no_comments(@context_narrow).should == [
            "[",
            "  a = 42",
            "  b = 43",
            "  c = 44,",
            "  a = 42",
            "  b = 43",
            "  c = 44,",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "]"
          ].join("\n")

          @node_comments_before.to_ruby_no_comments(@context_narrow).should == [
           "[",
           "  # before",
           "  42,",
           "  # before",
           "  43,",
           "  # before",
           "  44",
           "]"
          ].join("\n")

          @node_comments_after.to_ruby_no_comments(@context_narrow).should == [
           "[",
           "  42, # after",
           "  43, # after",
           "  44 # after",
           "]"
          ].join("\n")
        end

        it "passes correct available space info to elements" do
          node = Array.new(
            :elements => [
              check_context(@literal_42, :width => -2, :shift => 0),
              check_context(@literal_43, :width => -2, :shift => 0),
              check_context(@literal_44, :width => -2, :shift => 0)
            ]
          )

          node.to_ruby_no_comments(@context_narrow)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_empty.single_line_width_no_comments.should    == 2
        @node_one.single_line_width_no_comments.should      == 4
        @node_multiple.single_line_width_no_comments.should == 12

        @node_multiline.single_line_width_no_comments.should == Float::INFINITY

        @node_comments_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_comments_after.single_line_width_no_comments.should ==
          Float::INFINITY
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

      @node_aligned = Hash.new(
        :entries => [
          @hash_entry_a_42,
          @hash_entry_aa_43,
          @hash_entry_aaa_44
        ]
      )

      @node_multiline = Hash.new(
        :entries => [
          @hash_entry_a_statements,
          @hash_entry_b_statements,
          @hash_entry_c_statements
        ]
      )

      @node_comments_before = Hash.new(
        :entries => [
          @hash_entry_a_42_comment_before,
          @hash_entry_b_43_comment_before,
          @hash_entry_c_44_comment_before
        ]
      )
      @node_comments_after = Hash.new(
        :entries => [
          @hash_entry_a_42_comment_after,
          @hash_entry_b_43_comment_after,
          @hash_entry_c_44_comment_after
        ]
      )
    end

    describe "#to_ruby_no_comments" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_empty.to_ruby_no_comments(@context_default).should == "{}"

          @node_one.to_ruby_no_comments(@context_default).should ==
            "{ :a => 42 }"

          @node_multiple.to_ruby_no_comments(@context_default).should ==
            "{ :a => 42, :b => 43, :c => 44 }"

          @node_aligned.to_ruby_no_comments(@context_default).should ==
            "{ :a => 42, :aa => 43, :aaa => 44 }"

          @node_multiline.to_ruby_no_comments(@context_default).should == [
            "{",
            "  :a => a = 42",
            "  b = 43",
            "  c = 44,",
            "  :b => a = 42",
            "  b = 43",
            "  c = 44,",
            "  :c => a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")

          @node_comments_before.to_ruby_no_comments(@context_default).should == [
            "{",
            "  # before",
            "  :a => 42,",
            "  # before",
            "  :b => 43,",
            "  # before",
            "  :c => 44",
            "}"
          ].join("\n")

          @node_comments_after.to_ruby_no_comments(@context_default).should == [
            "{",
            "  :a => 42, # after",
            "  :b => 43, # after",
            "  :c => 44 # after",
            "}"
          ].join("\n")
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_empty.to_ruby_no_comments(@context_narrow).should == "{}"

          @node_one.to_ruby_no_comments(@context_narrow).should == [
           "{",
           "  :a => 42",
           "}"
          ].join("\n")

          @node_multiple.to_ruby_no_comments(@context_narrow).should == [
           "{",
           "  :a => 42,",
           "  :b => 43,",
           "  :c => 44",
           "}"
          ].join("\n")

          @node_aligned.to_ruby_no_comments(@context_narrow).should == [
           "{",
           "  :a   => 42,",
           "  :aa  => 43,",
           "  :aaa => 44",
           "}"
          ].join("\n")

          @node_multiline.to_ruby_no_comments(@context_narrow).should == [
            "{",
            "  :a => a = 42",
            "  b = 43",
            "  c = 44,",
            "  :b => a = 42",
            "  b = 43",
            "  c = 44,",
            "  :c => a = 42",
            "  b = 43",
            "  c = 44",
            "}"
          ].join("\n")

          @node_comments_before.to_ruby_no_comments(@context_narrow).should == [
            "{",
            "  # before",
            "  :a => 42,",
            "  # before",
            "  :b => 43,",
            "  # before",
            "  :c => 44",
            "}"
          ].join("\n")

          @node_comments_after.to_ruby_no_comments(@context_narrow).should == [
            "{",
            "  :a => 42, # after",
            "  :b => 43, # after",
            "  :c => 44 # after",
            "}"
          ].join("\n")
        end

        it "passes correct available space info to entries" do
          node = Hash.new(:entries => [
            check_context(@hash_entry_a_42, :width => -2, :shift => 0),
            check_context(@hash_entry_b_43, :width => -2, :shift => 0),
            check_context(@hash_entry_c_44, :width => -2, :shift => 0)
          ])

          node.to_ruby_no_comments(@context_narrow)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node_empty.single_line_width_no_comments.should    == 2
        @node_one.single_line_width_no_comments.should      == 12
        @node_multiple.single_line_width_no_comments.should == 32

        @node_multiline.single_line_width_no_comments.should == Float::INFINITY

        @node_comments_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_comments_after.single_line_width_no_comments.should ==
          Float::INFINITY
      end
    end
  end

  describe HashEntry, :type => :ruby do
    before :each do
      @node = HashEntry.new(:key => @literal_a, :value => @literal_42)

      @node_key_comment_before = HashEntry.new(
        :key   => @literal_a_comment_before,
        :value => @literal_42
      )
      @node_key_comment_after = HashEntry.new(
        :key   => @literal_a_comment_after,
        :value => @literal_42
      )
      @node_value_comment_before = HashEntry.new(
        :key   => @literal_a,
        :value => @literal_42_comment_before
      )
      @node_value_comment_after = HashEntry.new(
        :key   => @literal_a,
        :value => @literal_42_comment_after
      )
    end

    describe "#to_ruby_no_comments" do
      it "emits correct code" do
        @node.to_ruby_no_comments(@context_default).should == ":a => 42"

        @node_key_comment_before.to_ruby_no_comments(@context_default).should == [
          "# before",
          ":a => 42"
        ].join("\n")

        @node_key_comment_after.to_ruby_no_comments(@context_default).should == [
          ":a => # after",
          "  42"
        ].join("\n")

        @node_value_comment_before.to_ruby_no_comments(@context_default).should == [
          ":a =>",
          "  # before",
          "  42"
        ].join("\n")

        @node_value_comment_after.to_ruby_no_comments(@context_default).should ==
          ":a => 42 # after"
      end

      describe "for single-line hash entries" do
        it "passes correct available space info to key" do
          node = HashEntry.new(
            :key   => check_context(@literal_a, :width => 80, :shift => 0),
            :value => @literal_42
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to value" do
          node = HashEntry.new(
            :key   => @literal_a,
            :value => check_context(@literal_42, :width => 80, :shift => 6)
          )

          node.to_ruby_no_comments(@context_default)
        end
      end

      describe "for multi-line hash entries" do
        it "passes correct available space info to key" do
          node = HashEntry.new(
            :key   => check_context(
              @literal_a_comment_after,
              :width => 80,
              :shift => 0
            ),
            :value => @literal_42
          )

          node.to_ruby_no_comments(@context_default)
        end

        it "passes correct available space info to value" do
          node = HashEntry.new(
            :key   => @literal_a,
            :value => check_context(
              @literal_42_comment_before,
              :width => 78,
              :shift => 0
            )
          )

          node.to_ruby_no_comments(@context_default)
        end
      end
    end

    describe "#single_line_width_no_comments" do
      it "returns correct value" do
        @node.single_line_width_no_comments.should == 8

        @node_key_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_key_comment_after.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_value_comment_before.single_line_width_no_comments.should ==
          Float::INFINITY
        @node_value_comment_after.single_line_width_no_comments.should ==
          16
      end
    end
  end
end
