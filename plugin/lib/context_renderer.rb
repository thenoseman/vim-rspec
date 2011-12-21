class RSpecContextRenderer
  def initialize(context)
    @context=context
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
      FailureRenderer.new(dd/"div[@class='failure']") if dd[:class]=="spec failed"
    end
  end

  def render_spec_descriptor(dd)
    classes = {"spec passed"=>"+","spec failed"=>"-","spec not_implemented"=>"#"}
    txt = (dd/"span:first").inner_html
    puts "#{classes[dd[:class]]} #{txt}"
  end
end
