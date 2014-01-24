function [stat] = mous_beamformer_dics(freq, sourcemodel, headmodel, design)

if nargin<4
  design = [];
end

% prepare leadfield
cfg         = [];
cfg.grid    = sourcemodel;
cfg.vol     = headmodel;
cfg.grad    = freq.grad;
cfg.channel = 'MEG';
sourcemodel = ft_prepare_leadfield(cfg);

% compute sourcelevel sentence versus sequence contrast

% prepare the cfgs
cfg        = [];
cfg.method = 'dics';
cfg.grid   = sourcemodel;
cfg.vol    = headmodel;
cfg.keepleadfield   = 'yes';
cfg.dics.keepfilter = 'yes';
cfg.dics.fixedori   = 'yes';
cfg.dics.realfilter = 'yes';
cfg.dics.lambda     = '5%';

cfg2        = [];
cfg2.method = 'pcc';
cfg2.grid   = sourcemodel;
cfg2.vol    = headmodel;
cfg2.pcc.keepmom = 'yes';

cfg3           = [];
cfg3.method    = 'montecarlo';
cfg3.numrandomization = 0;
cfg3.parameter = 'pow';
cfg3.statistic = 'indepsamplesT';
%cfg3.design    = zeros(1, size(freq.trialinfo,1));

for k = 1:numel(freq.freq)
  cfg.frequency  = freq.freq(k);
  cfg2.frequency = freq.freq(k);

  freqy  = ft_selectdata(freq, 'foilim', cfg.frequency*[1 1]);
  freqx  = ft_checkdata(freqy, 'cmbrepresentation', 'fullfast');
  freqx.labelcmb = ft_channelcombination({'all' 'all'},freqx.label);
  freqx.powspctrm = abs(diag(freqx.crsspctrm));
  freqx.crsspctrm = tril(freqx.crsspctrm,-1);
  freqx.crsspctrm = freqx.crsspctrm(freqx.crsspctrm~=0);
  freqx.dimord    = 'chancmb_freq';
  source = ft_sourceanalysis(cfg, freqx);

  cfg2.grid.filter    = source.avg.filter;
  cfg2.grid.leadfield = source.leadfield;
  for m = 1:numel(sourcemodel.inside)
    indx = sourcemodel.inside(m);
    cfg2.grid.leadfield{indx} = cfg2.grid.leadfield{indx}(:,1);
    % this is an ugly fix to let sourceanalysis run in the next step, it
    % doesn't matter what you put in, as long as it's a one-column lf
  end

  source = ft_sourceanalysis(cfg2, freqy);

  % compute power
  % this is not standard fieldtripcode
  nrpt = numel(freq.cumtapcnt);
  nvox = numel(source.inside);
  proj = zeros(sum(freq.cumtapcnt), nrpt);
  ctap = 0;
  for m = 1:size(proj,2)
    ntap = freq.cumtapcnt(m);
    proj(ctap+(1:ntap), m) = 1./ntap;
    ctap = ctap+ntap;
  end

  pow = zeros(nvox, nrpt);
  for m = 1:nvox
    indx = source.inside(m);
    mom  = source.avg.mom{indx};
    pow(m,:) = (abs(mom).^2)*proj;
  end

  trial = [];
  for m = 1:nrpt
    trial(m).pow = zeros(prod(source.dim),1);
    trial(m).pow(source.inside) = pow(:,m);
  end

  sourcenew        = source;
  sourcenew.trial  = trial;
  sourcenew.method = 'rawtrial';
  sourcenew        = rmfield(sourcenew, 'avg');
  source           = sourcenew;
  clear sourcenew trial;


  % compute t-stat
  if isempty(design)
    T      = source.trialinfo(:,2);
    sel1   = find(T==1 | T==2 | T==5 | T==6);
    sel2   = find(T==3 | T==4 | T==7 | T==8);
    design = zeros(1,size(T,1));  
    design(sel1) = 1;
    design(sel2) = 2;
  elseif size(design,2)~=size(source.trialinfo,1)
    error('size of design does not correspond with the data');
  end    

  cfg3.design       = design;
  stat(k) = ft_sourcestatistics(cfg3, source);
end

