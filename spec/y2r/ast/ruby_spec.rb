# encoding: utf-8

require "spec_helper"

def check_to_ruby_context(node, expected_context)
  node_copy = node.dup

  node_copy.should_receive(:to_ruby) do |context|
    expected_context.each_pair do |key, value|
      context.send(key).should == value
    end

    node.to_ruby(context)
  end

  node_copy
end

def check_single_line_width_context(node, expected_context)
  node_copy = node.dup

  node_copy.should_receive(:single_line_width) do |context|
    expected_context.each_pair do |key, value|
      context.send(key).should == value
    end

    node.single_line_width(context)
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
      @variable_b_comment_before = Variable.new(
        :name           => "b",
        :comment_before => "# before"
      )
      @variable_c_comment_before = Variable.new(
        :name           => "c",
        :comment_before => "# before"
      )

      @variable_a_comment_after = Variable.new(
        :name          => "a",
        :comment_after => "# after"
      )
      @variable_b_comment_after = Variable.new(
        :name          => "b",
        :comment_after => "# after"
      )
      @variable_c_comment_after = Variable.new(
        :name          => "c",
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

      @assignment_a_42_comment_before = Assignment.new(
        :lhs            => @variable_a,
        :rhs            => @literal_42,
        :comment_before => "# before"
      )
      @assignment_a_42_comment_after = Assignment.new(
        :lhs           => @variable_a,
        :rhs           => @literal_42,
        :comment_after => "# after"
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

      @block = Block.new(:args => [], :statements => @statements)

      @context_default = EmitterContext.new(
        :width    => 80,
        :shift    => 0,
        :priority => Priority::NONE
      )
      @context_narrow = EmitterContext.new(
        :width    => 0,
        :shift    => 0,
        :priority => Priority::NONE
      )
      @context_max_key_width = EmitterContext.new(
        :width         => 0,
        :shift         => 0,
        :priority      => Priority::NONE,
        :max_key_width => 4
      )
    end
  end

  describe Node, :type => :ruby do
    class CommentedNode < Node
      def to_ruby_base(context)
        "ruby"
      end

      def single_line_width_base(context)
        4
      end

      def priority
        Priority::ATOMIC
      end
    end

    before :each do
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

    describe "#single_line_width" do
      describe "on nodes without any comments" do
        it "returns width without any comments" do
          @node_comment_none.single_line_width(@context_default).should == 4
        end
      end

      describe "on nodes with comment before" do
        it "returns width with comment before" do
          @node_comment_before.single_line_width(@context_default).should ==
            Float::INFINITY
        end
      end

      describe "on nodes with comment after" do
        it "returns width with comment after" do
          @node_comment_after.single_line_width(@context_default).should == 12
        end
      end
    end
  end

  describe Program, :type => :ruby do
    before :each do
      @node_comment_none = Program.new(
        :statements => @statements
      )
      @node_comment_before = Program.new(
        :statements     => @statements,
        :comment_before => "# before"
      )
      @node_comment_after = Program.new(
        :statements    => @statements,
        :comment_after => "# after"
      )
    end

    describe "#to_ruby" do
      it "emits correct code" do
        @node_comment_none.to_ruby(@context_default).should == [
          "# encoding: utf-8",
          "",
          "a = 42",
          "b = 43",
          "c = 44"
        ].join("\n")

        @node_comment_before.to_ruby(@context_default).should == [
          "# encoding: utf-8",
          "",
          "# before",
          "a = 42",
          "b = 43",
          "c = 44"
        ].join("\n")

        @node_comment_after.to_ruby(@context_default).should == [
          "# encoding: utf-8",
          "",
          "a = 42",
          "b = 43",
          "c = 44 # after"
        ].join("\n")
      end

      it "passes correct context to statements" do
        node = Program.new(
          :filename   => "file.ycp",
          :statements => check_to_ruby_context(
            @statements,
            :width    => 80,
            :shift    => 0,
            :priority => Priority::NONE
          )
        )

        node.to_ruby(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_comment_none.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_comment_after.single_line_width_base(@context_default).should ==
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == [
          "class C < S",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "passes correct context to superclass" do
        node = Class.new(
          :name       => "C",
          :superclass => check_to_ruby_context(
            @variable_S,
            :width    => 80,
            :shift    => 10,
            :priority => Priority::NONE
          ),
          :statements => @statements
        )

        node.to_ruby_base(@context_default)
      end

      it "passes correct context to statements" do
        node = Class.new(
          :name       => "C",
          :superclass => @variable_S,
          :statements => check_to_ruby_context(
            @statements,
            :width    => 78,
            :shift    => 0,
            :priority => Priority::NONE
          ),
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == Float::INFINITY
      end
    end
  end

  describe Module, :type => :ruby do
    before :each do
      @node = Module.new(:name  => "M", :statements => @statements)
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == [
          "module M",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "passes correct context to statements" do
        node = Module.new(
          :name       => "M",
          :statements => check_to_ruby_context(
            @statements,
            :width    => 78,
            :shift    => 0,
            :priority => Priority::NONE
          ),
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == Float::INFINITY
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

      @node_args_comments_before = Def.new(
        :name       => "m",
        :args       => [
          @variable_a_comment_before,
          @variable_b_comment_before,
          @variable_c_comment_before
        ],
        :statements => @statements
      )
      @node_args_comments_after = Def.new(
        :name       => "m",
        :args       => [
          @variable_a_comment_after,
          @variable_b_comment_after,
          @variable_c_comment_after
        ],
        :statements => @statements
      )
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_no_args.to_ruby_base(@context_default).should == [
          "def m",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_one_arg.to_ruby_base(@context_default).should == [
          "def m(a)",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_multiple_args.to_ruby_base(@context_default).should == [
          "def m(a, b, c)",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_args_comments_before.to_ruby_base(@context_default).should == [
          "def m(",
          "  # before",
          "  a,",
          "  # before",
          "  b,",
          "  # before",
          "  c",
          ")",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_args_comments_after.to_ruby_base(@context_default).should == [
          "def m(",
          "  a, # after",
          "  b, # after",
          "  c # after",
          ")",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      describe "for single-line method definitions" do
        it "passes correct context to args" do
          node = Def.new(
            :name       => "m",
            :args       => [
              check_to_ruby_context(
                @variable_a,
                :width    => 80,
                :shift    => 6,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @variable_b,
                :width    => 80,
                :shift    => 9,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @variable_c,
                :width    => 80,
                :shift    => 12,
                :priority => Priority::NONE
              ),
            ],
            :statements => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to statements" do
          node = Def.new(
            :name       => "m",
            :args       => [],
            :statements => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            ),
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for nulti-line method definitions" do
        it "passes correct context to args" do
          node = Def.new(
            :name       => "m",
            :args       => [
              check_to_ruby_context(
                @variable_a_comment_before,
                :width    => 78,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @variable_b_comment_before,
                :width    => 78,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @variable_c_comment_before,
                :width    => 78,
                :shift    => 0,
                :priority => Priority::NONE
              ),
            ],
            :statements => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to statements" do
          node = Def.new(
            :name       => "m",
            :args       => [@variable_a_comment_before],
            :statements => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            ),
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_no_args.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_one_arg.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multiple_args.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_args_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_args_comments_after.single_line_width_base(@context_default).should ==
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_empty.to_ruby_base(@context_default).should == ""

        @node_one.to_ruby_base(@context_default).should == "a = 42"

        @node_multiple.to_ruby_base(@context_default).should == [
          "a = 42",
          "b = 43",
          "c = 44",
        ].join("\n")

        @node_with_nils.to_ruby_base(@context_default).should == [
          "a = 42",
          "b = 43",
          "c = 44",
        ].join("\n")
      end

      it "passes correct context to statements" do
        node = Statements.new(
          :statements => [
            check_to_ruby_context(
              @assignment_a_42,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @assignment_b_43,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @assignment_c_44,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::NONE
            )
          ]
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_empty.single_line_width_base(@context_default).should ==
          0
        @node_one.single_line_width_base(@context_default).should ==
          6
        @node_multiple.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_with_nils.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to statements" do
        node = Statements.new(
          :statements => [
            check_single_line_width_context(
              @assignment_a_42,
              :priority => Priority::NONE
            )
          ]
        )

        node.single_line_width_base(@context_default)
      end
    end
  end

  describe Begin, :type => :ruby do
    before :each do
      @node = Begin.new(:statements => @statements)
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")
      end

      it "passes correct context to statements" do
        node = Begin.new(
          :statements => check_to_ruby_context(
            @statements,
            :width    => 78,
            :shift    => 0,
            :priority => Priority::NONE
          )
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == Float::INFINITY
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

      @node_single_condition_comment_before = If.new(
        :condition => @literal_true_comment_before,
        :then      => @assignment_a_42,
        :else      => nil
      )
      @node_single_condition_comment_after = If.new(
        :condition => @literal_true_comment_after,
        :then      => @assignment_a_42,
        :else      => nil
      )
      @node_single_then_comment_before = If.new(
        :condition => @literal_true,
        :then      => @assignment_a_42_comment_before,
        :else      => nil
      )
      @node_single_then_comment_after = If.new(
        :condition => @literal_true,
        :then      => @assignment_a_42_comment_after,
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

      @node_with_elsif = If.new(
        :condition => @literal_true,
        :then      => @statements,
        :else      => If.new(
          :condition => @literal_true,
          :then      => @assignment_a_42,
          :elsif     => true
        )
      )
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_single.to_ruby_base(@context_default).should == "a = 42 if true"

        @node_single_condition_comment_before.to_ruby_base(@context_default).should == [
          "if # before",
          "  true",
          "  a = 42",
          "end"
        ].join("\n")

        @node_single_condition_comment_after.to_ruby_base(@context_default).should ==
          "a = 42 if true # after"

        @node_single_then_comment_before.to_ruby_base(@context_default).should == [
          "if true",
          "  # before",
          "  a = 42",
          "end"
        ].join("\n")

        @node_single_then_comment_after.to_ruby_base(@context_default).should == [
          "if true",
          "  a = 42 # after",
          "end"
        ].join("\n")

        @node_multi_without_else.to_ruby_base(@context_narrow).should == [
          "if true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_multi_with_else.to_ruby_base(@context_default).should == [
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

        @node_with_elsif.to_ruby_base(@context_default).should == [
          "if true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "elsif true",
          "  a = 42",
          "end"
        ].join("\n")
      end

      describe "for single-line if statements" do
        it "passes correct context to condition" do
          node = If.new(
            :condition => check_to_ruby_context(
              @literal_true,
              :width    => 80,
              :shift    => 10,
              :priority => Priority::NONE
            ),
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to then" do
          node = If.new(
            :condition => @literal_true,
            :then      => check_to_ruby_context(
              @assignment_a_42,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            :else      => nil
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line if statements" do
        it "passes correct context to condition" do
          node = If.new(
            :condition => check_to_ruby_context(
              @literal_true,
              :width    => 78,
              :shift    => 1,
              :priority => Priority::NONE
            ),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to then" do
          node = If.new(
            :condition => @literal_true,
            :then      => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            :else      => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to else" do
          node = If.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_single.single_line_width_base(@context_default).should == 14

        @node_single_condition_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_single_condition_comment_after.single_line_width_base(@context_default).should ==
          22
        @node_single_then_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_single_then_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_multi_without_else.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multi_with_else.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to condition" do
        node = If.new(
          :condition => check_single_line_width_context(
            @assignment_a_42,
            :priority => Priority::NONE
          ),
          :then      => @statements,
          :else      => nil
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to then" do
        node = If.new(
          :condition => @literal_true,
          :then      => check_single_line_width_context(
            @assignment_a_42,
            :priority => Priority::NONE
          ),
          :else      => nil
        )

        node.single_line_width_base(@context_default)
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

      @node_single_condition_comment_before = Unless.new(
        :condition => @literal_true_comment_before,
        :then      => @assignment_a_42,
        :else      => nil
      )
      @node_single_condition_comment_after = Unless.new(
        :condition => @literal_true_comment_after,
        :then      => @assignment_a_42,
        :else      => nil
      )
      @node_single_then_comment_before = Unless.new(
        :condition => @literal_true,
        :then      => @assignment_a_42_comment_before,
        :else      => nil
      )
      @node_single_then_comment_after = Unless.new(
        :condition => @literal_true,
        :then      => @assignment_a_42_comment_after,
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_single.to_ruby_base(@context_default).should ==
          "a = 42 unless true"

        @node_single_condition_comment_before.to_ruby_base(@context_default).should == [
          "unless # before",
          "  true",
          "  a = 42",
          "end"
        ].join("\n")

        @node_single_condition_comment_after.to_ruby_base(@context_default).should ==
          "a = 42 unless true # after"

        @node_single_then_comment_before.to_ruby_base(@context_default).should == [
          "unless true",
          "  # before",
          "  a = 42",
          "end"
        ].join("\n")

        @node_single_then_comment_after.to_ruby_base(@context_default).should == [
          "unless true",
          "  a = 42 # after",
          "end"
        ].join("\n")

        @node_multi_without_else.to_ruby_base(@context_narrow).should == [
          "unless true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_multi_with_else.to_ruby_base(@context_default).should == [
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
        it "passes correct context to condition" do
          node = Unless.new(
            :condition => check_to_ruby_context(
              @literal_true,
              :width    => 80,
              :shift    => 14,
              :priority => Priority::NONE
            ),
            :then      => @assignment_a_42,
            :else      => nil
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to then" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => check_to_ruby_context(
              @assignment_a_42,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            :else      => nil
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line unless statements" do
        it "passes correct context to condition" do
          node = Unless.new(
            :condition => check_to_ruby_context(
              @literal_true,
              :width    => 78,
              :shift    => 5,
              :priority => Priority::NONE
            ),
            :then      => @statements,
            :else      => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to then" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            :else      => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to else" do
          node = Unless.new(
            :condition => @literal_true,
            :then      => @statements,
            :else      => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_single.single_line_width_base(@context_default).should == 18

        @node_single_condition_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_single_condition_comment_after.single_line_width_base(@context_default).should ==
          26
        @node_single_then_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_single_then_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_multi_without_else.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multi_with_else.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to condition" do
        node = Unless.new(
          :condition => check_single_line_width_context(
            @assignment_a_42,
            :priority => Priority::NONE
          ),
          :then      => @statements,
          :else      => nil
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to then" do
        node = Unless.new(
          :condition => @literal_true,
          :then      => check_single_line_width_context(
            @assignment_a_42,
            :priority => Priority::NONE
          ),
          :else      => nil
        )

        node.single_line_width_base(@context_default)
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_empty.to_ruby_base(@context_default).should == [
          "case 42",
          "end"
        ].join("\n")

        @node_one_when_without_else.to_ruby_base(@context_default).should == [
          "case 42",
          "  when 42",
          "    a = 42",
          "    b = 43",
          "    c = 44",
          "end"
        ].join("\n")

        @node_one_when_with_else.to_ruby_base(@context_default).should == [
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

        @node_multiple_whens_without_else.to_ruby_base(@context_default).should == [
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

        @node_multiple_whens_with_else.to_ruby_base(@context_default).should == [
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

      it "passes correct context to expression" do
        node = Case.new(
          :expression => check_to_ruby_context(
            @literal_42,
            :width    => 78,
            :shift    => 3,
            :priority => Priority::NONE
          ),
          :whens      => [],
          :else       => nil
        )

        node.to_ruby_base(@context_default)
      end

      it "passes correct context to whens" do
        node = Case.new(
          :expression => @literal_42,
          :whens      => [
            check_to_ruby_context(
              @when_42,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @when_43,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @when_44,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          ],
          :else       => nil
        )

        node.to_ruby_base(@context_default)
      end

      it "passes correct context to else" do
        node = Case.new(
          :expression => @literal_42,
          :whens      => [],
          :else       => check_to_ruby_context(
            @else,
            :width    => 78,
            :shift    => 0,
            :priority => Priority::NONE
          )
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_empty.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_one_when_without_else.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_one_when_with_else.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multiple_whens_without_else.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multiple_whens_with_else.single_line_width_base(@context_default).should ==
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

      @node_values_comments_before = When.new(
        :values => [
          @literal_42_comment_before,
          @literal_43_comment_before,
          @literal_44_comment_before
        ],
        :body   => @statements
      )
      @node_values_comments_after = When.new(
        :values => [
          @literal_42_comment_after,
          @literal_43_comment_after,
          @literal_44_comment_after
        ],
        :body   => @statements
      )
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_one_value.to_ruby_base(@context_default).should == [
          "when 42",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")

        @node_multiple_values.to_ruby_base(@context_default).should == [
          "when 42, 43, 44",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")

        @node_values_comments_before.to_ruby_base(@context_default).should == [
          "when",
          "  # before",
          "  42,",
          "  # before",
          "  43,",
          "  # before",
          "  44",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")

        @node_values_comments_after.to_ruby_base(@context_default).should == [
          "when",
          "  42, # after",
          "  43, # after",
          "  44 # after",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")
      end

      describe "for single-line when clauses" do
        it "passes correct context to values" do
          node = When.new(
            :values => [
              check_to_ruby_context(
                @literal_42,
                :width    => 80,
                :shift    => 5,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_43,
                :width    => 80,
                :shift    => 9,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_44,
                :width    => 80,
                :shift    => 13,
                :priority => Priority::NONE
              )
            ],
            :body   => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to body" do
          node = When.new(
            :values => [@literal_42],
            :body   => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line when clauses" do
        it "passes correct context to values" do
          node = When.new(
            :values => [
              check_to_ruby_context(
                @literal_42_comment_before,
                :width    => 78,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_43_comment_before,
                :width    => 78,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_44_comment_after,
                :width    => 78,
                :shift    => 0,
                :priority => Priority::NONE
              )
            ],
            :body   => @statements
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to body" do
          node = When.new(
            :values => [@literal_42_comment_before],
            :body   => check_to_ruby_context(
              @statements,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_one_value.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multiple_values.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_values_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_values_comments_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end
    end
  end

  describe Else, :type => :ruby do
    before :each do
      @node = Else.new(:body => @statements)
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == [
          "else",
          "  a = 42",
          "  b = 43",
          "  c = 44"
        ].join("\n")
      end

      it "passes correct context to body" do
        node = Else.new(
          :body => check_to_ruby_context(
            @statements,
            :width    => 78,
            :shift    => 0,
            :priority => Priority::NONE
          )
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == Float::INFINITY
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_common.to_ruby_base(@context_default).should == [
          "while true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_wrapper.to_ruby_base(@context_default).should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end while true",
        ].join("\n")
      end

      it "passes correct context to condition" do
        node = While.new(
          :condition => check_to_ruby_context(
            @literal_true,
            :width    => 78,
            :shift    => 4,
            :priority => Priority::NONE
          ),
          :body      => @statements
        )

        node.to_ruby_base(@context_default)
      end

      it "passes correct context to body" do
        node = While.new(
          :condition => @literal_true,
          :body      => check_to_ruby_context(
            @statements,
            :width    => 78,
            :shift    => 0,
            :priority => Priority::NONE
          )
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_common.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_wrapper.single_line_width_base(@context_default).should ==
          Float::INFINITY
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_common.to_ruby_base(@context_default).should == [
          "until true",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end"
        ].join("\n")

        @node_wrapper.to_ruby_base(@context_default).should == [
          "begin",
          "  a = 42",
          "  b = 43",
          "  c = 44",
          "end until true",
        ].join("\n")
      end

      it "passes correct context to condition" do
        node = Until.new(
          :condition => check_to_ruby_context(
            @literal_true,
            :width    => 78,
            :shift    => 4,
            :priority => Priority::NONE
          ),
          :body      => @statements
        )

        node.to_ruby_base(@context_default)
      end

      it "passes correct context to body" do
        node = Until.new(
          :condition => @literal_true,
          :body      => check_to_ruby_context(
            @statements,
            :width    => 78,
            :shift    => 0,
            :priority => Priority::NONE
          )
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_common.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_wrapper.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end
    end
  end

  describe Break, :type => :ruby do
    before :each do
      @node = Break.new
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == "break"
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == 5
      end
    end
  end

  describe Next, :type => :ruby do
    before :each do
      @node_without_value = Next.new(:value => nil)
      @node_with_value    = Next.new(:value => @literal_42)

      @node_value_comment_before = Next.new(
        :value => @literal_42_comment_before
      )
      @node_value_comment_after = Next.new(
        :value => @literal_42_comment_after
      )
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_without_value.to_ruby_base(@context_default).should == "next"

        @node_with_value.to_ruby_base(@context_default).should == "next 42"

        @node_value_comment_before.to_ruby_base(@context_default).should == [
          "next (",
          "  # before",
          "  42",
          ")"
        ].join("\n")

        @node_value_comment_after.to_ruby_base(@context_default).should ==
          "next 42 # after"
      end

      describe "for single-line next statements" do
        it "passes correct context to value" do
          node = Next.new(
            :value => check_to_ruby_context(
              @literal_42,
              :width    => 80,
              :shift    => 5,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line next statements" do
        it "passes correct context to value" do
          node = Next.new(
            :value => check_to_ruby_context(
              @literal_42_comment_before,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_without_value.single_line_width_base(@context_default).should == 4
        @node_with_value.single_line_width_base(@context_default).should    == 7

        @node_value_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_value_comment_after.single_line_width_base(@context_default).should ==
          15
      end

      it "passes correct context to value" do
        node = Next.new(
          :value => check_single_line_width_context(
            @literal_42,
            :priority => Priority::NONE
          )
        )

        node.single_line_width_base(@context_default)
      end
    end
  end

  describe Return, :type => :ruby do
    before :each do
      @node_without_value = Return.new(:value => nil)
      @node_with_value    = Return.new(:value => @literal_42)

      @node_value_comment_before = Return.new(
        :value => @literal_42_comment_before
      )
      @node_value_comment_after = Return.new(
        :value => @literal_42_comment_after
      )
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_without_value.to_ruby_base(@context_default).should == "return"

        @node_with_value.to_ruby_base(@context_default).should == "return 42"

        @node_value_comment_before.to_ruby_base(@context_default).should == [
          "return (",
          "  # before",
          "  42",
          ")"
        ].join("\n")

        @node_value_comment_after.to_ruby_base(@context_default).should ==
          "return 42 # after"
      end

      describe "for single-line next statements" do
        it "passes correct context to value" do
          node = Return.new(
            :value => check_to_ruby_context(
              @literal_42,
              :width    => 80,
              :shift    => 7,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line next statements" do
        it "passes correct context to value" do
          node = Return.new(
            :value => check_to_ruby_context(
              @literal_42_comment_before,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_without_value.single_line_width_base(@context_default).should == 6
        @node_with_value.single_line_width_base(@context_default).should    == 9

        @node_value_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_value_comment_after.single_line_width_base(@context_default).should ==
          17
      end

      it "passes correct context to value" do
        node = Return.new(
          :value => check_single_line_width_context(
            @literal_42,
            :priority => Priority::NONE
          )
        )

        node.single_line_width_base(@context_default)
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

    describe "#to_ruby_base" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_empty.to_ruby_base(@context_default).should == "()"

          @node_one.to_ruby_base(@context_default).should == "(42)"

          @node_multiple.to_ruby_base(@context_default).should == "(42; 43; 44)"

          @node_multiline.to_ruby_base(@context_default).should == [
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

          @node_comments_before.to_ruby_base(@context_default).should == [
            "(",
            "  # before",
            "  42;",
            "  # before",
            "  43;",
            "  # before",
            "  44",
            ")"
          ].join("\n")

          @node_comments_after.to_ruby_base(@context_default).should == [
            "(",
            "  42; # after",
            "  43; # after",
            "  44 # after",
            ")"
          ].join("\n")
        end

        it "passes correct context to expressions" do
          node = Expressions.new(
            :expressions => [
              check_to_ruby_context(
                @literal_42,
                :width    => 80,
                :shift    => 1,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_43,
                :width    => 80,
                :shift    => 5,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_44,
                :width    => 80,
                :shift    => 9,
                :priority => Priority::NONE
              )
            ]
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_empty.to_ruby_base(@context_narrow).should == "()"

          @node_one.to_ruby_base(@context_narrow).should == [
            "(",
            "  42",
            ")"
          ].join("\n")

          @node_multiple.to_ruby_base(@context_narrow).should == [
            "(",
            "  42;",
            "  43;",
            "  44",
            ")"
          ].join("\n")

          @node_multiline.to_ruby_base(@context_narrow).should == [
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

          @node_comments_before.to_ruby_base(@context_narrow).should == [
            "(",
            "  # before",
            "  42;",
            "  # before",
            "  43;",
            "  # before",
            "  44",
            ")"
          ].join("\n")

          @node_comments_after.to_ruby_base(@context_narrow).should == [
            "(",
            "  42; # after",
            "  43; # after",
            "  44 # after",
            ")"
          ].join("\n")
        end

        it "passes correct context to expressions" do
          node = Expressions.new(
            :expressions => [
              check_to_ruby_context(
                @literal_42,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_43,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_44,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              )
            ]
          )

          node.to_ruby_base(@context_narrow)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_empty.single_line_width_base(@context_default).should    == 2
        @node_one.single_line_width_base(@context_default).should      == 4
        @node_multiple.single_line_width_base(@context_default).should == 12

        @node_multiline.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_comments_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to expressions" do
        node = Expressions.new(
          :expressions => [
            check_single_line_width_context(
              @literal_42,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @literal_43,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @literal_44,
              :priority => Priority::NONE
            )
          ]
        )

        node.single_line_width_base(@context_default)
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == "a = 42"

        @node_lhs_comment_before.to_ruby_base(@context_default).should == [
          "# before",
          "a = 42"
        ].join("\n")

        @node_lhs_comment_after.to_ruby_base(@context_default).should == [
          "a = # after",
          "  42"
        ].join("\n")

        @node_rhs_comment_before.to_ruby_base(@context_default).should == [
          "a =",
          "  # before",
          "  42"
        ].join("\n")

        @node_rhs_comment_after.to_ruby_base(@context_default).should ==
          "a = 42 # after"
      end

      describe "for single-line assignments" do
        it "passes correct context to lhs" do
          node = Assignment.new(
            :lhs => check_to_ruby_context(
              @variable_a,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::ASSIGNMENT
            ),
            :rhs => @literal_42
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to rhs" do
          node = Assignment.new(
            :lhs => @variable_a,
            :rhs => check_to_ruby_context(
              @literal_42,
              :width    => 80,
              :shift    => 4,
              :priority => Priority::ASSIGNMENT
            )
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line assignments" do
        it "passes correct context to lhs" do
          node = Assignment.new(
            :lhs => check_to_ruby_context(
              @variable_a_comment_after,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::ASSIGNMENT
            ),
            :rhs => @literal_42
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to rhs" do
          node = Assignment.new(
            :lhs => @variable_a,
            :rhs => check_to_ruby_context(
              @literal_42_comment_before,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::ASSIGNMENT
            )
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == 6

        @node_lhs_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_lhs_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_rhs_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_rhs_comment_after.single_line_width_base(@context_default).should ==
          14
      end

      it "passes correct context to lhs" do
        node = Assignment.new(
          :lhs => check_single_line_width_context(
            @variable_a,
            :priority => Priority::ASSIGNMENT
          ),
          :rhs => @literal_42
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to rhs" do
        node = Assignment.new(
          :lhs => @variable_a,
          :rhs => check_single_line_width_context(
            @literal_42,
            :priority => Priority::ASSIGNMENT
          )
        )

        node.single_line_width_base(@context_default)
      end
    end
  end

  describe UnaryOperator, :type => :ruby do
    before :each do
      @node_simple = UnaryOperator.new(
        :op         => "+",
        :expression => @literal_42,
      )
      @node_complex = UnaryOperator.new(
        :op         => "+",
        :expression => @binary_operator_42_plus_43,
      )
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_simple.to_ruby_base(@context_default).should == "+42"

        @node_complex.to_ruby_base(@context_default).should == "+(42 + 43)"
      end

      it "passes correct context to expression" do
        node = UnaryOperator.new(
          :op         => "+",
          :expression => check_to_ruby_context(
            @literal_42,
            :width    => 80,
            :shift    => 1,
            :priority => Priority::UNARY
          ),
        )

        node.to_ruby_base(@context_default)
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_simple.single_line_width_base(@context_default).should  == 3
        @node_complex.single_line_width_base(@context_default).should == 10
      end

      it "passes correct context to expression" do
        node = UnaryOperator.new(
          :op         => "+",
          :expression => check_single_line_width_context(
            @literal_42,
            :priority => Priority::UNARY
          ),
        )

        node.single_line_width_base(@context_default)
      end
    end
  end

  describe BinaryOperator, :type => :ruby do
    before :each do
      @node_simple = BinaryOperator.new(
        :op  => "+",
        :lhs => @literal_42,
        :rhs => @literal_43
      )
      @node_complex = BinaryOperator.new(
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

    describe "#to_ruby_base" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_simple.to_ruby_base(@context_default).should == "42 + 43"

          @node_complex.to_ruby_base(@context_default).should ==
            "42 + 43 + 44 + 45"

          @node_lhs_comment_before.to_ruby_base(@context_default).should == [
            "# before",
            "42 + 43"
          ].join("\n")

          @node_lhs_comment_after.to_ruby_base(@context_default).should == [
            "42 + # after",
            "  43"
          ].join("\n")

          @node_rhs_comment_before.to_ruby_base(@context_default).should == [
            "42 +",
            "  # before",
            "  43"
          ].join("\n")

          @node_rhs_comment_after.to_ruby_base(@context_default).should ==
            "42 + 43 # after"
        end

        it "passes correct context to lhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => check_to_ruby_context(
              @binary_operator_42_plus_43,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::ADD
            ),
            :rhs => @binary_operator_44_plus_45
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to rhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @binary_operator_42_plus_43,
            :rhs => check_to_ruby_context(
              @binary_operator_44_plus_45,
              :width    => 80,
              :shift    => 10,
              :priority => Priority::ADD
            )
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_simple.to_ruby_base(@context_narrow).should ==
            "42 + 43"

          @node_complex.to_ruby_base(@context_narrow).should == [
            "42 + 43 +",
            "  44 + 45"
          ].join("\n")

          @node_lhs_comment_before.to_ruby_base(@context_narrow).should == [
            "# before",
            "42 + 43"
          ].join("\n")

          @node_lhs_comment_after.to_ruby_base(@context_narrow).should == [
            "42 + # after",
            "  43"
          ].join("\n")

          @node_rhs_comment_before.to_ruby_base(@context_narrow).should == [
            "42 +",
            "  # before",
            "  43"
          ].join("\n")

          @node_rhs_comment_after.to_ruby_base(@context_narrow).should ==
            "42 + 43 # after"
        end

        it "passes correct context to lhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => check_to_ruby_context(
              @binary_operator_42_plus_43,
              :width    => 0,
              :shift    => 0,
              :priority => Priority::ADD
            ),
            :rhs => @binary_operator_44_plus_45
          )

          node.to_ruby_base(@context_narrow)
        end

        it "passes correct context to rhs" do
          node = BinaryOperator.new(
            :op  => "+",
            :lhs => @binary_operator_42_plus_43,
            :rhs => check_to_ruby_context(
              @binary_operator_44_plus_45,
              :width    => -2,
              :shift    => 0,
              :priority => Priority::ADD
            )
          )

          node.to_ruby_base(@context_narrow)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_simple.single_line_width_base(@context_default).should  == 7
        @node_complex.single_line_width_base(@context_default).should == 17

        @node_lhs_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_lhs_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_rhs_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_rhs_comment_after.single_line_width_base(@context_default).should ==
          15
      end

      it "passes correct context to lhs" do
        node = BinaryOperator.new(
          :op  => "+",
          :lhs => check_single_line_width_context(
            @literal_42,
            :priority => Priority::ADD
          ),
          :rhs => @literal_43
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to rhs" do
        node = BinaryOperator.new(
          :op  => "+",
          :lhs => @literal_42,
          :rhs => check_single_line_width_context(
            @literal_43,
            :priority => Priority::ADD
          )
        )

        node.single_line_width_base(@context_default)
      end
    end
  end

  describe TernaryOperator, :type => :ruby do
    before :each do
      @node_simple = TernaryOperator.new(
        :condition => @literal_true,
        :then      => @literal_42,
        :else      => @literal_43
      )
      @node_complex = TernaryOperator.new(
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

    describe "#to_ruby_base" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_simple.to_ruby_base(@context_default).should ==
            "true ? 42 : 43"

          @node_complex.to_ruby_base(@context_default).should ==
            "true || false ? 42 + 43 : 44 + 45"

          @node_condition_comment_before.to_ruby_base(@context_default).should == [
            "# before",
            "true ? 42 : 43"
          ].join("\n")

          @node_condition_comment_after.to_ruby_base(@context_default).should == [
            "true ? # after",
            "  42 :",
            "  43"
          ].join("\n")

          @node_then_comment_before.to_ruby_base(@context_default).should == [
            "true ?",
            "  # before",
            "  42 :",
            "  43"
          ].join("\n")

          @node_then_comment_after.to_ruby_base(@context_default).should == [
            "true ?",
            "  42 : # after",
            "  43"
          ].join("\n")

          @node_else_comment_before.to_ruby_base(@context_default).should == [
            "true ?",
            "  42 :",
            "  # before",
            "  43"
          ].join("\n")

          @node_else_comment_after.to_ruby_base(@context_default).should ==
            "true ? 42 : 43 # after"
        end

        it "passes correct context to condition" do
          node = TernaryOperator.new(
            :condition => check_to_ruby_context(
              @literal_true,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::TERNARY
            ),
            :then      => @binary_operator_42_plus_43,
            :else      => @binary_operator_44_plus_45
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to then" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => check_to_ruby_context(
              @binary_operator_42_plus_43,
              :width    => 80,
              :shift    => 7,
              :priority => Priority::TERNARY
            ),
            :else      => @binary_operator_44_plus_45
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to else" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => @binary_operator_42_plus_43,
            :else      => check_to_ruby_context(
              @binary_operator_44_plus_45,
              :width    => 80,
              :shift    => 17,
              :priority => Priority::TERNARY
            ),
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_simple.to_ruby_base(@context_narrow).should == "true ? 42 : 43"

          @node_complex.to_ruby_base(@context_narrow).should == [
            "true || false ?",
            "  42 + 43 :",
            "  44 + 45"
          ].join("\n")

          @node_condition_comment_before.to_ruby_base(@context_narrow).should == [
            "# before",
            "true ? 42 : 43"
          ].join("\n")

          @node_condition_comment_after.to_ruby_base(@context_narrow).should == [
            "true ? # after",
            "  42 :",
            "  43"
          ].join("\n")

          @node_then_comment_before.to_ruby_base(@context_narrow).should == [
            "true ?",
            "  # before",
            "  42 :",
            "  43"
          ].join("\n")

          @node_then_comment_after.to_ruby_base(@context_narrow).should == [
            "true ?",
            "  42 : # after",
            "  43"
          ].join("\n")

          @node_else_comment_before.to_ruby_base(@context_narrow).should == [
            "true ?",
            "  42 :",
            "  # before",
            "  43"
          ].join("\n")

          @node_else_comment_after.to_ruby_base(@context_narrow).should ==
            "true ? 42 : 43 # after"
        end

        it "passes correct context to condition" do
          node = TernaryOperator.new(
            :condition => check_to_ruby_context(
              @literal_true,
              :width    => 0,
              :shift    => 0,
              :priority => Priority::TERNARY
            ),
            :then      => @binary_operator_42_plus_43,
            :else      => @binary_operator_44_plus_45
          )

          node.to_ruby_base(@context_narrow)
        end

        it "passes correct context to then" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => check_to_ruby_context(
              @binary_operator_42_plus_43,
              :width    => -2,
              :shift    => 0,
              :priority => Priority::TERNARY
            ),
            :else      => @binary_operator_44_plus_45
          )

          node.to_ruby_base(@context_narrow)
        end

        it "passes correct context to else" do
          node = TernaryOperator.new(
            :condition => @literal_true,
            :then      => @binary_operator_42_plus_43,
            :else      => check_to_ruby_context(
              @binary_operator_44_plus_45,
              :width    => -2,
              :shift    => 0,
              :priority => Priority::TERNARY
            ),
          )

          node.to_ruby_base(@context_narrow)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_simple.single_line_width_base(@context_default).should  == 14
        @node_complex.single_line_width_base(@context_default).should == 33

        @node_condition_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_condition_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_then_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_then_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_else_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_else_comment_after.single_line_width_base(@context_default).should ==
          22
      end

      it "passes correct context to condition" do
        node = TernaryOperator.new(
          :condition => check_single_line_width_context(
            @literal_true,
            :priority => Priority::TERNARY
          ),
          :then      => @literal_42,
          :else      => @literal_43
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to then" do
        node = TernaryOperator.new(
          :condition => @literal_true,
          :then      => check_single_line_width_context(
            @literal_42,
            :priority => Priority::TERNARY
          ),
          :else      => @literal_43
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to else" do
        node = TernaryOperator.new(
          :condition => @literal_true,
          :then      => @literal_42,
          :else      => check_single_line_width_context(
            @literal_43,
            :priority => Priority::TERNARY
          ),
        )

        node.single_line_width_base(@context_default)
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

      @node_receiver_comment_before = MethodCall.new(
        :receiver => @variable_a_comment_before,
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

      @node_parens_const = MethodCall.new(
        :receiver => nil,
        :name     => "M",
        :args     => [],
        :block    => nil,
        :parens   => true
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
      @node_parens_aligned_args = MethodCall.new(
        :receiver => nil,
        :name     => "m",
        :args     => [
          @hash_entry_a_42,
          @hash_entry_aa_43,
          @hash_entry_aaa_44
        ],
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
        :block    => @block,
        :parens   => true
      )

      @node_no_parens_const = MethodCall.new(
        :receiver => nil,
        :name     => "M",
        :args     => [],
        :block    => nil,
        :parens   => false
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
        :block    => @block,
        :parens   => false
      )
    end

    describe "#to_ruby_base" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_without_receiver.to_ruby_base(@context_default).should == "m"

          @node_with_receiver.to_ruby_base(@context_default).should == "a.m"

          @node_receiver_comment_before.to_ruby_base(@context_default).should == [
            "# before",
            "a.m"
          ].join("\n")

          @node_receiver_comment_after.to_ruby_base(@context_default).should == [
            "a. # after",
            "  m"
          ].join("\n")

          @node_parens_const.to_ruby_base(@context_default).should == "M()"

          @node_parens_no_args.to_ruby_base(@context_default).should == "m"

          @node_parens_one_arg.to_ruby_base(@context_default).should == "m(42)"

          @node_parens_multiple_args.to_ruby_base(@context_default).should ==
            "m(42, 43, 44)"

          @node_parens_aligned_args.to_ruby_base(@context_default).should ==
            "m(:a => 42, :aa => 43, :aaa => 44)"

          @node_parens_args_comments_before.to_ruby_base(@context_default).should == [
            "m(",
            "  # before",
            "  42,",
            "  # before",
            "  43,",
            "  # before",
            "  44",
            ")"
          ].join("\n")

          @node_parens_args_comments_after.to_ruby_base(@context_default).should == [
            "m(",
            "  42, # after",
            "  43, # after",
            "  44 # after",
            ")"
          ].join("\n")

          @node_parens_without_block.to_ruby_base(@context_default).should ==
            "m"

          @node_parens_with_block.to_ruby_base(@context_default).should == [
            "m do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_no_parens_const.to_ruby_base(@context_default).should == "M()"

          @node_no_parens_no_args.to_ruby_base(@context_default).should == "m"

          @node_no_parens_one_arg.to_ruby_base(@context_default).should ==
            "m 42"

          @node_no_parens_multiple_args.to_ruby_base(@context_default).should ==
            "m 42, 43, 44"

          @node_no_parens_without_block.to_ruby_base(@context_default).should ==
            "m"

          @node_no_parens_with_block.to_ruby_base(@context_default).should == [
            "m do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_without_receiver.to_ruby_base(@context_narrow).should == "m"

          @node_with_receiver.to_ruby_base(@context_narrow).should == "a.m"

          @node_receiver_comment_before.to_ruby_base(@context_narrow).should == [
            "# before",
            "a.m"
          ].join("\n")

          @node_receiver_comment_after.to_ruby_base(@context_narrow).should == [
            "a. # after",
            "  m"
          ].join("\n")

          @node_parens_const.to_ruby_base(@context_narrow).should == [
            "M(",
            ")"
          ].join("\n")

          @node_parens_no_args.to_ruby_base(@context_narrow).should == [
            "m(",
            ")"
          ].join("\n")

          @node_parens_one_arg.to_ruby_base(@context_narrow).should == [
            "m(",
            "  42",
            ")"
          ].join("\n")

          @node_parens_multiple_args.to_ruby_base(@context_narrow).should == [
            "m(",
            "  42,",
            "  43,",
            "  44",
            ")"
          ].join("\n")

          @node_parens_aligned_args.to_ruby_base(@context_narrow).should == [
            "m(",
            "  :a   => 42,",
            "  :aa  => 43,",
            "  :aaa => 44",
            ")"
          ].join("\n")

          @node_parens_args_comments_before.to_ruby_base(@context_narrow).should == [
            "m(",
            "  # before",
            "  42,",
            "  # before",
            "  43,",
            "  # before",
            "  44",
            ")"
          ].join("\n")

          @node_parens_args_comments_after.to_ruby_base(@context_narrow).should == [
            "m(",
            "  42, # after",
            "  43, # after",
            "  44 # after",
            ")"
          ].join("\n")

          @node_parens_without_block.to_ruby_base(@context_narrow).should == [
            "m(",
            ")"
          ].join("\n")

          @node_parens_with_block.to_ruby_base(@context_narrow).should == [
            "m(",
            ") do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_no_parens_const.to_ruby_base(@context_narrow).should == "M()"

          @node_no_parens_no_args.to_ruby_base(@context_narrow).should == "m"

          @node_no_parens_one_arg.to_ruby_base(@context_narrow).should == "m 42"

          @node_no_parens_multiple_args.to_ruby_base(@context_narrow).should ==
            "m 42, 43, 44"

          @node_no_parens_without_block.to_ruby_base(@context_narrow).should ==
            "m"

          @node_no_parens_with_block.to_ruby_base(@context_narrow).should == [
            "m do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end
      end

      it "passes correct context to receiver" do
        node = MethodCall.new(
          :receiver => check_to_ruby_context(
            @variable_a,
            :width    => 80,
            :shift    => 0,
            :priority => Priority::ATOMIC
          ),
          :name     => "m",
          :args     => [],
          :block    => nil,
          :parens   => false
        )

        node.to_ruby_base(@context_default)
      end

      describe "on method calls with :parens => true" do
        describe "for single-line method calls" do
          it "passes correct context to args" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [
                check_to_ruby_context(
                  @literal_42,
                  :width    => 80,
                  :shift    => 3,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @literal_43,
                  :width    => 80,
                  :shift    => 7,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @literal_44,
                  :width    => 80,
                  :shift    => 11,
                  :priority => Priority::NONE
                )
              ],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby_base(@context_default)
          end

          it "passes correct context to block" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [],
              :block    => check_to_ruby_context(
                @block,
                :width    => 80,
                :shift    => 3,
                :priority => Priority::NONE
              ),
              :parens   => true
            )

            node.to_ruby_base(@context_default)
          end
        end

        describe "for multi-line method calls" do
          it "passes correct context to args" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [
                check_to_ruby_context(
                  @literal_42,
                  :width    => -2,
                  :shift    => 0,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @literal_43,
                  :width    => -2,
                  :shift    => 0,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @literal_44,
                  :width    => -2,
                  :shift    => 0,
                  :priority => Priority::NONE
                )
              ],
              :block    => nil,
              :parens   => true
            )

            node.to_ruby_base(@context_narrow)
          end

          it "passes correct context to block" do
            node = MethodCall.new(
              :receiver => @variable_a,
              :name     => "m",
              :args     => [],
              :block    => check_to_ruby_context(
                @block,
                :width    => 0,
                :shift    => 1,
                :priority => Priority::NONE
              ),
              :parens   => true
            )

            node.to_ruby_base(@context_narrow)
          end
        end
      end

      describe "on method calls with :parens => false" do
        it "passes correct context to args" do
          node = MethodCall.new(
            :receiver => @variable_a,
            :name     => "m",
            :args     => [
              check_to_ruby_context(
                @literal_42,
                :width    => 80,
                :shift    => 3,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_43,
                :width    => 80,
                :shift    => 7,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_44,
                :width    => 80,
                :shift    => 11,
                :priority => Priority::NONE
              )
            ],
            :block    => nil,
            :parens   => false
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to block" do
          node = MethodCall.new(
            :receiver => @variable_a,
            :name     => "m",
            :args     => [],
            :block    => check_to_ruby_context(
              @block,
              :width    => 80,
              :shift    => 3,
              :priority => Priority::NONE
            ),
            :parens   => false
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_without_receiver.single_line_width_base(@context_default).should ==
          1
        @node_with_receiver.single_line_width_base(@context_default).should ==
          3

        @node_receiver_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_receiver_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_parens_const.single_line_width_base(@context_default).should ==
          3
        @node_parens_no_args.single_line_width_base(@context_default).should ==
          1
        @node_parens_one_arg.single_line_width_base(@context_default).should ==
          5
        @node_parens_multiple_args.single_line_width_base(@context_default).should ==
          13
        @node_parens_aligned_args.single_line_width_base(@context_default).should ==
          34
        @node_parens_args_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_parens_args_comments_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_parens_without_block.single_line_width_base(@context_default).should ==
          1
        @node_parens_with_block.single_line_width_base(@context_default).should ==
          1

        @node_no_parens_const.single_line_width_base(@context_default).should ==
          3
        @node_no_parens_no_args.single_line_width_base(@context_default).should ==
          1
        @node_no_parens_one_arg.single_line_width_base(@context_default).should ==
          4
        @node_no_parens_multiple_args.single_line_width_base(@context_default).should ==
          12
        @node_no_parens_without_block.single_line_width_base(@context_default).should ==
          1
        @node_no_parens_with_block.single_line_width_base(@context_default).should ==
          1
      end

      it "passes correct context to receiver" do
        node = MethodCall.new(
          :receiver => check_single_line_width_context(
            @variable_a,
            :priority => Priority::ATOMIC
          ),
          :name     => "m",
          :args     => [],
          :block    => nil,
          :parens   => false
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to args" do
        node = MethodCall.new(
          :receiver => @variable_a,
          :name     => "m",
          :args     => [
            check_single_line_width_context(
              @literal_42,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @literal_43,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @literal_44,
              :priority => Priority::NONE
            )
          ],
          :block    => nil,
          :parens   => false
        )

        node.single_line_width_base(@context_default)
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

      @node_single_args_comments_before = Block.new(
        :args       => [
          @variable_a_comment_before,
          @variable_b_comment_before,
          @variable_c_comment_before
        ],
        :statements => @assignment_a_42
      )
      @node_single_args_comments_after = Block.new(
        :args       => [
          @variable_a_comment_after,
          @variable_b_comment_after,
          @variable_c_comment_after
        ],
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

      @node_multi_args_comments_before = Block.new(
        :args       => [
          @variable_a_comment_before,
          @variable_b_comment_before,
          @variable_c_comment_before
        ],
        :statements => @statements
      )
      @node_multi_args_comments_after = Block.new(
        :args       => [
          @variable_a_comment_after,
          @variable_b_comment_after,
          @variable_c_comment_after
        ],
        :statements => @statements
      )
    end

    describe "#to_ruby_base" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_single_no_args.to_ruby_base(@context_default).should ==
            "{ a = 42 }"

          @node_single_one_arg.to_ruby_base(@context_default).should ==
            "{ |a| a = 42 }"

          @node_single_multiple_args.to_ruby_base(@context_default).should ==
            "{ |a, b, c| a = 42 }"

          @node_single_args_comments_before.to_ruby_base(@context_narrow).should == [
            "do |",
            "  # before",
            "  a,",
            "  # before",
            "  b,",
            "  # before",
            "  c",
            "|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_single_args_comments_after.to_ruby_base(@context_narrow).should == [
            "do |",
            "  a, # after",
            "  b, # after",
            "  c # after",
            "|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_multi_no_args.to_ruby_base(@context_narrow).should == [
            "do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_one_arg.to_ruby_base(@context_narrow).should == [
            "do |a|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_multiple_args.to_ruby_base(@context_narrow).should == [
            "do |a, b, c|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_args_comments_before.to_ruby_base(@context_narrow).should == [
            "do |",
            "  # before",
            "  a,",
            "  # before",
            "  b,",
            "  # before",
            "  c",
            "|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_args_comments_after.to_ruby_base(@context_narrow).should == [
            "do |",
            "  a, # after",
            "  b, # after",
            "  c # after",
            "|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        describe "for blocks with uncommented args" do
          it "passes correct context to args" do
            node = Block.new(
              :args       => [
                check_to_ruby_context(
                  @variable_a,
                  :width    => 80,
                  :shift    => 3,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_b,
                  :width    => 80,
                  :shift    => 6,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_c,
                  :width    => 80,
                  :shift    => 9,
                  :priority => Priority::NONE
                )
              ],
              :statements => @assignment_a_42
            )

            node.to_ruby_base(@context_default)
          end

          it "passes correct context to statements" do
            node = Block.new(
              :args       => [],
              :statements => check_to_ruby_context(
                @assignment_a_42,
                :width    => 80,
                :shift    => 2,
                :priority => Priority::NONE
              )
            )

            node.to_ruby_base(@context_default)
          end
        end

        describe "for blocks with commented args" do
          it "passes correct context to args" do
            node = Block.new(
              :args       => [
                check_to_ruby_context(
                  @variable_a_comment_before,
                  :width    => 78,
                  :shift    => 0,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_b_comment_before,
                  :width    => 78,
                  :shift    => 0,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_c_comment_before,
                  :width    => 78,
                  :shift    => 0,
                  :priority => Priority::NONE
                )
              ],
              :statements => @assignment_a_42
            )

            node.to_ruby_base(@context_default)
          end

          it "passes correct context to statements" do
            node = Block.new(
              :args       => [@variable_a_comment_before],
              :statements => check_to_ruby_context(
                @assignment_a_42,
                :width    => 78,
                :shift    => 0,
                :priority => Priority::NONE
              )
            )

            node.to_ruby_base(@context_default)
          end
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_single_no_args.to_ruby_base(@context_narrow).should == [
            "do",
            "  a = 42",
            "end"
          ].join("\n")

          @node_single_one_arg.to_ruby_base(@context_narrow).should == [
            "do |a|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_single_multiple_args.to_ruby_base(@context_narrow).should == [
            "do |a, b, c|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_single_args_comments_before.to_ruby_base(@context_narrow).should == [
            "do |",
            "  # before",
            "  a,",
            "  # before",
            "  b,",
            "  # before",
            "  c",
            "|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_single_args_comments_after.to_ruby_base(@context_narrow).should == [
            "do |",
            "  a, # after",
            "  b, # after",
            "  c # after",
            "|",
            "  a = 42",
            "end"
          ].join("\n")

          @node_multi_no_args.to_ruby_base(@context_narrow).should == [
            "do",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_one_arg.to_ruby_base(@context_narrow).should == [
            "do |a|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_multiple_args.to_ruby_base(@context_narrow).should == [
            "do |a, b, c|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_args_comments_before.to_ruby_base(@context_narrow).should == [
            "do |",
            "  # before",
            "  a,",
            "  # before",
            "  b,",
            "  # before",
            "  c",
            "|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")

          @node_multi_args_comments_after.to_ruby_base(@context_narrow).should == [
            "do |",
            "  a, # after",
            "  b, # after",
            "  c # after",
            "|",
            "  a = 42",
            "  b = 43",
            "  c = 44",
            "end"
          ].join("\n")
        end

        describe "for blocks with uncommented args" do
          it "passes correct context to args" do
            node = Block.new(
              :args       => [
                check_to_ruby_context(
                  @variable_a,
                  :width    => 0,
                  :shift    => 4,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_b,
                  :width    => 0,
                  :shift    => 7,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_c,
                  :width    => 0,
                  :shift    => 10,
                  :priority => Priority::NONE
                )
              ],
              :statements => @assignment_a_42
            )

            node.to_ruby_base(@context_narrow)
          end

          it "passes correct context to statements" do
            node = Block.new(
              :args       => [],
              :statements => check_to_ruby_context(
                @assignment_a_42,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              )
            )

            node.to_ruby_base(@context_narrow)
          end
        end

        describe "for blocks with commented args" do
          it "passes correct context to args" do
            node = Block.new(
              :args       => [
                check_to_ruby_context(
                  @variable_a_comment_before,
                  :width    => -2,
                  :shift    => 0,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_b_comment_before,
                  :width    => -2,
                  :shift    => 0,
                  :priority => Priority::NONE
                ),
                check_to_ruby_context(
                  @variable_c_comment_before,
                  :width    => -2,
                  :shift    => 0,
                  :priority => Priority::NONE
                )
              ],
              :statements => @assignment_a_42
            )

            node.to_ruby_base(@context_narrow)
          end

          it "passes correct context to statements" do
            node = Block.new(
              :args       => [@variable_a_comment_before],
              :statements => check_to_ruby_context(
                @assignment_a_42,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              )
            )

            node.to_ruby_base(@context_narrow)
          end
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_single_no_args.single_line_width_base(@context_default).should ==
          10
        @node_single_one_arg.single_line_width_base(@context_default).should ==
          14
        @node_single_multiple_args.single_line_width_base(@context_default).should ==
          20

        @node_single_args_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_single_args_comments_after.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_multi_no_args.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multi_one_arg.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multi_multiple_args.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_multi_args_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_multi_args_comments_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to args" do
        node = Block.new(
          :args       => [
            check_single_line_width_context(
              @variable_a,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @variable_b,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @variable_c,
              :priority => Priority::NONE
            )
          ],
          :statements => @assignment_a_42
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to statements" do
        node = Block.new(
          :args       => [],
          :statements => check_single_line_width_context(
            @assignment_a_42,
            :priority => Priority::NONE
          )
        )

        node.single_line_width_base(@context_default)
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node_without_receiver.to_ruby_base(@context_default).should == "C"

        @node_with_receiver.to_ruby_base(@context_default).should == "a::C"

        @node_receiver_comment_before.to_ruby_base(@context_default).should == [
          "# before",
          "a::C"
        ].join("\n")

        @node_receiver_comment_after.to_ruby_base(@context_default).should == [
          "a:: # after",
          "  C"
        ].join("\n")
      end

      describe "for single-line const accesses" do
        it "passes correct context to receiver" do
          node = ConstAccess.new(
            :receiver => check_to_ruby_context(
              @variable_a,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::ATOMIC
            ),
            :name     => "C"
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line const accesses" do
        it "passes correct context to receiver" do
          node = ConstAccess.new(
            :receiver => check_to_ruby_context(
              @variable_a_comment_after,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::ATOMIC
            ),
            :name     => "C"
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_without_receiver.single_line_width_base(@context_default).should ==
          1
        @node_with_receiver.single_line_width_base(@context_default).should ==
          4

        @node_receiver_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_receiver_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to receiver" do
        node = ConstAccess.new(
          :receiver => check_single_line_width_context(
            @variable_a,
            :priority => Priority::ATOMIC
          ),
          :name     => "C"
        )

        node.single_line_width_base(@context_default)
      end
    end
  end

  describe Variable, :type => :ruby do
    before :each do
      @node = Variable.new(:name => "a")
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == "a"
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == 1
      end
    end
  end

  describe Self, :type => :ruby do
    before :each do
      @node = Self.new
    end

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == "self"
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == 4
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

      @node_string_long_multi_line = Literal.new(
        :value => "abcdefghijklmnop\nabcdefghijklmnop\nabcdefghijklmnop"
      )
    end

    describe "#to_ruby_base" do
      describe "basics" do
        it "emits correct code" do
          @node_nil.to_ruby_base(@context_default).should     == "nil"
          @node_true.to_ruby_base(@context_default).should    == "true"
          @node_false.to_ruby_base(@context_default).should   == "false"
          @node_integer.to_ruby_base(@context_default).should == "42"
          @node_float.to_ruby_base(@context_default).should   == "42.0"
          @node_symbol.to_ruby_base(@context_default).should  == ":abcd"
          @node_string.to_ruby_base(@context_default).should  == "\"abcd\""

          @node_string_long_multi_line.to_ruby_base(@context_default).should == [
            "\"abcdefghijklmnop\\n\" +",
            "  \"abcdefghijklmnop\\n\" +",
            "  \"abcdefghijklmnop\""
          ].join("\n")
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_nil.single_line_width_base(@context_default).should     == 3
        @node_true.single_line_width_base(@context_default).should    == 4
        @node_false.single_line_width_base(@context_default).should   == 5
        @node_integer.single_line_width_base(@context_default).should == 2
        @node_float.single_line_width_base(@context_default).should   == 4
        @node_symbol.single_line_width_base(@context_default).should  == 5
        @node_string.single_line_width_base(@context_default).should  == 6

        @node_string_long_multi_line.single_line_width_base(@context_default).should ==
          Float::INFINITY
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

    describe "#to_ruby_base" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_empty.to_ruby_base(@context_default).should == "[]"

          @node_one.to_ruby_base(@context_default).should == "[42]"

          @node_multiple.to_ruby_base(@context_default).should == "[42, 43, 44]"

          @node_multiline.to_ruby_base(@context_default).should == [
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

          @node_comments_before.to_ruby_base(@context_default).should == [
            "[",
            "  # before",
            "  42,",
            "  # before",
            "  43,",
            "  # before",
            "  44",
            "]"
          ].join("\n")

          @node_comments_after.to_ruby_base(@context_default).should == [
            "[",
            "  42, # after",
            "  43, # after",
            "  44 # after",
            "]"
          ].join("\n")
        end

        it "passes correct context to elements" do
          node = Array.new(
            :elements => [
              check_to_ruby_context(
                @literal_42,
                :width    => 80,
                :shift    => 1,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_43,
                :width    => 80,
                :shift    => 5,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_44,
                :width    => 80,
                :shift    => 9,
                :priority => Priority::NONE
              )
            ]
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_empty.to_ruby_base(@context_narrow).should == "[]"

          @node_one.to_ruby_base(@context_narrow).should == [
            "[",
            "  42",
            "]"
          ].join("\n")

          @node_multiple.to_ruby_base(@context_narrow).should == [
            "[",
            "  42,",
            "  43,",
            "  44",
            "]"
          ].join("\n")

          @node_multiline.to_ruby_base(@context_narrow).should == [
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

          @node_comments_before.to_ruby_base(@context_narrow).should == [
            "[",
            "  # before",
            "  42,",
            "  # before",
            "  43,",
            "  # before",
            "  44",
            "]"
          ].join("\n")

          @node_comments_after.to_ruby_base(@context_narrow).should == [
            "[",
            "  42, # after",
            "  43, # after",
            "  44 # after",
            "]"
          ].join("\n")
        end

        it "passes correct context to elements" do
          node = Array.new(
            :elements => [
              check_to_ruby_context(
                @literal_42,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_43,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              ),
              check_to_ruby_context(
                @literal_44,
                :width    => -2,
                :shift    => 0,
                :priority => Priority::NONE
              )
            ]
          )

          node.to_ruby_base(@context_narrow)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_empty.single_line_width_base(@context_default).should    == 2
        @node_one.single_line_width_base(@context_default).should      == 4
        @node_multiple.single_line_width_base(@context_default).should == 12

        @node_multiline.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_comments_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to elements" do
        node = Array.new(
          :elements => [
            check_single_line_width_context(
              @literal_42,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @literal_43,
              :priority => Priority::NONE
            ),
            check_single_line_width_context(
              @literal_44,
              :priority => Priority::NONE
            )
          ]
        )

        node.single_line_width_base(@context_default)
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

    describe "#to_ruby_base" do
      describe "with lot of space available" do
        it "emits correct code" do
          @node_empty.to_ruby_base(@context_default).should == "{}"

          @node_one.to_ruby_base(@context_default).should == "{ :a => 42 }"

          @node_multiple.to_ruby_base(@context_default).should ==
            "{ :a => 42, :b => 43, :c => 44 }"

          @node_aligned.to_ruby_base(@context_default).should ==
            "{ :a => 42, :aa => 43, :aaa => 44 }"

          @node_multiline.to_ruby_base(@context_default).should == [
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

          @node_comments_before.to_ruby_base(@context_default).should == [
            "{",
            "  # before",
            "  :a => 42,",
            "  # before",
            "  :b => 43,",
            "  # before",
            "  :c => 44",
            "}"
          ].join("\n")

          @node_comments_after.to_ruby_base(@context_default).should == [
            "{",
            "  :a => 42, # after",
            "  :b => 43, # after",
            "  :c => 44 # after",
            "}"
          ].join("\n")
        end

        it "passes correct context to entries" do
          node = Hash.new(:entries => [
            check_to_ruby_context(
              @hash_entry_a_42,
              :width    => 80,
              :shift    => 2,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @hash_entry_b_43,
              :width    => 80,
              :shift    => 12,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @hash_entry_c_44,
              :width    => 80,
              :shift    => 22,
              :priority => Priority::NONE
            )
          ])

          node.to_ruby_base(@context_default)
        end
      end

      describe "with no space available" do
        it "emits correct code" do
          @node_empty.to_ruby_base(@context_narrow).should == "{}"

          @node_one.to_ruby_base(@context_narrow).should == [
            "{",
            "  :a => 42",
            "}"
          ].join("\n")

          @node_multiple.to_ruby_base(@context_narrow).should == [
            "{",
            "  :a => 42,",
            "  :b => 43,",
            "  :c => 44",
            "}"
          ].join("\n")

          @node_aligned.to_ruby_base(@context_narrow).should == [
            "{",
            "  :a   => 42,",
            "  :aa  => 43,",
            "  :aaa => 44",
            "}"
          ].join("\n")

          @node_multiline.to_ruby_base(@context_narrow).should == [
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

          @node_comments_before.to_ruby_base(@context_narrow).should == [
            "{",
            "  # before",
            "  :a => 42,",
            "  # before",
            "  :b => 43,",
            "  # before",
            "  :c => 44",
            "}"
          ].join("\n")

          @node_comments_after.to_ruby_base(@context_narrow).should == [
            "{",
            "  :a => 42, # after",
            "  :b => 43, # after",
            "  :c => 44 # after",
            "}"
          ].join("\n")
        end

        it "passes correct context to entries" do
          node = Hash.new(:entries => [
            check_to_ruby_context(
              @hash_entry_a_42,
              :width    => -2,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @hash_entry_b_43,
              :width    => -2,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            check_to_ruby_context(
              @hash_entry_c_44,
              :width    => -2,
              :shift    => 0,
              :priority => Priority::NONE
            )
          ])

          node.to_ruby_base(@context_narrow)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node_empty.single_line_width_base(@context_default).should    == 2
        @node_one.single_line_width_base(@context_default).should      == 12
        @node_multiple.single_line_width_base(@context_default).should == 32

        @node_multiline.single_line_width_base(@context_default).should ==
          Float::INFINITY

        @node_comments_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_comments_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
      end

      it "passes correct context to entries" do
        node = Hash.new(:entries => [
          check_single_line_width_context(
            @hash_entry_a_42,
            :priority => Priority::NONE
          ),
          check_single_line_width_context(
            @hash_entry_b_43,
            :priority => Priority::NONE
          ),
          check_single_line_width_context(
            @hash_entry_c_44,
            :priority => Priority::NONE
          )
        ])

        node.single_line_width_base(@context_default)
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

    describe "#to_ruby_base" do
      it "emits correct code" do
        @node.to_ruby_base(@context_default).should == ":a => 42"

        @node_key_comment_before.to_ruby_base(@context_default).should == [
          "# before",
          ":a => 42"
        ].join("\n")

        @node_key_comment_after.to_ruby_base(@context_default).should == [
          ":a => # after",
          "  42"
        ].join("\n")

        @node_value_comment_before.to_ruby_base(@context_default).should == [
          ":a =>",
          "  # before",
          "  42"
        ].join("\n")

        @node_value_comment_after.to_ruby_base(@context_default).should ==
          ":a => 42 # after"
      end

      describe "for single-line hash entries" do
        it "passes correct context to key" do
          node = HashEntry.new(
            :key   => check_to_ruby_context(
              @literal_a,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            :value => @literal_42
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to value" do
          node = HashEntry.new(
            :key   => @literal_a,
            :value => check_to_ruby_context(
              @literal_42,
              :width    => 80,
              :shift    => 6,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end

      describe "for multi-line hash entries" do
        it "passes correct context to key" do
          node = HashEntry.new(
            :key   => check_to_ruby_context(
              @literal_a_comment_after,
              :width    => 80,
              :shift    => 0,
              :priority => Priority::NONE
            ),
            :value => @literal_42
          )

          node.to_ruby_base(@context_default)
        end

        it "passes correct context to value" do
          node = HashEntry.new(
            :key   => @literal_a,
            :value => check_to_ruby_context(
              @literal_42_comment_before,
              :width    => 78,
              :shift    => 0,
              :priority => Priority::NONE
            )
          )

          node.to_ruby_base(@context_default)
        end
      end
    end

    describe "#single_line_width_base" do
      it "returns correct value" do
        @node.single_line_width_base(@context_default).should == 8

        @node_key_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_key_comment_after.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_value_comment_before.single_line_width_base(@context_default).should ==
          Float::INFINITY
        @node_value_comment_after.single_line_width_base(@context_default).should ==
          16
      end

      it "passes correct context to key" do
        node = HashEntry.new(
          :key   => check_single_line_width_context(
            @literal_a,
            :priority => Priority::NONE
          ),
          :value => @literal_42
        )

        node.single_line_width_base(@context_default)
      end

      it "passes correct context to value" do
        node = HashEntry.new(
          :key   => @literal_a,
          :value => check_single_line_width_context(
            @literal_42,
            :priority => Priority::NONE
          )
        )

        node.single_line_width_base(@context_default)
      end
    end
  end
end
