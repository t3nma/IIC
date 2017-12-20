require 'nokogiri'
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


doc = Nokogiri::XML(File.open(ARGV[0]))

# save all osm node info and add
osm_nodes = {}

doc.xpath("//node").each do |node|
  attrs = node.attributes
  id = attrs["id"].to_s
  osm_nodes[id] = {}
  osm_nodes[id][:lat] = attrs["lat"].value.to_f
  osm_nodes[id][:lon] = attrs["lon"].value.to_f
  osm_nodes[id][:counter] = 0 # auxiliary field
end

# save all valid ways (roads)
osm_ways = {}
way_reg = /primary|secondary|tertiary|unclassified|residential/

doc.xpath("//way").each do |way|
  
  w = {}
  w[:name] = "UNAMED"
  w[:type] = nil
  
  # get necessary tag info
  way.css("tag").each do |tag|
    w[:name] = tag["v"].to_s if tag["k"].to_s == "name"    
    w[:type] = tag["v"].to_s if tag["k"].to_s == "highway"
  end
  
  # invalid way?
  next if way_reg.match(w[:type]).nil?
  
  # valid, add node info and save it
  w[:nodes] = []
  way.css("nd").each do |nd|
    id = nd.attributes["ref"].value.to_s
    w[:nodes] << id
    osm_nodes[id][:counter] += 1 # count node, util for intersection finding
  end

  osm_ways[way.attributes["id"].value.to_s] = w
end

puts osm_ways.length.to_s + " valid roads"

nodes = Set.new
edges = []

# find intersections
osm_ways.each do |key,val|

  abort("INVALID WAY #" + key + " -> 0 NODES") if val[:nodes].length == 0

  gap_start = 0
  next if gap_start == val[:nodes].length-1 # one node way

  val[:nodes].each_with_index do |cur_node,ix|
    next if ix == 0 || osm_nodes[cur_node][:counter] < 2 # first or not an intersection node

    start_node = val[:nodes][gap_start]
    
    nodes << start_node
    nodes << cur_node
    edges << (start_node + ";" + cur_node + ";" + val[:name] + ";" + val[:type] + ";" + dist(osm_nodes[start_node][:lat],osm_nodes[start_node][:lon],osm_nodes[cur_node][:lat],osm_nodes[cur_node][:lon]).to_s + ";" + "Undirected")
    
    gap_start = ix
  end

  next if gap_start == val[:nodes].length-1

  s = val[:nodes][gap_start]
  e = val[:nodes][-1]
  
  edges << (s + ";" + e + ";" + val[:name] + ";" + val[:type] + ";" + dist(osm_nodes[s][:lat], osm_nodes[s][:lon], osm_nodes[e][:lat], osm_nodes[e][:lon]).to_s + ";" +"Undirected")
  
end

# write nodes file
str = "Id;Latitude;Longitude\n"
nodes.each { |n| str += n + ";" + osm_nodes[n][:lat].to_s + ";" + osm_nodes[n][:lon].to_s + "\n" }
File.write("Nodes.csv", str)

# write edges file
str = "Source;Target;Road;Road_Type;Dist;Type\n"
edges.each { |e| str += e + "\n" }
File.write("Edges.csv", str)
