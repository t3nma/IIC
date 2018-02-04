=begin

--intersect.rb

Parse JSON file containing data extracted 
from OSM and build the corresponding 
primal network.

Nodes => Road intersection
Edges => Road

=end

require 'json'
require 'set'

$edge_map = {}

# check if edge exists
def find_edge(s,e)
  return false if $edge_map[s].nil? || $edge_map[e].nil?

  if !$edge_map[s].nil?
    $edge_map[s].each { |n| return true if e == n }
  end

  if !$edge_map[e].nil?
    $edge_map[e].each { |n| return true if s == n }
  end

  false
end

# mark edge as found
def add_edge(n_start, n_end)

  $edge_map[n_start] = [] if $edge_map[n_start].nil?
  $edge_map[n_start] << n_end
  
  $edge_map[n_end] = [] if $edge_map[n_end].nil?
  $edge_map[n_end] << n_start
  
end

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
  file_nodes[elem[:id].to_s] = {:id => -1, :lat => elem[:lat], :lon => elem[:lon], :counter => 0}
end

# save all valid osm ways
# count each node appearance
ways = []
way_reg = /^(primary|secondary|tertiary|residential)$/

map[:elements].each do |elem|
  
  next if elem[:type] != "way"                      ||
          !elem.has_key?(:tags)                     ||
          !elem[:tags].has_key?(:highway)           ||
          way_reg.match(elem[:tags][:highway]).nil?
  
  ways << elem
  elem[:nodes].each { |node| file_nodes[node.to_s][:counter] += 1 }
end

# find way intersections, build graph
nodes = Set.new
node_count = 1
edges = []

ways.each do |way|

  abort("Invalid way #" + way[:id].to_s) if way[:nodes].length == 0 # sanity check

  ix_start = 0
  next if ix_start == way[:nodes].length-1 # one node way
  
  way[:nodes].each_with_index do |cur_node,ix|

    next if ix==0 ||                                # first node
            file_nodes[cur_node.to_s][:counter] < 2 # not an intersection node

    n_start = way[:nodes][ix_start].to_s
    n_end   = way[:nodes][ix].to_s

    next if n_start == n_end ||       # same nodes
            find_edge(n_start,n_end)  # edge already exists

    add_edge(n_start, n_end)
    
    if file_nodes[n_start][:id] == -1
      file_nodes[n_start][:id] = node_count
      node_count += 1
    end

    if file_nodes[n_end][:id] == -1
      file_nodes[n_end][:id] = node_count
      node_count += 1
    end
      
    nodes << n_start
    nodes << n_end

    e = file_nodes[n_start][:id].to_s + ";" + file_nodes[n_end][:id].to_s

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

  next if n_start == n_end ||      # same nodes
          find_edge(n_start,n_end) # edge already exists

  add_edge(n_start, n_end)
  
  if file_nodes[n_start][:id] == -1
    file_nodes[n_start][:id] = node_count
    node_count += 1
  end

  if file_nodes[n_end][:id] == -1
    file_nodes[n_end][:id] = node_count
      node_count += 1
  end
      
  nodes << n_start
  nodes << n_end
  
  e = file_nodes[n_start][:id].to_s + ";" + file_nodes[n_end][:id].to_s

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

# write nodes csv file
str = "Id;Latitude;Longitude\n"
nodes.each { |n| str << file_nodes[n][:id].to_s << ";" << file_nodes[n][:lat].to_s << ";" << file_nodes[n][:lon].to_s << "\n" }
File.write("Nodes.csv", str)

puts nodes.size.to_s + " nodes"

# write edges csv file
# Label  == street name
# Length == sub-street distance in meters
str = "Source;Target;Label;Highway;Length;Type\n"
str_el = ""
avg_len = 0
edges.each do |e|
  str += e + "\n"
  tokens = e.split(";")
  str_el += tokens[0] + " " + tokens[1] + " " + tokens[4] + "\n"
  avg_len += tokens[4].to_f
end
File.write("Edges.csv", str)
File.write("edgelist.txt", str_el)

puts edges.size.to_s + " edges"
puts (avg_len/edges.size).to_s + " avg edge length"
