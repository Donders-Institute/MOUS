dodss = false;
dofreq = false;
dofreqbaseline = false;
dosource = 0;
dosource8mm = 0;
dovox = 0;
dovoxbaseline = 0;
doica = 0;
doccc = 1;
dosourcedss = 0;
dosentvsseq = 0;
dowordsentpar = 0;
dowordseqpar = 0;
sourcedata2avgword = 0;

dowordsentpar2 = 0;
dowordseqpar2 = 0;

rootdir = '/home/language/jansch/public/mous/';

% use the variable suff and frequency to toggle between different frequency bands
suff      = '';
frequency = 20;

if dodss,
  [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname);
  mous_db_putdata(subjectname, 'meg_bfica_comp', 'comp', 'avgcomp', 'avgpre', rootdir);
end
if dofreq,
  % theta frequency
  options = [];
  options.taper = 'hanning';
  options.t_ftimwin = 0.4;
  options.resamplefs = 300;
  freq = mous_bfica_freq(subjectname, 5, rootdir, options);
  mous_db_putdata(subjectname, 'meg_bfica_freq5', 'freq', rootdir);
  
% % beta frequency
% options = [];
% options.taper = 'hanning';
% options.t_ftimwin = 0.250;
% options.resamplefs = 300;
% freq = mous_bfica_freq(subjectname, 20, rootdir);
% mous_db_putdata(subjectname, 'meg_bfica_freq', 'freq', rootdir);
%
% % broadband gamma frequency
% options = [];
% options.tapsmofrq = 30;
% options.taper = 'dpss';
% options.t_ftimwin = 0.1;
% options.resamplefs = 300;
% freq = mous_bfica_freq(subjectname, 70, rootdir, options);
% mous_db_putdata(subjectname, 'meg_bfica_freq70', 'freq', rootdir);
end
if dofreqbaseline,
  options.taper = 'dpss';
  options.tapsmofrq = 4;
  freq = mous_bfica_freqbaseline(subjectname, rootdir, options);
  mous_db_putdata(subjectname, 'meg_bfica_freqbaseline', 'freq', rootdir);
end
if dosource,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  [source, trialinfo] = mous_bfica_source(subjectname, freq);
  mous_db_putdata(subjectname, ['meg_bfica_source',suff], 'source', 'trialinfo', rootdir);
end
if dosource8mm,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  [source, trialinfo] = mous_bfica_source(subjectname, freq, 0.4, 8);
  mous_db_putdata(subjectname, ['meg_bfica_source8mm',suff], 'source', 'trialinfo', rootdir);
end
if dovox,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  sourcedata = mous_bfica_sourcedata(source, freq);%, toi);
  mous_db_putdata(subjectname, ['meg_bfica_sourcedata',suff], 'sourcedata', rootdir);
