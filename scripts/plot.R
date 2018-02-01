library("distr")
b <- read.table(file="betweenness.txt", sep=" ")
fx <- DiscreteDistribution(supp=b$V1, prob=b$V2)

png("betweennessCDF.png", width=900, height=350, res=120)
plot(fx, xlabel="Cb", ylabel="P(Cb)")
dev.off

c <- read.table(file="closeness.txt", sep=" ")
fx <- DiscreteDistribution(supp=c$V1, prob=c$V2)

dev.new()
png("closenessCDF.png", width=900, height=350, res=120)
plot(fx, xlabel="Cc", ylabel="P(Cc)")
dev.off