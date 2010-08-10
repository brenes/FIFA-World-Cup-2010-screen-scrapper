require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'date'
require 'time'
require 'active_support'



def add_to_summary summary, match_info, match_time, subject, action, object = nil

  summary_time = match_time.split("+")
  
  summary[match_time.length > 1 ? match_time : "#{match_time}"] = [] if summary[match_time].nil?

  time = DateTime.parse("#{match_info[:match_date]} #{match_info[:match_time]}")
  time = time + summary_time[0].to_i.minutes
  time = time + summary_time[1].to_i.minutes

  if summary_time[0].to_i > 45
    time = time + (match_info[:additional_time]["First Half"].to_i).minutes
    time = time + 15.minutes # the usual break between the two halves
  end

  if summary_time[0].to_i > 90
    time = time + match_info[:additional_time]["Second Half"].to_i.minutes
    time = time + 15.minutes # the usual break between the second half and the extra time
  end

  if summary_time[0].to_i > 115
    time = time + match_info[:additional_time]["First Extra Time"].to_i.minutes
  end



  summary[match_time.length > 1 ? match_time : "#{match_time}"] << {:time => time, :match_time => match_time, :subject => subject, :object => object, :action => action }
  summary
end

# CONFIG

# FIFA.com URLs
groups_url = 'http://www.fifa.com/worldcup/matches/groupstage.html'
final_stage_url = 'http://www.fifa.com/worldcup/matches/index.html'
fifa_domain = 'http://www.fifa.com/'

# xpath expressions
group_xpath = '//a[@title = "Summary"]/@href'
final_stage_xpath = '//a[@title = "Summary"]/@href'

xpath_expressions = {}

xpath_expressions[:match_number] = '//div[@class="hdTeams"]//div[@class="cont"]//tbody//td[1]'
xpath_expressions[:match_date] = '//div[@class="hdTeams"]//div[@class="cont"]//tbody//td[2]'
xpath_expressions[:match_time] = '//div[@class="hdTeams"]//div[@class="cont"]//tbody//td[3]'
xpath_expressions[:match_venue] = '//div[@class="hdTeams"]//div[@class="cont"]//tbody//td[4]'
xpath_expressions[:match_attendance] = '//div[@class="hdTeams"]//div[@class="cont"]//tbody//td[5]'

### The plain name of the teams
xpath_expressions[:home_player_name] = '//div[@class = "teamH"]/div[@class = "name"]/a'
xpath_expressions[:visiting_player_name] = '//div[@class = "teamA"]/div[@class = "name"]/a'

### The result with a format containing both result at the end of the 1st part and at the end of the match.
### i.e: "4:1 (2:1)"
xpath_expressions[:score] = '//div[@class = "result"]'

### A list with a link containing the name of the scorer and the minutes:
### i.e: <a href="[...]">Miroslav KLOSE</a>
###       (20')
###       <a href="[...]" title="GER:ENG - Miroslav KLOSE  "><img/></a>
xpath_expressions[:scorers_home] = '//div[@class = "listScorer"]/div[@class = "home"]/ul/li'
xpath_expressions[:scorers_visiting] = '//div[@class = "listScorer"]/div[@class = "away"]/ul/li'

### A list  containing both the role of each referee (main referee, assistant, fourth official...), their names and nationalities
### i.e: [<div class="bold">Referee</div> Jorge LARRIONDA (URU), <div class="bold">Assistant Referee 1</div> Pablo FANDINO (URU)  ]
xpath_expressions[:referees] = '//div[@class="cont"]/table[contains(@summary,"official")]//tr/td[div]'

### Lineup and players
xpath_expressions[:lineup_home] = '//div[@class = "lnupTeam"]/ul[contains(div, "Line-up")]/li'
xpath_expressions[:lineup_visiting] = '//div[@class = "lnupTeam away"]//ul[contains(div, "Line-up")]/li'
xpath_expressions[:substitutes_home] = '//div[@class = "lnupTeam"]/ul[contains(div, "Substitute")]/li'
xpath_expressions[:substitutes_visiting] = '//div[@class = "lnupTeam away"]//ul[contains(div, "Substitute")]/li'

### Manager, containing both the name and the nationality. i.e: Joachim LOEW (GER)
xpath_expressions[:manager_home] = '//div[@class = "lnupTeam"]/child::text()'
xpath_expressions[:manager_visiting] = '//div[@class = "lnupTeam away"]/child::text()'

### yellow (cautions) and red (expulsions) cards. It returns a list of names and minutes. i.e: Arne FRIEDRICH (GER) 47'
xpath_expressions[:cautions] = '//div[@class="cont"]/ul[contains(div, "Cautions")]/li'
xpath_expressions[:expulsions] = '//div[@class="cont"]/ul[contains(div, "Expulsions")]/li'

### Aditional time for each time, a list containing the concept (first half, second half...) and the amoun ot minutes
xpath_expressions[:additional_time] = '//div[@class="cont"]/ul[contains(div, "Additional time")]/li[normalize-space(.) !=  ""]'

