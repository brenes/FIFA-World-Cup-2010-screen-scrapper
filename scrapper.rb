require 'nokogiri'
require 'open-uri'

# CONFIG

# FIFA.com URLs
groups_url = 'http://www.fifa.com/worldcup/matches/groupstage.html'
final_stage_url = 'http://www.fifa.com/worldcup/matches/index.html'
fifa_domain = 'http://www.fifa.com/'

# xpath expressions
group_xpath_expression = '//a[@title = "Summary"]/@href'
final_stage_xpath_expression = '//a[@title = "Summary"]/@href'

# other
# 
# The time between two requests
nap_seconds = 5

# LET'S START ###################################################################

# we first need a list of the all URLs of the matches, but they are divided in 2 diferentes pages
groups_web = Nokogiri::HTML(open(groups_url))
final_stage_web = Nokogiri::HTML(open(final_stage_url))

# Now we collect all the links to the matches
# WARNING: we have the data to the summary of the match and we want the report (the important data)
# so we must change the URL
match_links = []
groups_web.xpath(group_path_expression).each do |href|
  match_links << href[0].gsub(/index.html$/i, "report.html")
end

final_stage_web.xpath(final_stage_path_expression).each do |href|
  match_links << href[0].gsub(/index.html$/i, "report.html")
end

# And now we visit every match page and dump all its data to a CSV

match_links.each do |url|
  report_web = Nokogiri::HTML("#{fifa_domain}#{url}")

  # do the stuff
end