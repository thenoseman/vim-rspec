require "rubygems"
require "hpricot"
require 'cgi'

class RSpecOutputHandler
  def initialize(doc)
    @doc=doc
    render_header
    render_examples
  end

  private

  module RSpecContextRenderer
    def self.render(context)
      render_context_header(context) 
      render_specs(context)
      puts " "
    end

    def self.render_context_header(context)
      puts "[#{(context/"dl/dt").inner_html}]"
    end

    def self.render_specs(context)
      classes = {"spec passed"=>"+","spec failed"=>"-","spec not_implemented"=>"#"}

      (context/"dd").each do |dd|
        txt = (dd/"span:first").inner_html
        puts "#{classes[dd[:class]]} #{txt}"

        next if dd[:class]!="spec failed"
        render_failure_details(dd)
      end
    end

    def self.render_failure_details(example_details)
      failure = (example_details/"div[@class='failure']")
      puts "  #{failure_message(failure)}"
      puts "  #{backtrace_line(failure)}"
      puts backtrace_details(failure)
    end

    def self.backtrace_details(failure)
      unescape(
        (failure/"pre[@class='ruby']/code").inner_html.scan(/(<span class="linenum">)(\d+)(<\/span>)(.*)/).map do |elem| 
          linenum = elem[1]
          code = elem[3].chomp
          code.gsub!(/<span class=[^>]+>/,'')
          code.gsub!(/<\/span>/,'')
          "  "+elem[1]+": "+code.chomp+"\n"
        end.join
      )
    end

    def self.backtrace_line(failure)
      unescape((failure/"div[@class='backtrace']/pre").inner_html)
    end

    def self.failure_message(failure)
      unescape((failure/"div[@class='message']/pre").inner_html.gsub!(/\n/,'').gsub(/\s+/,' '))
    end

    def self.unescape(html)
      CGI.unescapeHTML(html)
    end
  end

  def render_header
    stats = (@doc/"script").select {|script| script.innerHTML =~ /duration|totals/ }
    stats.map! do |script| 
      script.inner_html.scan(/".*"/).first.gsub(/<\/?strong>/,"")
    end
    puts "* #{stats.join(" | ").gsub(/\"/,'')}"
    puts " "
  end

  def render_examples
    (@doc/"div[@class='example_group']").each do |context|
      RSpecContextRenderer.render(context)
    end
  end

end

renderer=RSpecOutputHandler.new(Hpricot(STDIN.read))
