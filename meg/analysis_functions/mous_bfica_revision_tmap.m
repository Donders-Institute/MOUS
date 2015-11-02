function [stat,stat250,stat350,stat450] = mous_bfica_revision_tmap(contrast, frequency, baseflg)

if nargin<3,
  baseflg = 0;
end

subj = mous_db_getfilename('all','subjectname');
load standard_sourcemodel3d8mm;
tmp     = ft_convert_units(sourcemodel,'mm');
tmp.pow = zeros(11000,15);

dat1 = cell(numel(subj),1);
dat2 = cell(numel(subj),1);
cond = tokenize(contrast, '-');
for k = 1:numel(subj)
  mous_db_getdata(subj{k}, ['meg_bfica_revision_erfanalysis',num2str(frequency),'Hz']); 
  tmp.time = output.time;
  tmp.dimord = 'pos_time';
  
  tmp.pow(tmp.inside,:) = getsubfield(output, cond{1});
  if baseflg,
    tmp.pow = tmp.pow - repmat(tmp.pow(:,1),[1 size(tmp.pow,2)]);
  end
  dat1{k} = tmp;
  tmp.pow(tmp.inside,:) = getsubfield(output, cond{2});
  if baseflg,
    tmp.pow = tmp.pow - repmat(tmp.pow(:,1),[1 size(tmp.pow,2)]);
  end
  dat2{k} = tmp;
end

n = numel(dat1);

cfg           = [];
cfg.method    = 'montecarlo';
cfg.statistic = 'depsamplesT';
cfg.design    = [ones(1,n) ones(1,n)*2;1:n 1:n];
cfg.numrandomization = 0;
cfg.parameter = 'pow';
cfg.ivar = 1;
cfg.uvar = 2;

stat = ft_sourcestatistics(cfg, dat1{:}, dat2{:});
stat.cfg = rmfield(stat.cfg, 'previous');
cfg.latency = [0.24 0.26];
cfg.numrandomization = 1000;
cfg.correctm = 'cluster';
cfg.clusterthreshold = 'nonparametric_individual';
cfg.clusteralpha = 0.01;
stat250 = ft_sourcestatistics(cfg, dat1{:}, dat2{:});
stat250.cfg = rmfield(stat250.cfg, 'previous');

cfg.latency = [0.34 0.36];
stat350 = ft_sourcestatistics(cfg, dat1{:}, dat2{:});
stat350.cfg = rmfield(stat350.cfg, 'previous');

cfg.latency = [0.44 0.46];
stat450 = ft_sourcestatistics(cfg, dat1{:}, dat2{:});
stat450.cfg = rmfield(stat450.cfg, 'previous');