# other
# 
# The time between two requests
nap_seconds = 5

# LET'S START ###################################################################

# we first need a list of the all URLs of the matches, but they are divided in 2 diferentes pages
puts "Downloading #{groups_url}"
groups_web = Nokogiri::HTML(open(groups_url))
puts "Downloading #{final_stage_url}"
final_stage_web = Nokogiri::HTML(open(final_stage_url))

# Now we collect all the links to the matches
# WARNING: we have the data to the summary of the match and we want the report (the important data)
# so we must change the URL
puts "Retrieving all the matches links"
match_links = []
groups_web.xpath(group_xpath).each do |href|
  match_links << href.content.gsub(/index.html$/i, "report.html")
end

final_stage_web.xpath(final_stage_xpath).each do |href|
  match_links << href.content.gsub(/index.html$/i, "report.html")
end

# And now we visit every match page and dump all its data to a CSV

match_number = 1
match_links.each do |url|

  puts "-----------------------------------------------------"
  report_web = Nokogiri::HTML(open("#{fifa_domain}#{url}"))

  match_info = {}
  xpath_expressions.each do |pair|
    eval "match_info[:#{pair[0].to_s}] = report_web.xpath('#{pair[1]}')"
  end
  match_info[:home_player_name] = match_info[:home_player_name][0].content
  match_info[:visiting_player_name] = match_info[:visiting_player_name][0].content

  match_info[:match_number] = match_info[:match_number][0].content
  match_info[:match_date] = match_info[:match_date][0].content
  match_info[:match_time] = match_info[:match_time][0].content
  match_info[:match_venue] = match_info[:match_venue][0].content
  match_info[:match_attendance] = match_info[:match_attendance][0].content

  puts "\#\#\#\# Match #{match_info[:match_number]}: #{match_info[:home_player_name]} - #{match_info[:visiting_player_name]} -- #{url}"
  puts "\#\# Home team: #{match_info[:home_player_name].inspect}"
  puts "\#\# Visiting team: #{match_info[:visiting_player_name].inspect}"
  puts "\#\# Date/Time: #{match_info[:match_date]} #{match_info[:match_time]}"
  puts "\#\# Venue: #{match_info[:match_venue]}"
  puts "\#\# Attendance: #{match_info[:match_attendance]}\n\n"

  ####################### Scores
  match_info[:score] = match_info[:score][0].content.gsub(/[\(\)]/,"").split(" ").map{|s| s.split(":") }.flatten
  match_info[:score] = {:home_final => match_info[:score][0], :visiting_final => match_info[:score][1], :home_partial => match_info[:score][2], :visiting_partial => match_info[:score][3]}
  
  puts "\#\# Score: #{match_info[:score].inspect}\n\n"

  ###################### Scorers
  scorers = []
  penalties = []
  [:home, :visiting].each do |score_team|
    match_info[:"scorers_#{score_team}"].each do |scorer|
      scorer_name = scorer.content.match(/(.)*\(/)[0].sub("(","").downcase.strip
      scores_minutes = scorer.content.match(/\((.)*\)/)[0].gsub(/[\(\)\']/, "").split(",")
      scores_minutes.each do |minute|
        scorers << {:minute => minute.gsub("PEN", "").strip, :player => scorer_name, :team => score_team.to_s}
        unless minute.index("PEN").nil?
          penalties << {:minute => minute.gsub("PEN", "").strip, :scorer => scorer_name, :team => score_team.to_s}
        end
      end
    end
  end

  match_info[:scorers] = scorers
  match_info[:penalties] = penalties

  puts "\#\#\#\# Scorers \n\n #{scorers.inspect}\n\n"
  puts "\#\#\#\# Penalties \n\n #{penalties.inspect}\n\n"

  ######################### Referees
  referees = {}
  match_info[:referees].each do |referee|

    referee_type =  referee.xpath("div[@class = 'bold']")[0].content.strip
    referee_name = referee.xpath("child::text()")[0].content.match(/(.)*\(/)[0].sub("(","").downcase.strip
    referee_country = referee.xpath("child::text()")[0].content.match(/\((.)*\)/)[0].gsub(/[\(\)\']/, "").strip

    referees[referee_type.to_sym] = {:type => referee_type, :name => referee_name, :country => referee_country}
    
  end

  match_info[:referees] = referees
  puts "\#\#\#\# Referees \n\n#{match_info[:referees].inspect}\n\n"

  ######################### Lineups

  players = {}
  substitutions = {}
  [:home, :visiting].each do |lineup_team|
    players[lineup_team] = {}
    [:lineup, :substitutes].each do |player_type|
      players[lineup_team][player_type] = []
    
      match_info[:"#{player_type}_#{lineup_team}"].each do |player|
        player_number = player.xpath("div/a")[0].content
        player_name = player.xpath("div/span")[0].content.gsub(/\((.)*\)/, "").strip.downcase
        player_in = player.xpath("div/span")[0].content.match(/\+(\d)+/)
        unless player_in.nil?
          player_in = player_in[0].strip.sub("+", "")
          substitutions[player_in] = [] if substitutions[player_in].nil?
          if substitutions[player_in].select{|p| p[:in].nil?}.empty?
            substitutions[player_in] << {:in => player_name}
          else
            substitutions[player_in].select{|p| p[:in].nil?}.first[:in] = player_name
          end
        end
        player_out = player.xpath("div/span")[0].content.match(/\-(\d)+/)
        unless player_out.nil?
          player_out = player_out[0].strip.sub("-", "")
          substitutions[player_out] = [] if substitutions[player_out].nil?
          if substitutions[player_out].select{|p| p[:out].nil?}.empty?
            substitutions[player_out] << {:out => player_name}
          else
            substitutions[player_out].select{|p| p[:out].nil?}.first[:out] = player_name
          end
        end

        players[lineup_team][player_type] << {:number => player_number, :name => player_name, :in => player_in, :out => player_out }

      end
    end
  end

  match_info[:players] = players
  match_info[:substitutions] = substitutions

  puts "\#\#\#\# Players \n\n#{match_info[:players].inspect}\n\n"
  puts "\#\#\#\# Substitutions \n\n#{match_info[:substitutions].inspect}\n\n"

  ############################ Managers
  managers = {}

  [:home, :visiting].each do |manager_team|
    managers[manager_team] = {
      :name => match_info[:"manager_#{manager_team}"][0].content.match(/(.)*\(/)[0].sub("(","").downcase.strip,
      :country => match_info[:"manager_#{manager_team}"][0].content.match(/\((.)*\)/)[0].gsub(/[\(\)\']/, "").strip
    }
  end

  match_info[:managers] = managers
  puts "\#\#\#\# Managers \n\n#{match_info[:managers].inspect}\n\n"

  ########################## Cards

  cards = {}
  [:cautions, :expulsions].each do |card_type|
    cards[card_type] = []
    match_info[card_type].each do|card|
      # Arne FRIEDRICH (GER) 47'
      cards[card_type] << {
        :player => card.content.match(/(.)*\(/)[0].gsub(/[,\(]/,"").downcase.strip,
        :team => card.content.match(/\((.)*\)/)[0].gsub(/[\(\)\']/, "").strip,
        :minute => card.content.match(/\)(.)*$/)[0].gsub(/[\)\']/,"").downcase.strip
      }
    end
  end

  match_info[:cards] = cards
  puts "\#\#\#\# Cards \n\n#{match_info[:cards].inspect}\n\n"

  ########################### Additional time
  additional_time = {}
  match_info[:additional_time].each do |time|
    time = time.content.split(":")
    additional_time[time[0].strip] = time[1].strip.sub("\'", "")
  end
  match_info[:additional_time] = additional_time
  puts "\#\#\#\# Additional time \n\n#{match_info[:additional_time].inspect}\n\n"

  ############################ Summary
  summary = {}

  summary = add_to_summary summary, match_info, "0", nil, "beginning"
  summary = add_to_summary summary, match_info, "45+#{match_info[:additional_time]["First Half"]}", nil, "end_first_half"
  summary = add_to_summary summary, match_info, "46", nil, "beginning_second_half"
  summary = add_to_summary summary, match_info, "90+#{match_info[:additional_time]["Second Half"]}", nil, "end_second_half"
  summary = add_to_summary summary, match_info, "105+#{match_info[:additional_time]["First Extra Time"]}", nil, "end_first_extra_time" unless match_info[:additional_time]["First Extra Time"].nil?
  summary = add_to_summary summary, match_info, "120+#{match_info[:additional_time]["Second Extra Time"]}", nil, "end_second_extra_time" unless match_info[:additional_time]["Second Extra Time"].nil?

  ## scores
  match_info[:scorers].each do |scorer|
    summary = add_to_summary summary, match_info, scorer[:minute], scorer[:player], "goal"
  end

  ## penalties
  match_info[:penalties].each do |penalty|
    summary = add_to_summary summary, match_info, penalty[:minute], nil, "penalty",  penalty[:scorer]
  end

  ## substitutions
  match_info[:substitutions].each do |substitutions|
    substitutions[1].each do |substitution|
      summary = add_to_summary summary, match_info, substitutions[0], substitution[:in], "substitution", substitution[:out]
    end
  end

  match_info[:cards].each do |card_type|
    card_type[1].each do |card|
      summary = add_to_summary summary, match_info, card[:minute], nil, card_type[0], card[:player]
    end
  end


  puts "\#\#\#\# Summary\n"
  summary.sort{|m1, m2| m1[0].to_i <=> m2[0].to_i}.each do |minute|
    minute[1].each do |action|
      puts "#{action[:time]} Minute #{minute[0]}: #{action[:action]} - #{action[:subject]} - #{action[:object]}"
    end
  end
  # do the stuff
  break;

end