end
if dovoxbaseline,
  mous_db_getdata(subjectname, 'meg_bfica_freqbaseline', rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  sourcedata = mous_bfica_sourcedatabaseline(source, freq, frequency);
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatabaseline',suff], 'sourcedata', rootdir);
end
if dosentvsseq,
% toi = -0.2:0.05:0.8;
% sourcedata = mous_db_getdata(subjectname, 'meg_bfica_sourcedata', rootdir);
% source = mous_db_getdata(subjectname, 'meg_bfica_source', rootdir);
% krn = compute_kernel(source);
% [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
% sourcedata.trialinfo = trialinfo;
% sourcedata.trial = trial;
% sourcedata.time = time;
% [tlcksent, tlckseq] = mous_makecontrast(sourcedata, 'sent-seq');
% mous_db_putdata(subjectname, 'meg_bfica_sourcedatasentseq', tlcksent, tlckseq, rootdir);

  toi = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  %krn = compute_kernel(source);
  %[trial,time,trialinfonew] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  [trial,time,trialinfonew] = trial2words(sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  
  % match the trials with the trialinfo from the sourcedata file
  [c, ia, ib] = intersect(trialinfonew(:,1:2), trialinfo(:,[1 5]),'rows');
  % chop until word offset minus half a time window for the spectral analysis
  % FIXME
  
  sourcedata.trialinfo = trialinfonew(ia,:);
  sourcedata.trial = trial(ia);
  sourcedata.time = time(ia);
  [tlcksent, tlckseq] = mous_makecontrast(sourcedata, 'sent-seq');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatasentseq',suff], 'tlcksent', 'tlckseq', rootdir);

end

% if dowordsentpar,
% toi = -0.2:0.05:0.8;
% sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
% source = mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
% krn = compute_kernel(source);
% [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
% sourcedata.trialinfo = trialinfo;
% sourcedata.trial = trial;
% sourcedata.time = time;
% [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordsent_parametric');
% mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordsentpar',suff], 'tlck', 'stat', 'stat2', rootdir);
% end
% if dowordseqpar,
% toi = -0.2:0.05:0.8;
% sourcedata = mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
% source = mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
% krn = compute_kernel(source);
% [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
% sourcedata.trialinfo = trialinfo;
% sourcedata.trial = trial;
% sourcedata.time = time;
% [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordseq_parametric');
% mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordseqpar',suff], 'tlck', 'stat', 'stat2', rootdir);
% end
if dowordsentpar2,
  toi = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  krn = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo = trialinfo;
  sourcedata.trial = trial;
  sourcedata.time = time;
  sourcedata.fsample = 1;

  for k = 1:numel(sourcedata.trial)
    ix = nearest(sourcedata.time{k}, 0.3);
    iy = nearest(sourcedata.time{k}, 0.6);
    sourcedata.trial{k} = nanmean(sourcedata.trial{k}(:,ix:iy),2);
    sourcedata.time{k} = nanmean(sourcedata.time{k}(ix:iy),2);
  end
  
  [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordsent_parametric');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordsentpar2',suff], 'tlck', 'stat', 'stat2', rootdir);
end
if dowordseqpar2,
  toi = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  krn = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo = trialinfo;
  sourcedata.trial = trial;
  sourcedata.time = time;
  sourcedata.fsample = 1;

  for k = 1:numel(sourcedata.trial)
    ix = nearest(sourcedata.time{k}, 0.3);
    iy = nearest(sourcedata.time{k}, 0.6);
    sourcedata.trial{k} = nanmean(sourcedata.trial{k}(:,ix:iy),2);
    sourcedata.time{k} = nanmean(sourcedata.time{k}(ix:iy),2);
  end
 
  [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordseq_parametric');
  mous_db_putdata(subjectname, ['meg_bfica_sourcedatawordseqpar2',suff], 'tlck', 'stat', 'stat2', rootdir);
end

if sourcedata2avgword
  toi = -0.2:0.05:0.8;
  mous_db_getdata(subjectname, ['meg_bfica_sourcedata',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source',suff], rootdir);
  krn = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  for k = 1:numel(trial)
    sel = time{k}>=0;
    trial{k} = nanmean(trial{k}(:,sel),2);
    time{k} = nanmean(time{k}(sel),2);
  end
  sourcedata.trial = trial;
  sourcedata.time = time;
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
if doccc,
  mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);
  mous_db_getdata(subjectname, ['meg_bfica_source8mm',suff], rootdir);
  
  freq              = ft_selectdata(freq, 'toilim', [0.38 0.42]);
  [cohsent, cohseq] = mous_bfica_ccc(source, freq);
  mous_db_putdata(subjectname, ['meg_bfica_ccc',suff], 'cohsent', 'cohseq', rootdir);
end

  

%
% % do ica -> can this be done on single subject if sufficient data is
% % present?
% cfg = [];
% cfg.demean = 'no'; % do outside the function is possibly more memory efficient
% cfg.method = 'fastica';
% cfg.fastica.lastEig = 100;
% comp = ft_componentanalysis(cfg, sdata);


% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatasentseq',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  load('/home/language/jansch/matlab/fieldtrip/template/sourcemodel/standard_grid3d10mm');

   
  for k = 1:Nsubj
    %mous_db_getdata(subj{k}, ['meg_bfica_sourcedatabaseline',suff], rootdir);
    %sel = ismember(sourcedata.trialinfo(:,2), [2 6]); % 1 is sent, 0 is seq
    %Bsent = (mean(sourcedata.trial{1}(:,sel),2));
    %Bseq = (mean(sourcedata.trial{1}(:,~sel),2));
    
    clear tlcksent tlckseq
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatasentseq',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = tlckseq.time;
    source = rmfield(source, 'freq');
    %source.avg.pow = tlckseq.avg;
    source.avg.pow = log10(tlckseq.avg);% ./ repmat(Bseq, [1 numel(tlckseq.time)]);
    
    seq{k} = source;
    %source.avg.pow = tlcksent.avg;
    source.avg.pow = log10(tlcksent.avg);% ./ repmat(Bsent, [1 numel(tlcksent.time)]);
    
    sent{k} = source;
  end
  
  for k = 1:Nsubj
    globalpow = mean(seq{k}.avg.pow(:)+sent{k}.avg.pow(:))./2;
    seq{k}.avg.pow = seq{k}.avg.pow - globalpow;
    sent{k}.avg.pow = sent{k}.avg.pow - globalpow;
    seq{k}.pos = grid.pos;
    sent{k}.pos = grid.pos;
  end
  
  % the pow is only defined on the insides, ft_sourcestatistics expects all
  % voxels
  for k = 1:Nsubj
    tmp1 = zeros(prod(seq{k}.dim),numel(seq{k}.time));
    tmp1(seq{k}.inside,:) = seq{k}.avg.pow;
    tmp2 = zeros(prod(sent{k}.dim),numel(sent{k}.time));
    tmp2(sent{k}.inside,:) = sent{k}.avg.pow;
    
    seq{k}.avg.pow = (tmp1);% - repmat(mean((tmp1),1), [size(tmp1,1) 1]);
    sent{k}.avg.pow = (tmp2);% - repmat(mean((tmp2),1), [size(tmp1,1) 1]);
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  senttime = sent;
  seqtime = seq;
% for k = 1:Nsubj
% senttime{k}.avg.pow = senttime{k}.avg.pow - repmat(mean(senttime{k}.avg.pow(:,4:11),2),[1 20]);
% seqtime{k}.avg.pow = seqtime{k}.avg.pow - repmat(mean(seqtime{k}.avg.pow(:,4:11),2),[1 20]);
% end
  stattime = ft_sourcestatistics(cfg, senttime{:}, seqtime{:});
  
  
  ix = nearest(sent{1}.time, 0.3);
  iy = nearest(sent{1}.time, 0.6);
  for k = 1:numel(sent)
    sent{k}.avg.pow = nanmean(sent{k}.avg.pow(:,ix:iy),2);
    seq{k}.avg.pow = nanmean(seq{k}.avg.pow(:,ix:iy),2);
    sent{k}.time = nanmean(sent{k}.time(ix:iy));
    seq{k}.time = nanmean(seq{k}.time(ix:iy));
    
    globalpow = nanmean(sent{k}.avg.pow(sent{k}.inside)+seq{k}.avg.pow(seq{k}.inside))./2;
    sent{k}.avg.pow = sent{k}.avg.pow - globalpow;
    seq{k}.avg.pow = seq{k}.avg.pow - globalpow;
    %sent{k}.avg.pow = sent{k}.avg.pow - nanmean(sent{k}.avg.pow(sent{k}.inside));
    %seq{k}.avg.pow = seq{k}.avg.pow - nanmean(seq{k}.avg.pow(seq{k}.inside));
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 2000;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  cfg.clusteralpha = 0.005;
  stat = ft_sourcestatistics(cfg, sent{:}, seq{:});
  if ndims(stat.stat)>2
    stat.stat=stat.stat(:);
    stat.prob=stat.prob(:);
    stat.mask=stat.mask(:);
  end
  i1 = mous_bfica_sourceinterpolate(stat, 'stat', stat.inside);
  iprob = mous_bfica_sourceinterpolate(stat, 'prob', stat.inside);
  imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);
  i1.coordsys = 'spm';
  i1.mask = imask.avg.pow;
  i1.prob = iprob.avg.pow;
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordsentpar',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordsentpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
    
    wordavg(1:size(tlck.trial,1),:,:,k) = tlck.trial;
    
  end
  data2 = data;
  for k = 1:numel(data)
    %data2{k}.avg.pow(data2{k}.inside,:) = ones(numel(data2{k}.inside),1)*nanmean(data2{k}.avg.pow);
    data2{k}.avg.pow(data2{k}.inside,:) = 0;
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'no';%'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  i1 = mous_bfica_sourceinterpolate(stat, 'stat');
  
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordseqpar',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordseqpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
  end
  data2 = data;
  for k = 1:numel(data)
    %data2{k}.avg.pow(data2{k}.inside,:) = ones(numel(data2{k}.inside),1)*nanmean(data2{k}.avg.pow);
    data2{k}.avg.pow(data2{k}.inside,:) = 0;
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 0;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'no';%'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  i1 = mous_bfica_sourceinterpolate(stat, 'stat');
  
end

% group statistics
if 0
  rootdir = '/home/language/jansch/public/mous';
  subj = mous_db_getfilename('all', 'subjectname');
  [f,s] = mous_db_getfilename(subj, ['meg_bfica_sourcedatawordseqpar',suff], 0, rootdir);
  subj = subj(s);
  Nsubj = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordseqpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
  
    %wordavg(1:size(tlck.trial,1),:,:,k) = tlck.trial;
  end
  data2 = data;
  %wordavgseq = wordavg;
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, ['meg_bfica_sourcedatawordsentpar',suff], rootdir);
    mous_db_getdata(subj{k}, ['meg_bfica_source',suff], rootdir);
    
    source.time = stat.time;
    source = rmfield(source, 'freq');
    source.avg.pow(1, numel(stat.time)) = nan;
    source.avg.pow(source.inside,:) = stat.stat;
    data{k} = source;
    data{k}.pos = data{1}.pos;
  
    %wordavg(1:size(tlck.trial,1),:,:,k) = tlck.trial;
  end
  %wordavgsent = wordavg;
  clear wordavg;
  
  for k = 1:Nsubj
    data{k}.avg.pow = mean(data{k}.avg.pow(:,10:16),2); %300 to 600
    data2{k}.avg.pow = mean(data2{k}.avg.pow(:,10:16),2);
    data{k}.time = 0.45;
    data2{k}.time = 0.45;
  end
  
  cfg = [];
  cfg.method = 'montecarlo';
  cfg.statistic = 'depsamplesT';
  cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
  cfg.ivar = 1;
  cfg.uvar = 2;
  cfg.numrandomization = 2000;
  cfg.parameter = 'avg.pow';
  cfg.correctm = 'cluster';
  cfg.clusterthreshold = 'nonparametric_common';
  cfg.clusteralpha = 0.01;
  stat = ft_sourcestatistics(cfg, data{:}, data2{:});
  if ndims(stat.stat)>2
    stat.stat=stat.stat(:);
    stat.prob=stat.prob(:);
    stat.mask=stat.mask(:);
  end
  i1 = mous_bfica_sourceinterpolate(stat, 'stat', stat.inside);
  iprob = mous_bfica_sourceinterpolate(stat, 'prob', stat.inside);
  imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);
  i1.coordsys = 'spm';
  i1.mask = imask.avg.pow;
  i1.prob = iprob.avg.pow;
end

