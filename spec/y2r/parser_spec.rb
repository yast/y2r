require "spec_helper"

module Y2R
  describe Parser do
    describe "#parse" do
      it "parses a simple program" do
        ast = AST::Const.new(:type => :void, :value => nil)

        Parser.new.parse("{}", compile_options).should == ast
      end

      it "parses a more complex program" do
        ast = AST::FileBlock.new(
          :kind       => :file,
          :name       => nil,
          :symbols    => [
            AST::Symbol.new(
              :global   => true,
              :category => :filename,
              :type     => "<unspec>",
              :name     => nil
            ),
            AST::Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "i"
            ),
            AST::Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "j"
            ),
            AST::Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => "integer",
              :name     => "k"
            )
          ],
          :statements => [
            AST::Assign.new(
              :name  => "i",
              :child => AST::Const.new(:type => :int, :value => "42")
            ),
            AST::Assign.new(
              :name  => "j",
              :child => AST::Const.new(:type => :int, :value => "43")
            ),
            AST::Assign.new(
              :name  => "k",
              :child => AST::Const.new(:type => :int, :value => "44")
            )
          ]
        )

        Parser.new.parse(cleanup(<<-EOT), compile_options).should == ast
          {
            integer i = 42;
            integer j = 43;
            integer k = 44;
          }
        EOT
      end

      it "raises an exception on syntax error" do
        lambda {
          Parser.new.parse("invalid", compile_options).should == ast
        }.should raise_error Parser::SyntaxError
      end
    end
  end
end
