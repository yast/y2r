require "redcarpet"

class RSpecRenderer < Redcarpet::Render::Base
  INDENT_STEP = 2

  def initialize
    super

    @level = 0
    @separate = false
  end

  def header(text, header_level)
    case header_level
      when 1, 4 # 1 = top level header, 4 = code block header
        nil
      when 2, 3
        level = header_level - 1
        raise "Missing higher level header: #{text}" if level > @level + 1

        lines = []

        lines << pop_describe while @level >= level
        lines << "" if @separate
        lines << push_describe(text.downcase)

        join(lines)
      else
        raise "Invalid header level: #{header_level}."
    end
  end

  def paragraph(text)
    @description = text.split(".").first.sub(/^Y2R /, "")

    nil
  end

  def block_code(code, language)
    case language
      when "ycp"
        raise "Unexpected YCP code: #{code}." if @ycp_code
        @ycp_code = code[0..-2]
      when "ruby"
        raise "Unexpected Ruby code: #{code}." if !@ycp_code
        @ruby_code = code[0..-2]
      when "error"
        raise "Unexpected error message: #{code}." if !@ycp_code
        @error_code = code[0..-2]
      else
        raise "Invalid language: #{language}."
    end

    if @ycp_code && (@ruby_code || @error_code)
      lines = []

      lines << "" if @separate
      lines << "it \"#{@description}\" do"
      lines << "  ycp_code = cleanup(<<-EOT)"
      lines << indent(@ycp_code, 2)
      lines << "  EOT"
      lines << ""
      if @ruby_code
        lines << "  ruby_code = cleanup(<<-EOT)"
        lines << indent(@ruby_code, 2)
        lines << "  EOT"
        lines << ""
        lines << "  Y2R.compile(ycp_code).should == ruby_code"
      elsif @error_code
        lines << "  lambda {"
        lines << "    Y2R.compile(ycp_code)"
        lines << "  }.should raise_error NotImplementedError, \"#{@error_code}\""
      end
      lines << "end"

      @ycp_code   = nil
      @ruby_code  = nil
      @error_code = nil
      @separate   = true

      auto_indent(join(lines))
    else
      nil
    end
  end

  def doc_header
    join([
      "# Generated from spec/y2r_spec.md -- do not change!",
      "",
      "require \"spec_helper\"",
      "",
      "describe Y2R do",
      "  describe \".compile\" do",
    ])
  end

  def doc_footer
    lines = []

    lines << pop_describe while @level > 0
    lines << "  end"
    lines << "end"

    join(lines)
  end

  private

  def join(lines)
    lines.map { |l| "#{l}\n" }.join("")
  end

  def indent(s, n)
    s.gsub(/^(?=.)/, " " * (INDENT_STEP * n))
  end

  def auto_indent(s)
    indent(s, @level + 2)
  end

  def push_describe(text)
    result = auto_indent("describe \"#{text}\" do")

    @level += 1
    @separate = false

    result
  end

  def pop_describe
    @level -= 1
    @separate = true

    auto_indent("end")
  end
end
