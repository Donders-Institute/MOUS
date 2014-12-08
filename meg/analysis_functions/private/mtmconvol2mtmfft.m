function output = mtmconvol2mtmfft(input, fsample)

hascrs     = isfield(input, 'crsspctrm');
hasfourier = isfield(input, 'fourierspctrm');

allpow     = [];
allcrs     = [];
allfourier = [];
alltrialinfo = [];
cumtapcnt  = [];
origtrl    = [];
if hascrs,     siz = size(input.crsspctrm);     end
if hasfourier, siz = size(input.fourierspctrm); end

if hascrs,
  for j = 1:siz(1)
    fprintf('computing trial %d of %d\n',j,siz(1));
    sizpow = size(input.powspctrm);
    dumpow = reshape(input.powspctrm(j,:,:,:), [sizpow(2) sizpow(3) sizpow(4)]);
    sizcrs = size(input.crsspctrm);
    dumcrs = reshape(input.crsspctrm(j,:,:,:), [sizcrs(2) sizcrs(3) sizcrs(4)]);     
    sel = find(~isnan(dumpow(1,1,:)));
    if length(size(dumcrs))==3,
      allpow = cat(3,allpow,dumpow(:,:,sel));
      allcrs = cat(3,allcrs,dumcrs(:,:,sel));
    else
      allpow = cat(3,allpow,dumpow(:,:,sel));
      allcrs = cat(2,allcrs,dumcrs(:,sel));
    end
  end
elseif hasfourier,
  nsmp = input.cfg.t_ftimwin(1)*fsample;
  if isfield(input.cfg, 'tapsmofrq')
    if ~all(input.cfg.tapsmofrq==input.cfg.tapsmofrq(1)), error('cannot do reformatting, since a different number of tapers is used for the frequencies'); end
    ntap = input.cumtapcnt(1);
  else
    input.cfg.tapsmofrq = ones(1,numel(input.freq));
    ntap = 1;
  end
  if ~all(input.cfg.t_ftimwin==input.cfg.t_ftimwin(1)), error('cannot do reformatting, since a different window is used for the frequencies');           end
  
  siz          = size(input.fourierspctrm);
  siz2         = size(input.cumtapcnt,1);
  
  allfourier   = reshape(permute(input.fourierspctrm,[1 4 2 3]), [siz(1)*siz(4) siz(2) siz(3)]);
  allcumtapcnt = repmat(input.cumtapcnt, [siz(4) 1]);
  alltrialinfo = repmat(input.trialinfo, [siz(4) 1]);
  
  ncol = size(alltrialinfo,2);
  for k = 1:siz(4)
    alltrialinfo((k-1)*siz2(1)+(1:siz2(1)), ncol+1) = 1:siz2;
    alltrialinfo((k-1)*siz2(1)+(1:siz2(1)), ncol+2) = k;
  end
  
  sel1       = isfinite(allfourier(:,1));
  allfourier = allfourier(sel1,:,:);
  sel1       = find(sel1);
  sel1       = sel1(mod(sel1,ntap)==0);
  sel1       = sel1./ntap;
  
  alltrialinfo = alltrialinfo(sel1,:);
  cumtapcnt = allcumtapcnt(sel1,:);
  
  %FIXME behavior has changed sept 2012: as a concession to computational efficiency,
  %the concatenation is now: all trials (with non-zeros) per time point
  %together, concatenation across time points.
  %Earlier implementation: all time points per trial (with non-zeros)
  %together.
  
  
%   for j = 1:(siz(1)/ntap)
%     fprintf('computing trial %d of %d\n',j,siz(1)/ntap);
%     dumfourier = input.fourierspctrm((1+(j-1)*ntap):(j*ntap),:,:,:);
%     sel        = find(~isnan(dumfourier(1,1,1,:)));
%     tmpfourier = zeros(ntap*length(sel), siz(2), siz(3));
%     tmptrialinfo = [input.trialinfo(j*ones(1,length(sel)),:) sel(:)];
%     for k = 1:length(sel)
%       tmpfourier((1+(k-1)*ntap):(k*ntap),:,:) = dumfourier(:,:,:,sel(k));
%       cumtapcnt = [cumtapcnt; ntap];
%       origtrl   = [origtrl;   j];
%     end
%     allfourier   = cat(1,allfourier,  tmpfourier);
%     alltrialinfo = cat(1,alltrialinfo,tmptrialinfo);
%   end
end

output           = input;
output.dimord    = 'rpttap_chan_freq';
output           = rmfield(output,'time');
if ~isempty(allpow), output.powspctrm = permute(allpow,[3 1 2]); end

if     hascrs && length(size(allcrs))==2, output.crsspctrm     = permute(allcrs,[2 3 1]);
elseif hascrs,                            output.crsspctrm     = permute(allcrs,[3 1 2]);
elseif hasfourier,
   output.fourierspctrm = allfourier;
   output.trialinfo     = alltrialinfo;
   output.cumtapcnt     = cumtapcnt;
end

output.origtrl = origtrl;

%FIXME cumtapcnt handling does not function appropriately
%if isfield(input,'tapsmofrq'),
%%if ~isfield(input,'cumtapcnt');
%    for j = 1:siz(3),
%      Nsmp            = input.cfg.t_ftimwin(j).*fsample;
%      Bwidth          = input.cfg.tapsmofrq(j)./fsample;
%      tap             = dpss(Nsmp,Nsmp*Bwidth)';
%      cumtapcnt(j)    = size(tap,1) - 1;
%    end
%%else
%%    cumtapcnt = freq.cumtapcnt;
%%end
%else 
%  for j = 1:siz(3)
%    cumtapcnt(j) = 1;
%  end
%end

%output.cumtapcnt = repmat(cumtapcnt(:)',[size(output.powspctrm,1) 1]);
