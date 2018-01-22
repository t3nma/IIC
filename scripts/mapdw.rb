=begin

--mapdw.rb

Use overpass API to download osm information
about nodes and ways in specific boundary
boxes defined by the user in a file.

File should be .csv with header:
s;n;w;e;filename

Being (s,n,w,e) the coordinates for the box
and filename the filename to store the 
downloaded content.

=end

require 'overpass_api_ruby'
require 'json'

abort("USAGE: ruby mapdw.rb filename.csv") if ARGV.empty?

# set global api options
options = {:timeout => 900,
           :maxsize => 1073741824}

# init api
api = OverpassAPI::QL.new(options)

# read bbox file and request data
File.readlines(ARGV[0]).each_with_index do |line,ix|
  next if ix == 0 # skip header
  
  vals = line.gsub("\n",'').split(';')
  next if vals.length < 4 # simple input validation
  
  api.bounding_box(vals[0].to_f, vals[1].to_f, vals[2].to_f, vals[3].to_f)
  resp = api.query("node;way;(._;>;);out body;")
  
  File.write(vals[4]+".json", JSON.generate(resp))
end
