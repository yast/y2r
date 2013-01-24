require "spec_helper"

module Y2R
  describe Parser do
    describe "#parse" do
      it "parses a simple program" do
        ast = AST::YCP.new(:child => AST::Const.new(:type => "void"))

        Parser.new.parse("{}").should == ast
      end

      it "parses a more complex program" do
        ast = AST::YCP.new(
          :child   => AST::Block.new(
            :kind       => "file",
            :symbols    => AST::Symbols.new(
              :children => [
                AST::Symbol.new,
                AST::Symbol.new(:name => "i"),
                AST::Symbol.new(:name => "j"),
                AST::Symbol.new(:name => "k")
              ]
            ),
            :statements => AST::Statements.new(
              :children => [
                AST::Stmt.new(
                  :child => AST::Assign.new(
                    :name  => "i",
                    :child => AST::Const.new(:type => "int", :value => "42")
                  )
                ),
                AST::Stmt.new(
                  :child => AST::Assign.new(
                    :name  => "j",
                    :child => AST::Const.new(:type => "int", :value => "43")
                  )
                ),
                AST::Stmt.new(
                  :child => AST::Assign.new(
                    :name  => "k",
                    :child => AST::Const.new(:type => "int", :value => "44")
                  )
                )
              ]
            )
          )
        )

        Parser.new.parse(cleanup(<<-EOT)).should == ast
          {
            integer i = 42;
            integer j = 43;
            integer k = 44;
          }
        EOT
      end

      it "raises an exception on syntax error" do
        lambda {
          Parser.new.parse("invalid").should == ast
        }.should raise_error Parser::SyntaxError
      end
    end
  end
end
