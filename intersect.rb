=begin

--intersect.rb

=end

require 'json'
require 'set'

# degrees to radians
def to_rad(deg)
  deg*(Math::PI/180)
end


# Use Haversine formula to compute the
# distance between to (lat,lon) coordinates
def dist(lat1, lon1, lat2, lon2)
  dLat = to_rad(lat2-lat1)
  dLon = to_rad(lon2-lon1)
  a = Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) *
      Math.sin(dLon/2) * Math.sin(dLon/2)
  c = 2 * Math.atan2(Math.sqrt(a),Math.sqrt(1-a))
  d = 6371 * c * 1000 # dist in meters

  d.round(2)
end

abort("USAGE: ruby intersect.rb filename.json") if ARGV.empty?

map = JSON.parse(File.open(ARGV[0]).read, {:symbolize_names=>true})

ways = []
link_count = {}
way_reg = /^(primary|secondary|tertiary|unclassified|residential)$/

map[:elements].each do |elem|

  next if elem[:type] != "way"                      ||
          !elem.has_key?(:tags)                     ||
          !elem[:tags].has_key?(:highway)           ||
          way_reg.match(elem[:tags][:highway]).nil?
  
  ways << elem # valid way!

  elem[:nodes].each do |node|
    link_count[node] = {:counter=>0} if link_count[node].nil?
    link_count[node][:counter] += 1
  end
  
end

puts ways.length.to_s + " valid ways"


nodes = Set.new
edges = []

ways.each do |way|

  abort("Invalid way #" + way[:id]) if way[:nodes].length == 0

  start = 0
  next if start == way[:nodes].length-1 # one node way

  way[:nodes].each_with_index do |node,ix|
    next if ix==0 || link_count[node][:counter] < 2 # first or not an intersection node

    n_start = way[:nodes][start]

    nodes << n_start
    nodes << node

    e = n_start.to_s + ";" + node.to_s

    if !way[:tags].has_key?(:name)
      e += ";UNAMED"
    else
      e += ";" + way[:tags][:name].gsub(";",'/')
    end

    e += ";" + way[:tags][:highway] + ";Undirected"

    edges << e
    start = ix
  end

  next if start == way[:nodes].length-1

  n_start = way[:nodes][start]
  n_end   = way[:nodes][-1]

  nodes << n_start
  nodes << n_end

  e = n_start.to_s + ";" + n_end.to_s

  if !way[:tags].has_key?(:name)
    e += ";UNAMED"
  else
    e += ";" + way[:tags][:name].gsub(";",'/')
  end

  e += ";" + way[:tags][:highway] + ";Undirected"
  
  edges << e
end

# write nodes file
str = "Id;Latitude;Longitude\n"
map[:elements].each do |elem|
  next if elem[:type] != "node" || !nodes.include?(elem[:id])
  str += elem[:id].to_s + ";" + elem[:lat].to_s + ";" + elem[:lon].to_s + "\n"
end
File.write("Nodes.csv", str)

# write edges file
str = "Source;Target;Name;Highway;Type\n"
edges.each { |e| str += e + "\n" }
File.write("Edges.csv", str)
