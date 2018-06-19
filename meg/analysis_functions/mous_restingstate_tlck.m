function [tlck, data] = mous_restingstate_tlck(data, options)

if nargin<2
  options = [];
else
end
length    = ft_getopt(options, 'length',    2);
overlap   = ft_getopt(options, 'overlap', 0.5);

if isfield(options, 'comp') && isfield(options, 'avgcomp')
  comp = options.comp;
  
  % reject cardiac components
  v = var(options.avgcomp,[],2);
  v = v./v(1);
  
  % dummy trial to fool ft_rejectcomponent
  comp.time  = data.time;
  comp.trial = cellrowselect(data.trial,1:numel(comp.label));
  
  % NOTE: this avoids a crash later on, but not sure which grad structure is
  % used in ft_rejectcomponent.
  comp = rmfield(comp, 'grad');
  
  cfg           = [];
  cfg.component = find(v>0.1);
  data          = ft_rejectcomponent(cfg, comp, data);
end

% redefine
cfg         = [];
cfg.length  = length;
cfg.overlap = overlap;
data = ft_redefinetrial(cfg, data);

for k = 1:numel(data.trial)
  data.trial{k} = ft_preproc_baselinecorrect(data.trial{k});
end

hpfreq = 1;
for k = 1:numel(data.trial)
  data.trial{k} = ft_preproc_highpassfilter(data.trial{k}, data.fsample, hpfreq);
end

data.time(1:end) = data.time(1);

% select the middle part
n          = numel(data.time{1})./4;
cfg        = [];
cfg.toilim = data.time{1}([n+1 3*n]);
data       = ft_redefinetrial(cfg, data);

% remove line noise
Fline = 50:50:400;
Fline(Fline>data.fsample/2) = [];
for k = 1:numel(data.trial)
  data.trial{k} = ft_preproc_dftfilter(data.trial{k}, data.fsample, Fline); 
end

% covariance computation
cfg            = [];
cfg.covariance = 'yes';
cfg.preproc.demean = 'yes';
tlck           = ft_timelockanalysis(cfg, data);