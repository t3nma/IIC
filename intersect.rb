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

# save all osm nodes
file_nodes = {}
map[:elements].each do |elem|
  next if elem[:type] != "node"
  file_nodes[elem[:id].to_s] = {:lat => elem[:lat], :lon => elem[:lon], :counter => 0}
end

# save all valid osm ways
# count each node appearance
ways = []
way_reg = /^(primary|secondary|tertiary|unclassified|residential)$/

map[:elements].each do |elem|
  
  next if elem[:type] != "way"                      ||
          !elem.has_key?(:tags)                     ||
          !elem[:tags].has_key?(:highway)           ||
          way_reg.match(elem[:tags][:highway]).nil?
  
  ways << elem
  elem[:nodes].each { |node| file_nodes[node.to_s][:counter] += 1 }
end

puts ways.length.to_s + " valid ways"

# find way intersections, build graph
nodes = Set.new
edges = []

ways.each do |way|

  abort("Invalid way #" + way[:id].to_s) if way[:nodes].length == 0 # sanity check

  ix_start = 0
  next if ix_start == way[:nodes].length-1 # one node way
  
  way[:nodes].each_with_index do |cur_node,ix|
    next if ix==0 || file_nodes[cur_node.to_s][:counter] < 2 # first or not an intersection node

    n_start = way[:nodes][ix_start].to_s
    n_end   = way[:nodes][ix].to_s
    
    nodes << n_start
    nodes << n_end

    e = n_start + ";" + n_end

    if !way[:tags].has_key?(:name)
      e << ";UNAMED"
    else
      e << ";" + way[:tags][:name].gsub(";",'/')
    end

    e << ";" + way[:tags][:highway]
    e << ";" + dist(file_nodes[n_start][:lat].to_f, file_nodes[n_start][:lon].to_f, file_nodes[n_end][:lat].to_f, file_nodes[n_end][:lon].to_f).to_s
    e << ";Undirected"

    edges << e
    ix_start = ix
  end

  next if ix_start == way[:nodes].length-1 # road was fully connected

  n_start = way[:nodes][ix_start].to_s
  n_end   = way[:nodes][-1].to_s

  nodes << n_start
  nodes << n_end

  e = n_start + ";" + n_end

  if !way[:tags].has_key?(:name)
    e << ";UNAMED"
  else
    e << ";" + way[:tags][:name].gsub(";",'/')
  end

  e << ";" + way[:tags][:highway]
  e << ";" + dist(file_nodes[n_start][:lat], file_nodes[n_start][:lon], file_nodes[n_end][:lat], file_nodes[n_end][:lon]).to_s
  e << ";Undirected"
  
  edges << e
end

# write nodes file
str = "Id;Latitude;Longitude\n"
nodes.each { |node| str << node << ";" << file_nodes[node][:lat].to_s << ";" << file_nodes[node][:lon].to_s << "\n" }
File.write("Nodes.csv", str)

# write edges file
str = "Source;Target;Name;Highway;Distance;Type\n"
edges.each { |e| str += e + "\n" }
File.write("Edges.csv", str)
