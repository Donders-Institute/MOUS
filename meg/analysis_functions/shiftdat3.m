function outs = shiftdat3(dat, lags, maxlag)

% this function creates a matrix from a vector, where each row is time
% shifted with lag. 

n   = numel(lags);
n2  = size(dat,2);
outs = zeros(n,n2+maxlag*2);
for i = 1:n
    outs(i,maxlag+lags(i)+(1:n2)) = dat;
end

x = 1;

