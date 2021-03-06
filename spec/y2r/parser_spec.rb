# encoding: utf-8

require "spec_helper"

module Y2R
  describe Parser do
    describe "#parse" do
      it "parses a simple program" do
        ast = AST::YCP::Const.new(
          :filename => "default.ycp",
          :type     => :void,
          :value    => nil
        )

        Parser.new(compile_options).parse("{}").should == ast
      end

      it "parses a more complex program" do
        ast = AST::YCP::FileBlock.new(
          :filename   => "default.ycp",
          :name       => nil,
          :symbols    => [
            AST::YCP::Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => AST::YCP::Type.new("integer"),
              :name     => "i"
            ),
            AST::YCP::Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => AST::YCP::Type.new("integer"),
              :name     => "j"
            ),
            AST::YCP::Symbol.new(
              :global   => false,
              :category => :variable,
              :type     => AST::YCP::Type.new("integer"),
              :name     => "k"
            )
          ],
          :statements => [
            AST::YCP::Assign.new(
              :ns    => nil,
              :name  => "i",
              :child => AST::YCP::Const.new(:type => :int, :value => "42")
            ),
            AST::YCP::Assign.new(
              :ns    => nil,
              :name  => "j",
              :child => AST::YCP::Const.new(:type => :int, :value => "43")
            ),
            AST::YCP::Assign.new(
              :ns            => nil,
              :name          => "k",
              :child         => AST::YCP::Const.new(:type => :int, :value => "44"),
              :comment_after => " \n"
            )
          ]
        )

        Parser.new(compile_options).parse(cleanup(<<-EOT)).should == ast
          {
            integer i = 42;
            integer j = 43;
            integer k = 44;
          }
        EOT
      end

      it "raises an exception on syntax error" do
        lambda {
          Parser.new(compile_options).parse("invalid")
        }.should raise_error Parser::SyntaxError
      end
    end
  end
end
