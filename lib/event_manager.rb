require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(number)
  number = number.to_s.tr('^0-9', '') 
  if number.length == 10
    number
  elsif number.length == 11 && number[0] == "1"
    number[1..10]
  else  
    'Invalid Phone Number'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def get_hours(date, array)
  hour = DateTime.strptime(date, '%m/%d/%Y %H:%M').hour
  array << hour
end

def get_day(date, array)
  date = DateTime.strptime(date, '%m/%d/%Y %H:%M')
  year = date.year.to_i
  month = date.month.to_i
  day = date.day.to_i
  weekday = Date.new(year, month, day).wday
  array << weekday
end

def convert_days(day)
  case day 
  when 0
    "Sunday"
  when 1
    "Monday"
  when 2
    "Tuesday"
  when 3
    "Wednesday"
  when 4
    "Thursday"
  when 5 
    "Friday"
  when 6
    "Saturday"
  end
end

def most_common_value(a)
  a.group_by(&:itself).values.max_by(&:size).first
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = []
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  get_hours(row[:regdate], hours)
  get_day(row[:regdate], days)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  puts "#{name} #{number} #{zipcode}"
end

puts "The most popular registration hour is #{most_common_value(hours)}"
puts "The most popular registration day is #{convert_days(most_common_value(days))}"

