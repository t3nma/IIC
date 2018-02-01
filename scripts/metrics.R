# call tnet and load network
library("tnet")
net <- read.table(file = "edgelist.txt", sep = " ", header = FALSE)
net <- as.tnet(net = net, type="weighted one-mode tnet")
net <- symmetrise_w(net = net)

# compute betweenness and filter results
b <- betweenness_w(net = net)
b <- b[,-1]

# compute closeness and filter results
c <- closeness_w(net = net, gconly = FALSE)
c <- c[,-1]
c <- c[,-2]

# write results to files
write.csv(x = b, file = "betweenness.csv", quote = FALSE, row.names = FALSE, sep = ";")
write.csv(x = c, file = "closeness.csv", quote = FALSE, row.names = FALSE, sep = ";")