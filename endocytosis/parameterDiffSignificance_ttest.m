function [ttestpval, results] = parameterDiffSignificance_ttest(compRes1,compRes2)
% determine significance in the difference of each fit parameter between
% two conditions, using a t-test on the mean and standard deviation, the
% latter of which was estimated through a jackknife assay
% 
% SYNOPSIS: [ttestpval, results] = parameterDiffSignificance_ttest(compRes1,compRes2)
%
% INPUT     compRes1 = compact fit results data set 1 
%           compRes2 = compact fit results data set 2
%           These compact fit results data sets have to contain a field called 
%           .matrix, 
%           NOTE: The data format of compRes is the result of the function
%           lifetimeCompactFitData
%           This is the same format that is created by running the function
%           runLifetimeAnalysis
%
% OUTPUT    ttestpval   = p-value of the t-test, for all parameters, in the
%                         format [contributions, taus]
%           results     = contains the fields 
%                           .contributions
%                           .timeConstants
%           which both have the format (successive columns)
%           [mean1 std1 mean2 std2 p-value]
% 
% last modified: Dinah Loerke 04/20/2009
%
% NOTE: The updated version of this function can deal with a comparison of
% fit results with different numbers of subpopulation (e.g. 3 vs. 4) -
% in this case, the p-values are calculated for the comparison between the
% maximum available number of distributions (pop1 to pop1, pop2 to pop2,
% pop3 to pop3, and pop4 unmatched)

% extract mean values from compact fit results; 
% first column (1) = contributions, second column (3) = time constants
meanValues1 = compRes1.matrix(:,[1,3]);
meanValues2 = compRes2.matrix(:,[1,3]);

stdValues1  = compRes1.matrix(:,[2,4]);
stdValues2  = compRes2.matrix(:,[2,4]);

nValues1    = compRes1.matrix(1,6);
nValues2    = compRes2.matrix(1,6);

[sr1,sc1] = size(meanValues1);
[sr2,sc2] = size(meanValues2);
minrow = min(sr1,sr2);
maxrow = max(sr1,sr2);

ttestpval = nan*zeros(maxrow,sc1);

for i=1:minrow
    for k=1:sc1
        values1 = [meanValues1(i,k) stdValues1(i,k) nValues1];
        values2 = [meanValues2(i,k) stdValues2(i,k) nValues2];
        [pval] = ttest2OnValues(values1,values2);
        ttestpval(i,k) = pval;
    end
end

cont = nan*zeros(maxrow,5);
taus = nan*zeros(maxrow,5);

cont(1:sr1,1:2) = [meanValues1(:,1),stdValues1(:,1)];
cont(1:sr2,3:4) = [meanValues2(:,1),stdValues2(:,1)];
cont(1:maxrow,5) = ttestpval(:,1);

taus(1:sr1,1:2) = [meanValues1(:,2),stdValues1(:,2)];
taus(1:sr2,3:4) = [meanValues2(:,2),stdValues2(:,2)];
taus(1:maxrow,5) = ttestpval(:,2);

results.contributions = cont;
results.timeConstants = taus;



end % of function


%% SUBFUNCTION

function [pval]=ttest2OnValues(val1,val2);
% calculate p-val of t-test to compare means of two distributions
% INPUT     val1 = [mean, std, n] of first distribution
%           val2 = [mean, std, n] of second distribution
% OUTPUT    pval
%
% NOTE: This function is written to determine the p-value of the difference
% between two distributions for which the mean, standard deviation, and
% sample size are known; this function does not require the input of the
% original distribution. Thus, this function can be used to estimate the
% significance of the difference between two distributions for which the
% standard deviation is estimated through a jackknife assay.

% mean of distributions
mean1   = val1(1);
mean2   = val2(1);
% variance of distributions
var1    = val1(2)^2;
var2    = val2(2)^2;
% sample size of each distribution
n1      = val1(3);
n2      = val2(3);

% standard error for unequal sample size, unequal variance
% see http://en.wikipedia.org/wiki/Student%27s_t-test
s12 = sqrt( (var1/n1) + (var2/n2) );

% t-statistic
tstat = (mean1-mean2)/s12;

% degrees of freedom: MOST CONSERVATIVE ESTIMATE
df = min((n1-1),(n2-1));
 
% degrees of freedom: FRACTIONAL ESTIMATE
% df = ((var1/n1)+(var2/n2))^2 / ( (var1/n1)^2/(n1-1) + (var2/n2)^2/(n2-1) );
  
% p-value for this t-statistic and specified degrees of freedom
% is defined as the integral of probability density function (pdf) of the 
% t-distribution between -tstat and +tstat; this is equivalent to the
% cumulative distribution function (cdf) at tstat minus cdf at -tstat
% NOTE: we want the 'inverse' p value (close to zero for highly
% significant, close to one for not significant)
pval = 1 - (tcdf(abs(tstat),df) - tcdf(-abs(tstat),df));

end
  
    