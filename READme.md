CAPM Model

Estimating beta in 2 ways and comparing them to observed returns
1. Using simple linear regression with a windowed time period for calculation of variance and covariances.
2. Using dcc-garch model to calculate time varying beta.

The dataset used for the estimation are the prices of 51 stocks in the NSE between 2005 and 2015.
NIFTY 50 index is used as market indicator.
The risk free rate of return is captured using bond yield(daily) of 10-year GoI bond.

In the first part, the beta value of each security is computed by fitting a linear regression model to the past 250 days of returns of each of the 51 stocks and return of NIFTY 50 index. Predicted stock return is calculated using capm equation.
In the second part, the beta value of each security is calculated by fitting a dcc-garch(Dynamic Conditional Correlation - GARCH) model to the timeseries of 2-d vectors containing the stock return and market return.

Error analysis was done using the sum of squares of the difference between the predicted stock return and actual stock return.
Result: Beta prediction was better in dcc-garch model than regular regression in  out of the 51 stocks.
