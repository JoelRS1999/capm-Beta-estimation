library(xts)
print(load("/home/joel/ansue_finance_summer_school/data/DATA/BLOCK1/demo_dailydata.rda"))

b<-read.csv("/home/joel/Bond-Yield-05-15.csv")

nif<-matrix(NA,nrow = 0,ncol = 7)
for(i in 2005:2015)
{
    nif<-rbind(nif,read.csv(paste("/home/joel/nifty_",i,".csv",sep = "")))
}
nif<-as.data.frame(nif)    

library(lubridate)
b<-as.data.frame(b)
b$Date<-parse_date_time(b$Date, orders = "bdy")
b<-as.xts(b, order.by = b$Date)
bond<-b[,-1]
bond<-bond[,-5]
storage.mode(bond)<-"numeric"
head(bond)
remove(b)
bond<-bond[,1]
bond<-bond/(100*250)

nifty<-as.xts(nif, order.by = parse_date_time(nif$Date, "%d-%b-%y"))
nifty<-nifty[,-1]
storage.mode(nifty)<-"numeric"
nifty_ret<-diff(log(nifty[,4]))
nifty_ret[1]<-log(nifty[1,4]/nifty[1,1])
reldates<-as.Date(intersect(as.character.Date(index(bond)), as.character.Date(index(nifty_ret))))

ret_data<-cbind(bond[reldates], nifty_ret[reldates], as.xts(dailyreturns[reldates]))
colnames(ret_data)[c(1:2)]<-c("BOND_YIELD","NIFTY")

prem<-bond[reldates]
k<-0
full<-numeric(0)
for(i in 2:308)
{
    if(any(is.na(ret_data[,i]))==FALSE)
    {
        k<-k+1
        full<-c(full,i)
        prem<-cbind(prem,ret_data[,i] - ret_data[,1])
    }
}
colnames(prem)[1]<-"BOND_YIELD"

win<-250
beta<-matrix(ncol = 0, nrow = 2672 - win)
#beta_c<-matrix(ncol = 0, nrow = 2672 - win)
s<-Sys.time()
for(j in 3:53)
{
    bet_j<-numeric(0)
    #bet_c<-numeric(0)
    for(i in (win+1):2672)
    {
        bet_j<-rbind(bet_j,lm(paste(colnames(prem)[j], "~NIFTY"), data = prem[(i-win):(i-1),])$coefficients[2])
        #bet_c<-rbind(bet_c,cov(prem[(i-win):i,j], prem[(i-win):i,2])/var(prem[(i-win):i,2]))
    }
    beta<-cbind(beta,bet_j)
    #beta_c<-cbind(beta_c, bet_c)
    remove(bet_j)
}
e<-Sys.time()
colnames(beta)<-colnames(prem)[3:53]
beta<-as.xts(beta, order.by = index(prem)[(win+1):2672])
#colnames(beta_c)<-colnames(prem)[3:53]
#beta_c<-as.xts(beta_c, order.by = index(prem)[(win+1):2672])
e - s

library(rmgarch)
uspec<-ugarchspec(mean.model = list(armaOrder = c(1,0)), distribution.model = "std")
mspec<-multispec(replicate(2, uspec))
dspec<-dccspec(uspec = mspec)
dcc_beta<-matrix(nrow = 2672, ncol = 0)
s<-Sys.time()
for(j in 3:53)
{
    model.fit<-dccfit(spec = dspec, data = prem[,c(2,j)])
    bet_j<-rcov(model.fit)[1,2,]/rcov(model.fit)[1,1,]
    dcc_beta<-cbind(dcc_beta, bet_j)

}
e<-Sys.time()
e - s

remove(bet_j)
colnames(dcc_beta)<-colnames(prem)[3:53]
dcc_beta<-as.xts(dcc_beta, order.by = index(prem))
dcc_beta.test<-dcc_beta[as.Date(intersect(as.character(index(beta)),as.character(index(dcc_beta))))]

ex<-prem[index(dcc_beta.test), 3:53]

pred_dcc<-dcc_beta.test*replicate(51,as.vector(prem[index(dcc_beta.test),2]))
ssr_dcc<-colSums((pred_dcc-ex)^2)

pred_olswin<-beta*replicate(51,as.vector(prem[index(beta), 2]))
ssr_olswin<-colSums((pred_olswin - ex)^2)
