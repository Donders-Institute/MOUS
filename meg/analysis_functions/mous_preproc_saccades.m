function [datout] = mous_preproc_saccades(dat, x)

% MOUS_PREPROC_SACCADES serves the purpose as a custom function to be
% called in preproc, in order to maximize sensitivity to the features of a
% saccade.
% 
% The processing is as follows:
%  - 1. remove slow trend
%  - 2. apply a median filter
%  - 3. compute the acceleration (second derivative)
%  - 4. smooth the acceleration signal
%  - 5. computing a local measure of the std
%  - 6. threshold
%  - 7. locally integrate, i.e. collapse closely spaced samples with same
%        sign acceleration into 1 sample
%  - 8. rectify

datorig = dat - mean(dat);

[m,n] = size(dat);
if m>1,
  error('only a single signal is allowed');
end

% 1
dat  = dat - ft_preproc_smooth(dat, 1200);

% 2
datm = ft_preproc_medianfilter(dat,51);

% 3
dat  = [mean(datm(:,1:3),2)*ones(1,3) datm mean(datm(:,end-2:end),2)*ones(1,3)];
dat  = convn(dat, [1 -2 1], 'same'); % second derivative
dat  = dat(:,4:end-3); % un-pad

% 4
dat  = ft_preproc_smooth(dat, 100);

% 5
dats = sqrt(ft_preproc_smooth(abs(dat).^2,200));

% 6
datthr = max(dat-3.*dats,0) + min(dat+3.*dats,0);

% 7 & 8
datthr = ft_preproc_smooth(datthr, 15).*15;
onset  = [diff(datthr~=0) 0] & datthr==0;

dattrig = zeros(size(datthr));
sel    = find(onset)+15;
sel(sel>n) = [];
%datout(sel-15) = dat(sel);
dattrig(sel) = datthr(sel);

% now go back to datm and combine with info from datout to classify as
% saccade
%triggers     = find(dattrig);
triggers     = find(standardise(abs(dattrig))>5);
triggerssign = sign(dattrig(triggers));

datout = zeros(size(dattrig));
for k = 1:numel(triggers)-1
  %begsmp = max(1,triggers(k)-20);
  %endsmp = min(size(dat,2), triggers(k+1)+20);
  begsmp = triggers(k);
  endsmp = triggers(k+1);
  tmpdat = datm(begsmp:endsmp);
  tmpdat = tmpdat-mean(tmpdat);
  
  if triggerssign(k)~=triggerssign(k+1)
    % acceleration deceleration sequence
    
    % fit a step function
    npoint   = numel(tmpdat);
    midpoint = round(mean(triggers(k:(k+1))))-triggers(k);
    model    = [zeros(1,midpoint) ones(1,npoint-midpoint)];
    model    = model-mean(model);
    beta     = tmpdat/model;
    residual = tmpdat - beta*model;
    R        = 1 - sum(residual.^2)./sum(tmpdat.^2);
    % rationale: if the R squared > threshold, then the data looks like a
    % step function locally
    if R>0.8
      % refine a bit
%       tmpbeta  = beta;
%       Rtmp     = R;
%       for kk = 2:2:midpoint
%         tmpmodel = [zeros(1,midpoint-kk) linspace(0,1,2*kk) ones(1,npoint-midpoint-kk)];
%         tmpmodel = tmpmodel-mean(tmpmodel);
%         tmpbeta  = tmpdat/tmpmodel;
%         res      = tmpdat - tmpbeta*tmpmodel;
%         Rtmp     = 1 - sum(res.^2)./sum(tmpdat.^2);
%         if Rtmp>R
%           R = Rtmp;
%           beta = tmpbeta;
%         else
%           break;
%         end
%       end
%       %if triggers(k)>2000,keyboard;end 
      datout(triggers(k):triggers(k+1)) = abs(beta).*sqrt(R);
    end
  else
  end
end


