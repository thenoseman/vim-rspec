class FailureRenderer
  include StringUtil

  def initialize(failure)
    @failure = failure
    puts "  #{failure_message}"
    puts "  #{failure_location}"
    puts backtrace_details
  end

  private

  def failure_location
    unescape((@failure/"div[@class='backtrace']/pre").inner_html)
  end

  def failure_message
    unescape((@failure/"div[@class='message']/pre").inner_html.gsub(/\n/,'').gsub(/\s+/,' '))
  end

  def backtrace_details
    unescape(
      backtrace_lines.map do |elem|
        linenum = elem[1]
        code = elem[3].chomp
        code = strip_html_spans(code)
        "  #{linenum}: #{code}\n"
      end.join
    )
  end

  def backtrace_lines
    (@failure/"pre[@class='ruby']/code").inner_html.scan(/(<span class="linenum">)(\d+)(<\/span>)(.*)/)
  end

end
