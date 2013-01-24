require "spec_helper"

describe Y2R do
  describe ".compile" do
    # The following tests really are integration tests disguised as unit tests.

    describe "values" do
      it "compiles voids correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            void v = nil;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          v = nil
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles booleans correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            boolean t = true;
            boolean f = false;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          t = true
          f = false
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles integers correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            integer i = 42;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          i = 42
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles floats correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            float f = 42.0;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          f = 42.0
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles symbols correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            symbol s = `abcd;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          s = :abcd
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles strings correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            string s = "abcd";
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          s = 'abcd'
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles paths correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            path p = .abcd;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          p = Path.new('.abcd')
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles lists correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            list l = [42, 43, 44];
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          l = [42, 43, 44]
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles maps correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            map m = $[`a: 42, `b: 43, `c: 44];
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          m = { :a => 42, :b => 43, :c => 44 }
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles terms correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            term t = `a(42, 43, 44);
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          t = Term.new(:a, 42, 43, 44)
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end
    end

    describe "expressions" do
      it "compiles comparison operators" do
        ycp_code = cleanup(<<-EOT)
          {
            boolean b = 42 == 43;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          b = Ops.equal(42, 43)
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles unary operators" do
        ycp_code = cleanup(<<-EOT)
          {
            integer i = ~42;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          i = Ops.bitwise_not(42)
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles binary operators" do
        ycp_code = cleanup(<<-EOT)
          {
            integer i = 42 + 43;
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          i = Ops.add(42, 43)
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles builtin calls" do
        ycp_code = cleanup(<<-EOT)
          {
            y2milestone("abcd");
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          Builtins.y2milestone('abcd')
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles function calls" do
        ycp_code = cleanup(<<-EOT)
          {
            UI::OpenDialog(`Label("Hello, world!"));
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          import('UI')
          UI.OpenDialog(Term.new(:Label, 'Hello, world!'))
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end
    end

    describe "statements" do
      it "compiles if statements correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            if (true)
              y2milestone("abcd");
            else
              y2milestone("efgh");
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          if true
            Builtins.y2milestone('abcd')
          else
            Builtins.y2milestone('efgh')
          end
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles while statements correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            while (true)
              y2milestone("abcd");
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          while true
            Builtins.y2milestone('abcd')
          end
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end

      it "compiles imports correctly" do
        ycp_code = cleanup(<<-EOT)
          {
            import "String";
          }
        EOT

        ruby_code = cleanup(<<-EOT)
          import('String')
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end
    end
  end
end
