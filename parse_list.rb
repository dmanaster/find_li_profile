require 'mechanize'
require 'csv'    

counter = 0
match_counter = 0

data = Array.new
csv = CSV.open('attendees.csv', :headers => true)
csv.each do |row|
  data << row.to_hash
end
results_file = CSV.open("results.csv", "a+")
unless results_file.first
  results_file << ["Name", "Company", "Country", "Confirmed Link", "Google Link", "Bing Link"]
end

agent = Mechanize.new
google_page = agent.get('https://www.google.com/')
google_form = google_page.form('f')
bing_page = agent.get('https://www.bing.com/')
bing_form = bing_page.forms.first

def calculate_percentage(match_counter, counter)
  puts "Total: " + counter.to_s + "     Matches: " + match_counter.to_s + "     Percent Matched: " + (match_counter.to_f/counter.to_f*100).round.to_s + "%"
end

def compare_links(person, google_link, bing_link, counter, match_counter)   
  new_link = ""
  if !google_link.to_s.empty? && !bing_link.to_s.empty?
    google_name = google_link.split("/")[4].split("?").first
    bing_name = bing_link.split("/")[4].split("?").first
    if google_name == bing_name
      new_link = [google_link,bing_link].min_by(&:length)
      puts counter.to_s + ": " + person["Name"] + " - Match!"
      match_counter = increment(match_counter)
    else
      puts counter.to_s + ": " + person["Name"] + " - :("
    end
  else
    puts counter.to_s + ": " + person["Name"] + " - :("    
  end
  return new_link, match_counter
end

def add_result(results_file, name, company, country, final_link, google_link, bing_link)
    results_file << [name, company, country, final_link, google_link, bing_link]
end

def increment(counter)
  counter = counter + 1
end

def get_google_link(agent, form, person)
  search_string = "site:uk.linkedin.com/in/ " + person["Name"] + " " + person["Company"]
  form.q = search_string
  page = agent.submit(form, form.buttons.first)
  links = Array.new
  page.links.each do |link|
    if link.href.to_s =~ /url.q/
      str = link.href.to_s
      str_parts = str.split(%r{=|&}) 
      links << str_parts[1] 
    end 
  end
  final_link = links.first
  return final_link
end

def get_bing_link(agent, form, person)
  search_string = "site:linkedin.com/in/ " + person["Name"] + " " + person["Company"]
  form.q = search_string
  page = agent.submit(form, form.buttons.first)
  links = Array.new
  page.links.each do |link|
    if link.href.to_s.include?("linkedin.com/in/") 
      str = link.href.to_s
      links << str
    end 
  end
  final_link = links.first
  return final_link
end

data.each do |person|
  counter = increment(counter)
  google_link = get_google_link(agent, google_form, person)
  bing_link = get_bing_link(agent, bing_form, person)
puts google_link
puts bing_link
  final_link, match_counter = compare_links(person, google_link, bing_link, counter, match_counter)
  add_result(results_file, person["Name"], person["Company"], person["Country"], final_link, google_link, bing_link)
  calculate_percentage(match_counter, counter)
  sleep(46)
end

results_file.close