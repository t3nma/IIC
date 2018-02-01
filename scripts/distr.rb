abort("USAGE: ruby distr.rb Nodes.csv") if ARGV.empty?

b = {}
c = {}

nline = 0

File.foreach(ARGV[0]).with_index do |line, ix|
  next if ix == 0

  nline += 1
  
  line = line.gsub(/\n/, "")
  tokens = line.split(";")

  bvalue = tokens[3].to_f
  cvalue = tokens[4].to_f.round(2)

  if b[bvalue.to_s].nil?
    b[bvalue.to_s] = 0
  end

  if c[cvalue.to_s].nil?
    c[cvalue.to_s] = 0
  end

  b[bvalue.to_s] += 1
  c[cvalue.to_s] += 1
  
end

str = ""
b.each do |k,v|
  prob = v.to_f/nline
  str += k + " " + prob.to_s + "\n"
end

File.write("betweenness.txt", str)

str = ""
c.each do |k,v|
  prob = v.to_f/nline
  str += k + " " + prob.to_s + "\n"
end

File.write("closeness.txt", str)
