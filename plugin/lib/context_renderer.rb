# -*- encoding : utf-8 -*-
class RSpecContextRenderer
  # context: an html representation of an rspec context from rspec output
  # counts: a hash with :passed, :failed, :not_implemented counters
  def initialize(context, counts)
    @context=context
    @counts=counts
    render_context_header
    render_specs
    puts " "
  end

  private
  def render_context_header
    puts "[#{(@context/"dl/dt").inner_html}]"
  end

  def render_specs
    (@context/"dd").each do |dd|
      render_spec_descriptor(dd)
      FailureRenderer.new(dd/"div[@class~='failure']") if dd[:class] =~ /failed/
    end
  end

  def render_spec_descriptor(dd)
    classes = {"example passed"=>"+","example failed"=>"-","example not_implemented"=>"#"}
    txt = (dd/"span:first").inner_html
    puts "#{classes[dd[:class]]} #{txt}"
    outcome = dd[:class].gsub("example ",'').to_sym
    @counts[outcome] += 1
  end
end
