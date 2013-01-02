
dodss    = false;
dofreq   = false;
dosource = true;
dovox    = false;
doica    = false;
dosourcedss = false;
dosentvsseq = false;
dowordsentpar = true;
dowordseqpar  = true;
sourcedata2avgword = false;

rootdir  = '/home/language/jansch/public/mous/';

% use the variable suff and frequency to toggle between different frequency bands
suff      = '';'5';
frequency = 20;%5;

if dodss,
  [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname);
  mous_db_putdata(subjectname, 'meg_bfica_comp', 'comp', 'avgcomp', 'avgpre', rootdir);
end
if dofreq,
  % theta frequency

  %freq   = mous_bfica_freq(subjectname, 5);
  %mous_db_putdata(subjectname, 'meg_bfica_freq5', freq);
  
  % beta frequency
  freq   = mous_bfica_freq(subjectname, 20);
  mous_db_putdata(subjectname, 'meg_bfica_freq', 'freq', rootdir);
  
  % broadband gamma frequency
%   options.tapsmofrq = 30;
%   options.t_ftimwin = 0.1;

  options            = [];
  options.taper      = 'hanning';
  options.t_ftimwin  = 0.4;
  options.resamplefs = 300;
  freq   = mous_bfica_freq(subjectname, 5, rootdir, options);
  mous_db_putdata(subjectname, 'meg_bfica_freq5', 'freq', rootdir);
  
%  % beta frequency
%   options            = [];
%   options.taper      = 'hanning';
%   options.t_ftimwin  = 0.250;
%   options.resamplefs = 300;
%   freq   = mous_bfica_freq(subjectname, 20, rootdir);
%   mous_db_putdata(subjectname, 'meg_bfica_freq', 'freq', rootdir);
%   
%   % broadband gamma frequency
%   options            = [];
%   options.tapsmofrq  = 30;
%   options.taper      = 'dpss';
%   options.t_ftimwin  = 0.1;
>>>>>>> d728b288f28e8835fbb328ed2982e60cd248505f
%   options.resamplefs = 300;
%   freq   = mous_bfica_freq(subjectname, 70, rootdir, options);
%   mous_db_putdata(subjectname, 'meg_bfica_freq70', 'freq', rootdir);
end
if dosource,
<<<<<<< HEAD
  % theta frequency
  %freq   = mous_db_getdata(subjectname, 'meg_bfica_freq5');
  %source = mous_bfica_source(subjectname, freq, toi);
  %mous_db_putdata(subjectname, ['meg_bfica_source5_',num2str(round(toi*1000)),''], source);
  
  freq   = mous_db_getdata(subjectname, 'meg_bfica_freq', rootdir);
  source = mous_bfica_source(subjectname, freq);
  %mous_db_putdata(subjectname, ['meg_bfica_source',num2str(round(toi*1000)),''], source);
  mous_db_putdata(subjectname, 'meg_bfica_source', source, rootdir);
  
  % broadband gamma frequency
%   freq   = mous_db_getdata(subjectname, 'meg_bfica_freq70', rootdir);
%   source = mous_bfica_source(subjectname, freq);
%   mous_db_putdata(subjectname, 'meg_bfica_source70', 'source', rootdir);
%   
=======
  freq   = mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  source = mous_bfica_source(subjectname, freq);
  mous_db_putdata(subjectname, ['meg_bfica_source',suff], 'source', rootdir);  
>>>>>>> d728b288f28e8835fbb328ed2982e60cd248505f
end
if dovox,
  freq   = mous_db_getdata(subjectname, ['meg_bfica_freq',suff],   rootdir);
  source = mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  sourcedata = mous_bfica_sourcedata(source, freq);%, toi);
  mous_db_putdata(subjectname, ['meg_bfica_sourcedata',suff], 'sourcedata', rootdir);
