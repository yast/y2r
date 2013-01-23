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
          p = YCP::Path.new('.abcd')
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
          t = YCP::Term.new(:a, 42, 43, 44)
        EOT

        Y2R.compile(ycp_code).should == ruby_code
      end
    end
  end
end
