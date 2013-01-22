function [comp, avgcomp, avgpre, avgeog] = mous_artifact_eog_dss_blinks(filename, trl)


cfg1            = [];
cfg1.continuous = 'yes';
cfg1.dataset    = filename;
cfg1.channel    = 'MEG';
cfg1.demean     = 'yes';

cfg2            = cfg1;
cfg2.channel    = {'EEG058'};
cfg2.boxcar     = 0.2;
cfg2.bpfilter   = 'yes';
cfg2.bpfreq     = [1 10];
cfg2.bpfiltord  = 2;
cfg2.rectify    = 'yes';
cfg2.trl        = trl;

cfg3            = [];
cfg3.demean     = 'yes';
cfg3.detrend    = 'no';
cfg3.resamplefs = 600;

% read in and normalise eog data
eog             = ft_channelnormalise([], ft_preprocessing(cfg2));

% compute peak times for eog
clear p
newtrl = zeros(0,3);
for k = 1:numel(eog.trial)
  p = peakdetect2(eog.trial{k}(1,:),0.5,120);
  if ~isempty(p)
    for kk = 1:numel(p)
      if p(kk)>0.1*1200 && p(kk)<size(eog.trial{k},2)-0.1*1200
        newtrl(end+1,1) = trl(k, 1) + max(p(kk) - 300, 0);
        newtrl(end,  2) = trl(k, 1) + min(p(kk) + 599, size(eog.trial{k},2)-1);
        newtrl(end,  3) = -300;
      end
    end
  end
end

cfg1.trl = newtrl;
cfg2.trl = newtrl;
cfg2.rectify = 'no';
cfg2         = rmfield(cfg2, 'boxcar');

data   = ft_resampledata(cfg3, ft_preprocessing(cfg1));
eognew = ft_resampledata(cfg3, ft_preprocessing(cfg2));
eognew = ft_checkdata(eognew, 'hassampleinfo', 'yes');
for k = 1:numel(eognew.trial)
  offset(k,1) = nearest(eognew.time{k}, 0);
end

% do componentanalysis for eye blinks
addpath /home/language/jansch/matlab/toolboxes/dss_1-0
params.tr       = eognew.sampleinfo(:,1)+offset(:);
params.tr_begin = eognew.sampleinfo(:,1);
params.tr_end   = eognew.sampleinfo(:,2);
params.demean   = 1;
s.X             = 1;
params.computenew = 0;
[~,~,avgpre]    = denoise_avg2(params,cat(2,data.trial{:}),s);
[~,~,avgeog]    = denoise_avg2(params,cat(2,eognew.trial{:}),s);
params.computenew = 1;

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avg2';
cfg.dss.denf.params   = params;
cfg.channel           = 'MEG';
cfg.numcomponent      = 16;
comp                  = ft_componentanalysis(cfg, data);
params.computenew     = 0;
[~,~,avgcomp]         = denoise_avg2(params,cat(2,comp.trial{:}),s);
comp                  = rmfield(comp, 'trial');
