####### Regression #######
###### Regression

### Dominick's OJ Regression
oj<-read.csv("OJ.csv",strings=T) #strings=T makes character into factor
head(oj)
levels(oj$brand)

## plots
# create some colors for the brands then plot
brandcol <- c("green","red","gold")
#png('ojBoxplots.png', width=3, height=5, units="in", res=720)
boxplot(price ~ brand, data=oj, col=brandcol, bty="n", horizontal=TRUE, xaxt='n')
axis(1, at=c(1,2,3,4))
#dev.off()

#png('ojScatterplot.png', width=3, height=5, units="in", res=720)
plot(log(sales) ~ log(price), data=oj, col=brandcol[oj$brand], bty="n", cex=.5)
#dev.off()
#png('ojRawScatterplot.png', width=3, height=5, units="in", res=720)
plot(sales ~ price, data=oj, col=brandcol[oj$brand], bty="n", cex=.5)
#dev.off()

oj$featured <- factor(oj$ad==1)
#png('OJsales.png', width=5, height=5, units="in", res=720)
plot(brand ~ featured, data=oj, col=rev(brandcol), bty="n", cex=.5)
#dev.off()
############################

## simple log-log plus brand regression
fit<-glm(log(sales) ~ brand + log(price),data=oj)  
coef(fit)

# scatterplot with lines
beta <- coef(fit)
plot(log(sales) ~ log(price), data=oj, col=brandcol[oj$brand], 
	cex=.1, pch=20, bty="n")
abline(a=beta[1], b=beta[4], col=brandcol[1], lwd=2)
abline(a=beta[1]+beta[2], b=beta[4], col=brandcol[2], lwd=2)
abline(a=beta[1]+beta[3], b=beta[4], col=brandcol[3], lwd=2)
legend("bottomleft", bty="n", lwd=2, col=brandcol, legend=levels(oj$brand))

# exploring model matrix
oj[c(100,200,300),]
x <- model.matrix( ~ log(price) + brand, data=oj)
x[c(100,200,300),]

# add interaction
# note that '*' also adds the main effects automatically
fit2way <- glm(log(sales) ~ log(price)*brand, data=oj)
coef(fit2way)

# compare brand-specific log(price) slopes to our earlier elasticity (-3.1)
beta<-coef(fit2way)
plot(log(sales) ~ log(price), data=oj, col=brandcol[oj$brand], 
	cex=.1, pch=20, bty="n")
abline(a=beta[1], b=beta[2], col=brandcol[1], lwd=2)
abline(a=beta[1]+beta[3], b=beta[2]+beta[5], col=brandcol[2], lwd=2)
abline(a=beta[1]+beta[4], b=beta[2]+beta[6], col=brandcol[3], lwd=2)
legend("bottomleft", bty="n", lwd=2, col=brandcol, legend=levels(oj$brand))

# and finally, consider 3-way interactions
fit3way <- glm(log(sales) ~ log(price)*brand*ad, data=oj)
coef(fit3way)

# making predictions
# create some data for prediction, using the data.frame function
# note the care in specifying brand factor (levels must match original data)
# we don't need all variables in oj; just those used as covariates in regression
newdata=data.frame(price=rep(2,3), 
	brand=factor(c("tropicana","minute.maid","dominicks"),
			levels=levels(oj$brand)),
	ad=rep(1,3))
# predict
predict(fit3way, newdata=newdata)  ## predicted log units moved
exp(predict(fit3way, newdata=newdata)) ## predicted # of units moved


# for the elasticities table
b <- coef(fit3way)
b["log(price)"] 
b["log(price)"] + b["log(price):brandminute.maid"]
b["log(price)"] + b["log(price):brandtropicana"]
b["log(price)"] + b["log(price):ad"] 
b["log(price)"] + b["log(price):brandminute.maid"] + b["log(price):ad"] + b["log(price):brandminute.maid:ad"]
b["log(price)"] + b["log(price):brandtropicana"] + b["log(price):ad"] + b["log(price):brandtropicana:ad"]