end
if dosentvsseq,
%   toi        = -0.2:0.05:0.8;
%   sourcedata = mous_db_getdata(subjectname, 'meg_bfica_sourcedata', rootdir);
%   source     = mous_db_getdata(subjectname, 'meg_bfica_source', rootdir);
%   krn        = compute_kernel(source);
%   [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
%   sourcedata.trialinfo = trialinfo;
%   sourcedata.trial     = trial;
%   sourcedata.time      = time;
%   [tlcksent, tlckseq] = mous_makecontrast(sourcedata, 'sent-seq');
%   mous_db_putdata(subjectname, 'meg_bfica_sourcedatasentseq', tlcksent, tlckseq, rootdir);

  toi        = -0.2:0.05:0.8;
  sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  source     = mous_db_getdata(subjectname, ['meg_bfica_source',suff],     rootdir);
  krn        = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo = trialinfo;
  sourcedata.trial     = trial;
  sourcedata.time      = time;
  [tlcksent, tlckseq] = mous_makecontrast(sourcedata, 'sent-seq');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatasentseq',suff], 'tlcksent', 'tlckseq', rootdir);

end  

if dowordsentpar,
  toi        = -0.2:0.05:0.8;
  sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  source     = mous_db_getdata(subjectname, ['meg_bfica_source',suff],     rootdir);
  krn        = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo = trialinfo;
  sourcedata.trial     = trial;
  sourcedata.time      = time;
  [tlck,stat,stat2]    = mous_makecontrast(sourcedata, 'wordsent_parametric');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordsentpar',suff], 'tlck', 'stat', 'stat2', rootdir);
end
if dowordseqpar,
  toi        = -0.2:0.05:0.8;
  sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  source     = mous_db_getdata(subjectname, ['meg_bfica_source',suff],     rootdir);
  krn        = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo = trialinfo;
  sourcedata.trial     = trial;
  sourcedata.time      = time;
  [tlck,stat,stat2]    = mous_makecontrast(sourcedata, 'wordseq_parametric');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordseqpar',suff], 'tlck', 'stat', 'stat2', rootdir);
end

if sourcedata2avgword
  toi        = -0.2:0.05:0.8;
  sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  source     = mous_db_getdata(subjectname, ['meg_bfica_source',suff],     rootdir);
  krn        = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  for k = 1:numel(trial)
    sel      = time{k}>=0;
    trial{k} = nanmean(trial{k}(:,sel),2);
    time{k}  = nanmean(time{k}(sel),2);
  end
  sourcedata.trial = trial;
  sourcedata.time  = time;
  sourcedata.trialinfo = trialinfo;
  mous_db_putdata(subjectname, ['meg_bfica_sourcedataavgword',suff], 'sourcedata', rootdir);
end
if doica,
  comp = mous_bfica_ica(subjectname, [], rootdir);
  mous_db_putdata(subjectname, 'meg_bfica_ica', 'comp', rootdir);
end
if dosourcedss,
  comp = mous_bfica_sourcedatadss(subjectname, rootdir);
  mous_db_putdata(subjectname, 'meg_bfica_sourcedatadss', 'comp', rootdir);
end

% 
% % do ica -> can this be done on single subject if sufficient data is
% % present?
% cfg = [];
% cfg.demean       = 'no'; % do outside the function is possibly more memory efficient
% cfg.method       = 'fastica';
% cfg.fastica.lastEig = 100;
% comp = ft_componentanalysis(cfg, sdata);


% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj    = mous_db_getfilename('all', 'subjectname');
  [f,s]   = mous_db_getfilename(subj, ['meg_bfica_sourcedatasentseq',suff], 0, rootdir);
  subj    = subj(s);
  Nsubj   = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatasentseq',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff],            rootdir);
    
    source.time = tlckseq.time;
    source      = rmfield(source, 'freq');
    source.avg.pow = tlckseq.avg;
    seq{k}      = source;
    source.avg.pow = tlcksent.avg;
    sent{k}     = source;
  end
  
  for k = 1:numel(subj)
    seq{k}.avg.pow  = seq{k}.avg.pow  - mean(seq{k}.avg.pow(:));
    sent{k}.avg.pow = sent{k}.avg.pow - mean(sent{k}.avg.pow(:));
    seq{k}.pos = seq{1}.pos;
    sent{k}.pos = sent{1}.pos;
  end
  
  % the pow is only defined on the insides, ft_sourcestatistics expects all
  % voxels
  for k = 1:numel(subj)
    tmp = zeros(prod(seq{k}.dim),numel(seq{k}.time));
    tmp(seq{k}.inside,:) = seq{k}.avg.pow;
    seq{k}.avg.pow = tmp;
    
    tmp = zeros(prod(sent{k}.dim),numel(sent{k}.time));
    tmp(sent{k}.inside,:) = sent{k}.avg.pow;
    sent{k}.avg.pow = tmp;
  end
  
  cfg           = [];
  cfg.method    = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar      = 1;
  cfg.uvar      = 2;
  cfg.numrandomization = 500;
  cfg.parameter = 'avg.pow';
  cfg.correctm  = 'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, sent{:}, seq{:});
  i1   = mous_bfica_sourceinterpolate(stat, 'stat');
  iprob = mous_bfica_sourceinterpolate(stat, 'prob');
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj    = mous_db_getfilename('all', 'subjectname');
  [f,s]   = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordsentpar',suff], 0, rootdir);
  subj    = subj(s);
  Nsubj   = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordsentpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff],            rootdir);
    
    source.time = stat.time;
    source      = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:)     = stat.stat;
    data{k}      = source;
    data{k}.pos  = data{1}.pos;
  end
  data2 = data;
  for k = 1:numel(data)
    %data2{k}.avg.pow(data2{k}.inside,:) = ones(numel(data2{k}.inside),1)*nanmean(data2{k}.avg.pow);
    data2{k}.avg.pow(data2{k}.inside,:) = 0;
  end
  
  cfg           = [];
  cfg.method    = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar      = 1;
  cfg.uvar      = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  cfg.correctm  = 'no';%'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  i1   = mous_bfica_sourceinterpolate(stat, 'stat');
  
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj    = mous_db_getfilename('all', 'subjectname');
  [f,s]   = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordseqpar',suff], 0, rootdir);
  subj    = subj(s);
  Nsubj   = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordseqpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff],            rootdir);
    
    source.time = stat.time;
    source      = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:)     = stat.stat;
    data{k}      = source;
    data{k}.pos  = data{1}.pos;
  end
  data2 = data;
  for k = 1:numel(data)
    %data2{k}.avg.pow(data2{k}.inside,:) = ones(numel(data2{k}.inside),1)*nanmean(data2{k}.avg.pow);
    data2{k}.avg.pow(data2{k}.inside,:) = 0;
  end
  
  cfg           = [];
  cfg.method    = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar      = 1;
  cfg.uvar      = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  cfg.correctm  = 'no';%'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  i1   = mous_bfica_sourceinterpolate(stat, 'stat');
  
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj    = mous_db_getfilename('all', 'subjectname');
  [f,s]   = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordseqpar',suff], 0, rootdir);
  subj    = subj(s);
  Nsubj   = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordseqpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff],            rootdir);
    
    source.time = stat.time;
    source      = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:)     = stat.stat;
    data{k}      = source;
    data{k}.pos  = data{1}.pos;
  end
  data2 = data;
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordsentpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff],            rootdir);
    
    source.time = stat.time;
    source      = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:)     = stat.stat;
    data{k}      = source;
    data{k}.pos  = data{1}.pos;
  end
  
  cfg           = [];
  cfg.method    = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design    = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar      = 1;
  cfg.uvar      = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  cfg.correctm  = 'no';%'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  i1   = mous_bfica_sourceinterpolate(stat, 'stat');
  
end
