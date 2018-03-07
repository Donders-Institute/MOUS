function [coh, cohavg, cohavgp] = mous_multisetcca_parcelconnectivity(data1, data2)


if isstruct(data1) && isstruct(data2)
  % nothing to be done
else
  if isscalar(data1)
    data1 = fullfile('/project/3011020.09/jansch/mscca_group', sprintf('mscca_sce1_parcel%0.3d',data1));
  end
  if isscalar(data2)
    data2 = fullfile('/project/3011020.09/jansch/mscca_group', sprintf('mscca_sce1_parcel%0.3d',data2));
  end
  if ischar(data1)
    load(data1, 'comp');
    data1 = comp;
  end
  if ischar(data2)
    load(data2, 'comp');
    data2 = comp;
  end
  if ~ischar(data2) && numel(data2)==2
    % this indicates the averaging scheme
    n = data2;
    clear data2;
  else
    n = [];
  end
end

if exist('data1', 'var') && exist('data2', 'var')
  [~,ix1] = sort(data1.trialinfo(:,1));
  [~,ix2] = sort(data2.trialinfo(:,1));
  data1.trial = data1.trial(ix1);
  data2.trial = data2.trial(ix2);
  data1.time  = data1.time(ix1);
  data2.time  = data2.time(ix2);
  data1.trialinfo = data1.trialinfo(ix1);
  data2.trialinfo = data2.trialinfo(ix2);
  
  T = data1.trialinfo;
  data = ft_appenddata([], data1, data2);
  data.trialinfo = T;
else
  data = data1;
end

if isempty(match_str(data.label, {'stim_on_lagged001'}))
  stim = addstimchan(data, 'vis', 0); % HARD CODED VISUAL!
  data = ft_appenddata([],data,stim);
end

cfg         = [];
cfg.length  = 4;
cfg.overlap = 0.5;
data        = ft_redefinetrial(cfg,data);

for k = 1:numel(data.trial)
  data.trial{k}(~isfinite(data.trial{k})) = 0;
end


cfg         = [];
cfg.method  = 'mtmfft';
cfg.output  = 'fourier';
cfg.tapsmofrq = 0.5;
cfg.foilim  = [0 20];
freq        = ft_freqanalysis(cfg, data);

cfg          = [];
cfg.method   = 'csd';
%cfg.bandwidth = 1;
cfg.complex  = 'complex';
coh          = ft_connectivityanalysis(cfg, ft_checkdata(freq, 'cmbrepresentation','fullfast'));

if ~isempty(n)
  
%   cfg.partchannel = freq.label(1:n(1));
%   cohp1 = ft_connectivityanalysis(cfg, ft_checkdata(freq, 'cmbrepresentation', 'fullfast'));
%   cfg.partchannel = freq.label(n(1)+(1:n(2)));
%   cohp2 = ft_connectivityanalysis(cfg, ft_checkdata(freq, 'cmbrepresentation', 'fullfast'));
%   
  fourierspctrm(:,1,:) = mean(freq.fourierspctrm(:,1:n(1),:),2);
  fourierspctrm(:,2,:) = mean(freq.fourierspctrm(:,n(1)+(1:n(2)),:),2);
  fourierspctrm(:,3,:) = freq.fourierspctrm(:,end,:);
  freq.fourierspctrm = fourierspctrm;
  freq.label         = {'vis';'aud';'stim'};
  
  cfg = rmfield(cfg, 'partchannel');
  cohavg = ft_connectivityanalysis(cfg, ft_checkdata(freq, 'cmbrepresentation', 'fullfast'));
  cfg.partchannel = freq.label(3);
  cohavgp = ft_connectivityanalysis(cfg, ft_checkdata(freq, 'cmbrepresentation', 'fullfast'));
  
else
  cohavg = [];
  cohavgp = [];
%   cohp1 = [];
%   cohp2 = [];
end

  
  