## deviance
summary(fit3way) #deviances printed at bottom of output
# or we can calculate them
( SST <- sum( (log(oj$sales) - mean(log(oj$sales)))^2 ) )
( SSE <- sum( ( log(oj$sales) - fit3way$fitted )^2 ) )

# R-squared
1 - fit3way$deviance/fit3way$null.deviance # glm attributes
1 - SSE/SST # using SSE AND SST 
cor(fit3way$fitted,log(oj$sales))^2 # correlation squared

## degrees of freedom
summary(fit3way) # at bottom of output
# glm estimates residual variance ("dispersion") by SSE divided by residual df
SSE/fit3way$df.residual

##########################################


# Model fit statistics
summary(fit3way)
1-fit3way$deviance/fit3way$null.deviance #1 - 13975/30079


# table explaining why ads confounded our brand elasticity estimates
salestable <- tapply(oj$sales, oj[,c("ad","brand")], sum)
mosaicplot(salestable,col=brandcol)


# fit plots and R^2 
# (the 'bty="n"' option removes boxes around your plot)
#png('ojFittedVSy.png', width=5, height=5, units="in", res=720)
plot(log(oj$sales) ~ fit3way$fitted, col=brandcol[oj$brand], 
	bty="n", ylim=range(c(fit3way$fitted,log(oj$sales))),
	xlim=range(c(fit3way$fitted,log(oj$sales))),
	ylab="observed log(sales)", xlab="fitted log(sales)")
abline(a=0,b=1)#  add a line with slope 1, intercept 0
legend("topleft",legend=levels(oj$brand),fill=brandcol, bty="n")
#dev.off()

############################
### Causal inference chapter
oj<-read.csv("OJ.csv",strings=T)
head(oj)
basefit <- glm(log(sales) ~ log(price), data=oj)
coef(basefit)
brandfit <- glm(log(sales) ~ log(price) + brand, data=oj)
coef(brandfit)

# single residualization
pricereg <- glm(log(price) ~ brand, data=oj)
dhat <- predict(pricereg, newdata=oj)
dtil <- log(oj$price)-dhat
coef( glm( log(sales) ~ dtil, data=oj) )

# double residualization
salesreg <- lm(log(sales) ~ brand, data=oj)
yhat <- predict(salesreg, newdata=oj)
ytil<- log(oj$sales) - yhat
coef( glm( ytil ~ dtil -1 ) )

## same thing with an intercept
coef( glm( ytil ~ dtil) ) 


############################
### regularization chapter
# Sparse Model Matrices
oj<-read.csv("oj.csv",strings=T)
modMat<-model.matrix(~log(price)+brand,data=oj)
modMat[c(100,200,300),] 

library(gamlr)
ojdf <-naref(oj)
ojdf[c(100,200,300),"brand"]
modMatAllLevs<-model.matrix(~log(price)+brand,data=ojdf)[,-1] 
modMatAllLevs[c(100,200,300),]

# make it a sparse representation
library(Matrix)
xOJ<-sparse.model.matrix(~log(price)+brand,data=ojdf)[,-1]
xOJ[c(100,200,300),]

# Simple triplet matrix
rowNum<-c(1,3,2)
colNum<-c(1,1,2)
non0data<-c(-4,5,10)
sparseMat<-sparseMatrix(i=rowNum,j=colNum,x=non0data,
     dims=c(3,2),
     dimnames=list(c("r1","r2","r3"),c("c1","c2")))
sparseMat
str(sparseMat)

library(gamlr)
fitOJ <- gamlr(x=xOJ, y=log(ojdf$sales))
png('ojLasso.png', width=4.5, height=4.5, units="in", res=720)
plot(fitOJ)
dev.off()

names(fitOJ)

oj$brand <- relevel(ojdf$brand, "minute.maid")
glm(log(sales) ~ log(price) + brand, data=oj)

fitOJfree <- gamlr(x=xOJ, y=log(ojdf$sales), free="log(price)")
fitOJfree$beta[,c(1:2,99:100)]