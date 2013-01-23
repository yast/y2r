require "spec_helper"

module Y2R::AST
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

  describe YCP do
    describe "#to_ruby" do
      it "emits correct code" do
        node = YCP.new(:child => Const.new(:type => "void"))

        node.to_ruby.should == "nil"
      end
    end
  end
end
