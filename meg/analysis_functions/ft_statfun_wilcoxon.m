function stat = ft_statfun_wilcoxon(cfg, dat, design)

cfg.out = ft_getopt(cfg, 'out', 'Z');

sel1 = find(design(cfg.ivar,:)==1);
sel2 = find(design(cfg.ivar,:)==2);

uvar1 = design(cfg.uvar,sel1);
uvar2 = design(cfg.uvar,sel2);

[~, i1,i2] = intersect(uvar1, uvar2);
diffdat    = dat(:,sel1(i1))-dat(:,sel2(i2));

diffdat(diffdat==0) = nan;                      % eliminate null variations
n                   = sum(isfinite(diffdat),2); % number of ranks, excluding the nans

% Ranks of absolute value of samples differences with sign
[r,t] = tiedrank(abs(diffdat)); % ranks and ties, use custom subfunction that operates on matrices
W     = nansum(r.*sign(diffdat),2);  % Wilcoxon statics (sum of ranks with sign)

sW = sqrt((2.*n.^3+3.*n.^2+n-t)/6); % standard deviation
zW = (W-0.5.*sign(W))./sW;          % z-value with correction for continuity

switch cfg.out
  case 'Z'
    stat.stat = zW;
  case 'W'
    stat.stat = W;
end


function [ranks, tieadj] = tiedrank(x)
%TIEDRANK Compute the ranks of a sample, adjusting for ties.
%   [R, TIEADJ] = TIEDRANK(X) computes the ranks of the values in the
%   vector X.  If any X values are tied, TIEDRANK computes their average
%   rank.  The return value TIEADJ is an adjustment for ties required by
%   the nonparametric tests SIGNRANK and RANKSUM, and for the computation
%   of Spearman's rank correlation.
%
%   This version of TIEDRANK uses an absolute tolerance of zero by default.
%
%   See also ANSARIBRADLEY, CORR, PARTIALCORR, RANKSUM, SIGNRANK.

% Sort, then leave the NaNs (which are sorted to the end) alone
[sx, srtidx] = sort(x, 2);
numNaNs      = sum(isnan(x),2);
xLen         = size(x,2) - numNaNs;

% Use ranks counting from low end
ranks = ones(size(x,1),1)*(1:size(x,2));
ranks(isnan(sx)) = nan;

tieadj = zeros(size(x,1),1);
if isa(x,'single')
  ranks  = single(ranks);
  tieadj = single(tieadj);
end

% Adjust for ties.  Avoid using diff(sx) here in case there are infs.
ties  = sx(:,1:end-1) >= sx(:,2:end);

[tierow, tiecol] = find(ties); tierow = tierow(:); tiecol = tiecol(:);
urows = unique(tierow);
for k = 1:numel(urows)
  tieloc  = cat(1,tiecol(tierow==urows(k)),xLen(urows(k)));
  maxTies = numel(tieloc);
  
  tiecount = 1;
  while (tiecount < maxTies)
    tiestart = tieloc(tiecount);
    ntied = 2;
    while(tiecount< maxTies && tieloc(tiecount+1) == tieloc(tiecount)+1)
      tiecount = tiecount+1;
      ntied = ntied+1;
    end
    tieadj(urows(k)) = tieadj(urows(k)) + ntied*(ntied-1)*(ntied+1)/2;
     
    % Compute mean of tied ranks
    ranks(urows(k),tiestart:tiestart+ntied-1) = ...
                sum(ranks(urows(k),tiestart:tiestart+ntied-1)) / ntied;
    tiecount = tiecount + 1;
  end
end

% Broadcast the ranks back out, including NaN where required.
for k = 1:size(ranks,1)
  ranks(k,srtidx(k,:)) = ranks(k,:);
end



%This file execute the non parametric Wilcoxon test to evaluate the difference between paired (dependent) samples. 
%If the number of difference is less than 15, the algorithm calculate the exact ranks distribution; 
%else it uses a normal distribution approximation. 
%Now, the MatLab function SIGNRANK returns the same p-value. 
%Anyway, this Wilcoxon function gives a more detailed output (that is necessary for publications...)
%By itself Wilcoxon will run the demo
%
% Syntax: 	STATS=WILCOXON(X1,X2,PLTS)
%      
%     Inputs:
%           X1 and X2 - data vectors.
%           PLTS - Flag to set if you don't want (0) or want (1) view the plots
%     Outputs:
%           - W value and p-value when exact ranks distribution is used.
%           - W value, Z value, Standard deviation (Mean=0), p-value when normal distribution is used
%        If STATS nargout was specified the results will be stored in the STATS
%        struct.
%
%      Example: 
%
%         X1=[77 79 79 80 80 81 81 81 81 82 82 82 82 83 83 84 84 84 84 85 85 86 86 87 87];
% 
%         X2=[82 82 83 84 84 85 85 86 86 86 86 86 86 86 86 86 87 87 87 88 88 88 89 90 90];
%
%           Calling on Matlab the function: wilcoxon(X1,X2)
%
%           Answer is:
%
% WILCOXON TEST
% --------------------------------------------------------------------------------
% Sample size is good enough to use the normal distribution approximation
%  
% W         mW		sW          zW          p-value (2-tailed)
% --------------------------------------------------------------------------------
% 325  	     0		73.1608   4.4354	0.0000
% --------------------------------------------------------------------------------
%
%           Created by Giuseppe Cardillo
%           giuseppe.cardillo-edta@poste.it
%
% To cite this file, this would be an appropriate format:
% Cardillo G. (2006). Wilcoxon test: non parametric Wilcoxon test for paired samples.
% http://www.mathworks.com/matlabcentral/fileexchange/12702
