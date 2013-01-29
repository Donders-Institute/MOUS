function [comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss(filename, trl)

if size(trl,1)>50
  div = linspace(0,size(trl,1),ceil(size(trl,1)./50));
else
  div = [0 size(trl,1)];
end

cfg1            = [];
cfg1.continuous = 'yes';
cfg1.dataset    = filename;
cfg1.channel    = 'MEG';

cfg2 = cfg1;
cfg2.channel    = {'EEG057'};
cfg2.boxcar     = 0.2;
cfg2.bpfilter   = 'yes';
cfg2.bpfreq     = [1 10];
cfg2.bpfiltord  = 2;
cfg2.rectify    = 'yes';

% resample for memory reasons: think about whether this is OK
cfg3            = [];
cfg3.detrend    = 'no';
cfg3.demean     = 'yes';
cfg3.resamplefs = 200;


for k = 1:numel(div)-1
  cfg1.trl = trl((div(k)+1):div(k+1),:);
  cfg2.trl = cfg1.trl;
  
  data{k} = ft_resampledata(cfg3, ft_preprocessing(cfg1));
  eog{k}  = ft_resampledata(cfg3, ft_preprocessing(cfg2));
end
data = ft_appenddata([],data{:});
eog  = ft_appenddata([], eog{:});


% post process eog data
eog  = ft_channelnormalise([], eog);

% compute peak times for eog
clear p
for k = 1:numel(eog.trial)
  p{k} = peakdetect2(eog.trial{k}(1,:),4,20);
end

% convert to linear array
nsmp = cellfun('size', eog.trial, 2);
[p,begsmp,endsmp] = peaks2continuous(p, nsmp, 70, 150);
fprintf('detected %d blinks\n', numel(p));

% do componentanalysis for eye blinks
addpath /home/language/jansch/matlab/toolboxes/dss_1-0
params.tr = p(:);
params.tr_begin = begsmp(:);
params.tr_end   = endsmp(:);
s.X             = 1;
params.computenew = 0;
[~,~,avgpre]    = denoise_avgJM(params,cat(2,data.trial{:}),s);
[~,~,avgeog]    = denoise_avgJM(params,cat(2,eog.trial{:}),s);
params.computenew = 1;

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avgJM';
cfg.dss.denf.params   = params;
cfg.channel           = 'MEG';
cfg.numcomponent      = 16;
comp                  = ft_componentanalysis(cfg, data);
params.computenew     = 0;
[~,~,avgcomp]         = denoise_avgJM(params,cat(2,comp.trial{:}),s);
comp                  = rmfield(comp, 'trial');
