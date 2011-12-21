require "rubygems"
require "hpricot"
require 'cgi'
doc = Hpricot(STDIN.read)
classes = {"spec passed"=>"+","spec failed"=>"-","spec not_implemented"=>"#"}

stats = (doc/"script").select {|script| script.innerHTML =~ /duration|totals/ }.map {|script| script.inner_html.scan(/".*"/).first.gsub(/<\/?strong>/,"") }
puts "* #{stats.join(" | ").gsub(/\"/,'')}"
puts " "

(doc/"div[@class='example_group']").each do |example|

	puts "[#{(example/"dl/dt").inner_html}]"

	(example/"dd").each do |dd|
		txt = (dd/"span:first").inner_html
		puts "#{classes[dd[:class]]} #{txt}"

		next if dd[:class]!="spec failed"
		failure = (dd/"div[@class='failure']")
		msg = CGI.unescapeHTML((failure/"div[@class='message']/pre").inner_html)
		back = CGI.unescapeHTML((failure/"div[@class='backtrace']/pre").inner_html)
		ruby = CGI.unescapeHTML((failure/"pre[@class='ruby']/code").inner_html.scan(/(<span class="linenum">)(\d+)(<\/span>)([^<]+)/).map {|elem| "  "+elem[1]+": "+elem[3].chomp+"\n"}.join)
		puts "  #{msg}"
		puts "  #{back}"
		puts ruby
	end
	puts " "
end
