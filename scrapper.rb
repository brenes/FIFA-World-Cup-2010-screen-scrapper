require 'nokogiri'
require 'open-uri'

# CONFIG

# FIFA.com URLs
groups_url = 'http://www.fifa.com/worldcup/matches/groupstage.html'
final_stage_url = 'http://www.fifa.com/worldcup/matches/index.html'
fifa_domain = 'http://www.fifa.com/'

# xpath expressions
group_xpath = '//a[@title = "Summary"]/@href'
final_stage_xpath = '//a[@title = "Summary"]/@href'

### The plain name of the teams
home_player_name_xpath = '//div[@class = "teamH"]/div[@class = "name"]/a'
visiting_player_name_xpath = '//div[@class = "teamA"]/div[@class = "name"]/a'

### The result with a format containing both result at the end of the 1st part and at the end of the match. i.e: "4:1 (2:1)"
score_xpath = '//div[@class = "result"]'

### A list with a link containing the name of the scorer and the minutes:
### i.e: <a href="[...]">Miroslav KLOSE</a>
###       (20')
###       <a href="[...]" title="GER:ENG - Miroslav KLOSE  "><img/></a>
scorers_home_xpath = '//div[@class = "listScorer"]/div[@class = "home"]/ul/li'
scorers_visiting_xpath = '//div[@class = "listScorer"]/div[@class = "away"]/ul/li'

### A list  containing both the role of each referee (main referee, assistant, fourth official...), their names and nationalities
### i.e: [<div class="bold">Referee</div> Jorge LARRIONDA (URU), <div class="bold">Assistant Referee 1</div> Pablo FANDINO (URU)  ]
referees_xpath = '//div[@class="cont"]/table[contains(@summary,"official")]//tr/td'

### Lineup and players
lineup_home_xpath = '//div[@class = "lnupTeam"]/ul[contains(div, "Line-up")]/li'
lineup_visiting_xpath = '//div[@class = "lnupTeam away"]//ul[contains(div, "Line-up")]/li'
substitutes_home_xpath = '//div[@class = "lnupTeam"]/ul[contains(div, "Substitute")]/li'
substitutes_visiting_xpath = '//div[@class = "lnupTeam away"]//ul[contains(div, "Substitute")]/li'

### Manager, containing both the name and the nationality. i.e: Joachim LOEW (GER)
manager_home_xpath = '//div[@class = "lnupTeam"]/child::text()'
manager_visiting_xpath = '//div[@class = "lnupTeam away"]/child::text()'

### yellow (cautions) and red (expulsions) cards. It returns a list of names and minutes. i.e: Arne FRIEDRICH (GER) 47'
cautions_xpath = '//div[@class="cont"]/ul[contains(div, "Cautions")]//tr/td'
expulsions_xpath = '//div[@class="cont"]/ul[contains(div, "Expulsions")]//tr/td'

### Aditional time for each time, a list containing the concept (first half, second half...) and the amoun ot minutes
additional_time_xpath = '//div[@class="cont"]/ul[contains(div, "Additional time")]//tr/td'

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
groups_web.xpath(group_xpath).each do |href|
  match_links << href[0].gsub(/index.html$/i, "report.html")
end

final_stage_web.xpath(final_stage_xpath).each do |href|
  match_links << href[0].gsub(/index.html$/i, "report.html")
end

# And now we visit every match page and dump all its data to a CSV

match_links.each do |url|
  report_web = Nokogiri::HTML("#{fifa_domain}#{url}")
  home_player = report_web.xpath()

  # do the stuff
end