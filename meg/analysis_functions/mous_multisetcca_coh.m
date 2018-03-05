function [coh,cohall,data,Ti] = mous_multisetcca_coh(data,stim,n)

% account for nans in the data
for k = 1:numel(data.trial)
  data.trial{k}(~isfinite(data.trial{k}))=0;
end

if (nargin==1 || isempty(stim)) && ~isfield(data, 'stim_on_lagged001')
  stim        = addstimchan(data, 'vis', 0); % HARD CODED VISUAL!
  partchannel = {'stim_on_lagged001'};
  data        = ft_appenddata([],data,stim);
elseif (nargin==1 || isempty(stim)) && isfield(data, 'stim_on_lagged001')
  partchannel = {'stim_on_lagged001'};
elseif nargin>1
  data = ft_appenddata([],data,stim);
  partchannel = stim.label;  
end

if nargin>2
  computeTi = true;
else
  computeTi = false;
end

cfg         = [];
cfg.length  = 4;
cfg.overlap = 0.5;
data        = ft_redefinetrial(cfg,data);

cfg         = [];
cfg.method  = 'mtmfft';
cfg.output  = 'fourier';
cfg.tapsmofrq = 0.5;
cfg.foilim  = [0 20];
freq        = ft_freqanalysis(cfg, data);

cfg         = [];
cfg.method  = 'coh';
cfg.complex = 'complex';
cfg.channelcmb = ft_channelcombination(cat(2,repmat({'all'},[numel(partchannel) 1]),partchannel(:)), freq.label); 
coh         = ft_connectivityanalysis(cfg, freq);

cfg             = [];
cfg.method      = 'coh';
%cfg.partchannel = partchannel;
cohall          = ft_connectivityanalysis(cfg, ft_checkdata(freq, 'cmbrepresentation','fullfast'));

if computeTi
  cfg.method  = 'csd';
  cfg.complex = 'complex';
  csdall      = ft_connectivityanalysis(cfg, ft_checkdata(freq, 'cmbrepresentation','fullfast'));
  Ti = zeros(1,numel(csdall.freq));
  for k = 1:numel(csdall.freq)
    tmp = csdall.crsspctrm(:,:,k);
    Ti(k) = (abs(det(tmp(1:n(1),1:n(1)))).*abs(det(tmp(n(1)+(1:n(2)),n(1)+(1:n(2))))))./abs(det(tmp(1:sum(n),1:sum(n))));
  end
else
  Ti = [];
end

