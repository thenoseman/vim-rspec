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
      (context/"dd").each do |dd|
        render_spec_descriptor(dd)
        render_failure_details(dd) if dd[:class]=="spec failed"
      end
    end

    def self.render_spec_descriptor(dd)
      classes = {"spec passed"=>"+","spec failed"=>"-","spec not_implemented"=>"#"}
      txt = (dd/"span:first").inner_html
      puts "#{classes[dd[:class]]} #{txt}"
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
      script.inner_html.scan(/".*"/).first.gsub(/<\/?strong>/,"").gsub(/\"/,'')
    end
    failure_success_messages,other_stats = stats.partition {|stat| stat =~ /failure/}
    render_red_green_header(failure_success_messages.first)
    other_stats.each do |stat|
      puts "*#{stat}"
    end
    puts " "
  end

  def render_red_green_header(failure_success_messages)
    success,failures = failure_success_messages.split(", ")
    fail_count = failures.match(/(\d+) failure/)[1].to_i
    success_count = success.match(/(\d+) example/)[1].to_i

    if fail_count > 0
      puts "--------------------------"
      puts "-#{failures}" 
      puts "--------------------------"
      if 1.to_i > 0
        puts "+#{success_count} passes"
      end
    else
      puts "+++++++++++++++++++++++++++"
      puts "+All #{success_count} Specs Pass!"
      puts "+++++++++++++++++++++++++++"
    end


    puts " "
  end

  def render_examples
    (@doc/"div[@class='example_group']").each do |context|
      RSpecContextRenderer.render(context)
    end
  end

end

renderer=RSpecOutputHandler.new(Hpricot(STDIN.read))
