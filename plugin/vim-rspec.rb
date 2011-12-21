require "rubygems"
require "hpricot"
require 'cgi'
require "#{File.join(File.dirname(__FILE__), "lib/string_util")}"
require "#{File.join(File.dirname(__FILE__), "lib/failure_renderer")}"
require "#{File.join(File.dirname(__FILE__), "lib/context_renderer")}"

class RSpecOutputHandler

  def initialize(doc)
    @doc=doc
    render_header
    render_examples
  end

  private

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
      RSpecContextRenderer.new(context)
    end
  end

end

renderer=RSpecOutputHandler.new(Hpricot(STDIN.read))
