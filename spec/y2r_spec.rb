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
    end
  end
end
