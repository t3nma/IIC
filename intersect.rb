require 'nokogiri'

doc = Nokogiri::XML(File.open(ARGV[0]))

=begin
Save all <node>'s latitude and longitude in a hash,
they are needed later.
=end
xml_nodes = {}
doc.xpath("//node").each do |node|
  atrs = node.attributes
  id = atrs["id"].value.to_s

  xml_nodes[id] = {}
  xml_nodes[id][:lat] = atrs["lat"].value.to_s
  xml_nodes[id][:lon] = atrs["lon"].value.to_s
end

=begin
Save all residential <way>'s in a hash, 
they are needed later. Find and save final 
graph's nodes at the same time.
=end
xml_ways = {}
seen = {}
V = {}
doc.xpath("//way").each do |way|

  w = {}
  w[:nds] = []
  w[:name] = "UNAMED"

  valid = false;

  way.elements.each do |elem|
    atrs = elem.attributes

    # nd ?
    if elem.name == "nd"
      w[:nds] << atrs["ref"].value.to_s
    end

    # tag ?
    if elem.name == "tag"
      atrs = elem.attributes

      if atrs["k"].value == "highway" && atrs["v"].value == "residential"
        valid = true
      elsif atrs["k"].value == "name"
        w[:name] = atrs["v"].value.to_s
      end
    end
  end

  if valid
    xml_ways[way.attributes["id"].value.to_s] = w

    w[:nds].each do |nd|
      if seen[nd].nil?
        seen[nd] = {}
      elsif V[nd].nil? # <node> seen at least twice, this is a valid vertex!
        V[nd] = {}
      end
    end
  end

end

=begin
Write nodes file.
=end
str_nodes = "Id;Latitude;Longitude\n"
V.each { |v| str_nodes += v[0] + ";" + xml_nodes[v[0]][:lat] + ";" + xml_nodes[v[0]][:lon] + "\n" }
File.write("Nodes.csv", str_nodes)

=begin
Find and save final graph's edges.
=end
E = []
xml_ways.each do |k,v|
  prev = nil 
  v[:nds].each do |nd|
    if !V[nd].nil?
      if !prev.nil?
        elem = {}
        elem[:source] = prev
        elem[:dest] = nd
        elem[:street] = v[:name]
        elem[:type] = "Undirected"
        E << elem
      end
      prev = nd
    end
  end
end

=begin
Write edges file.
=end
str_edges = "Source;Target;Street;Type\n"
E.each { |e| str_edges += e[:source] + ";" + e[:dest] + ";" + e[:street] + ";" + e[:type] + "\n" }
File.write("Edges.csv", str_edges)
