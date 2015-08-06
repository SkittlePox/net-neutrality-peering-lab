library(plyr)
library(ggplot2)

# read in data from Internap-hosted measurement server in NYC
lga01 <- read.table("Network-interconnection-lga01.csv", header=FALSE, sep=",", fill=TRUE)
# read in data from Cogent-hosted measurement server in NYC

lga02 <- read.table("Network-interconnection-lga02.csv", header=FALSE, sep=",", fill=TRUE)

name.vector <- c("time", "client.ip", "client.hostname", "mid.throughput", 
                "s2c.throughput", "c2s.throughput", "timeouts", "sum.rtt", 
                "count.rtt", "pkts.retrans", "FastRetran", "DataPktsOut", 
                "AckPktsOut", "CurMSS", "DupAcksIn", "AckPktsIn", "MaxRwinRcvd", 
                "Sndbuf", "MaxCwnd", "SndLimTimeRwin", "SndLimTimeCwnd", "SndLimTimeSender", 
                "DataBytesOut", "SndLimTransRwin", "SndLimTransCwnd", "SndLimTransSender", 
                "MaxSsthresh", "CurRTO", "CurRwinRcvd", "link", "duplex.mismatch", "bad.cable", 
                "half.duplex", "congestion", "c2sdata", "c2sack", "c2cdata", "s2cack", 
                "CongestionSignals", "Packets.out", "MinRTT", "RcvWinScale", 
                "autotune.deprecated", "CongAvoid", "CongestionOverCount", "MaxRTT", 
                "OtherReductions", "CurTimeoutCount", "AbruptTimeouts", "SendStall", 
                "SlowStart", "SubsequentTimeouts", "ThruBytesAcked", "peaks.amount", 
                "peaks.min", "peaks.max")

names(lga01) <- name.vector
names(lga02) <- name.vector

lga01$server.hostname <- "Internap"
lga02$server.hostname <- "Cogent"

dat <- rbind(lga01, lga02)
dat$mid.throughput <- as.numeric(levels(dat$mid.throughput))[dat$mid.throughput]
dat$time <- strptime(dat$time, "%Y%m%dT%H:%M:%OSZ")
dat$day <- format(dat$time, format="%Y-%m-%d")
dat$day <- as.Date(dat$day)
dat <- na.omit(dat)
dat$isp <- "Unknown"
dat[grepl("comcast", dat$client.hostname),]$isp <- "Comcast"
dat[grepl("verizon", dat$client.hostname),]$isp <- "Verizon"
dat[grepl("bell.ca", dat$client.hostname),]$isp <- "Bell Canada"
dat[grepl("optonline", dat$client.hostname),]$isp <- "Optimum/Cablevision"

sub.dat <- dat[dat$isp=="Comcast",]

sub.dat$tput.mbps <- sub.dat$s2c.throughput/1000

dat.summarized <- ddply(sub.dat,~ server.hostname + day, summarise, 
			count=length(tput.mbps),
			mean=mean(tput.mbps),
			median=median(tput.mbps),
			sd=sd(tput.mbps))

q <- ggplot(dat.summarized) + theme_classic()
q <- q + geom_line(aes(x=day, y=mean, colour=server.hostname), size=3)
# the ribbon shows the standard error, which is important in terms
# of good statistical practice
q <- q + geom_ribbon(aes(ymin=mean-sd/sqrt(count), ymax=mean+sd/sqrt(count), fill=server.hostname, x=day), alpha=0.2)
# we specify color to highlight the line that is most important (the duck)
q <- q + scale_colour_manual("Tier 1 ISP", values=c("#d11255","#909090"))
q <- q + scale_fill_manual("Tier 1 ISP", values=c("#d11255","#909090"))
# Label the graph and each axis
q <- q + ggtitle("Mean download throughput for Comcast customers\nfrom different Tier 1 ISPs in NYC in Feb. 2014 (higher is better)")
q <- q + scale_y_continuous("Download rate (megabits per second)", limits=c(0,38))
q <- q + scale_x_date("")
# put legend on bottom
q <- q + theme(legend.position="bottom")
# add some annotations
#q <- q + geom_vline(xintercept=as.numeric(as.Date("2014-02-23")), linetype=2)
q <- q + annotate(geom="text", colour="#505050", 
     label="February 23:\nNetflix negotiates\ndirect connection\nto Comcast", 
     x=as.Date("2014-02-24"), y=32)
q <- q + annotate(geom="text", colour="#505050", 
     label="February 21:\nTraceroute reveals\nComcast-Netflix\ndirect connection", 
      x=as.Date("2014-02-18"), y=32)

png("network-interconnections.png", width=800, height=600)
print(q)
dev.off()
