# -*- encoding : utf-8 -*-
class RSpecContextRenderer
  # context: an html representation of an rspec context from rspec output
  # counts: a hash with :passed, :failed, :not_implemented counters
  def initialize(context, counts)
    @context=context
    @counts=counts
    @classes = {"passed"=>"+","failed"=>"-","not_implemented"=>"#"}
    render_context_header
    render_specs
    puts " "
  end

  private
  def render_context_header
    puts "[#{(@context/"dl/dt").inner_html}]"
  end

  def render_specs
    (@context/"dl").each do |dl|
      dl.children.each do |child|
        if child.is_a?(Hpricot::Elem) && child.name == 'dd'
          render_spec_descriptor(child)
          FailureRenderer.new(child/"div[@class~='failure']") if child[:class] =~ /failed/
        elsif child.is_a?(Hpricot::Text)
          text=child.to_s.strip
          puts text unless text.empty?
        end
      end
    end
  end

  def render_spec_descriptor(dd)
    txt = (dd/"span:first").inner_html
    clazz = dd[:class].gsub(/(?:example|spec) /,'')
    puts "#{@classes[clazz]} #{txt}"
    outcome = clazz.to_sym
    @counts[outcome] += 1
  end
end
