
dodss    = false;
dofreq   = false;
dosource = true;
dovox    = false;
doica    = false;
dosourcedss = false;
dosentvsseq = false;
dowordsentpar = false;
sourcedata2avgword = false;

rootdir  = '/home/language/jansch/public/mous/';

if dodss,
  [comp, avgpre, avgcomp] = mous_bfica_dss(subjectname);
  mous_db_putdata(subjectname, 'meg_bfica_comp', 'comp', 'avgcomp', 'avgpre', rootdir);
end

%toi = 0.375;
%toi = 0.5;
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
%   options.resamplefs = 300;
%   freq   = mous_bfica_freq(subjectname, 70, rootdir, options);
%   mous_db_putdata(subjectname, 'meg_bfica_freq70', 'freq', rootdir);
end
if dosource,
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
end

if dovox,
  % theta frequency
  %freq   = mous_db_getdata(subjectname, 'meg_bfica_freq5');
  %source = mous_db_getdata(subjectname, ['meg_bfica_source5_',num2str(round(toi*1000)),'']);
  %sourcedata = mous_bfica_sourcedata(source, freq, toi);
  %mous_db_putdata(subjectname, ['meg_bfica_sourcedata5_',num2str(round(toi*1000)),''], sourcedata);
  
%   freq   = mous_db_getdata(subjectname, 'meg_bfica_freq', rootdir);
%   source = mous_db_getdata(subjectname, 'meg_bfica_source', rootdir);
%   sourcedata = mous_bfica_sourcedata(source, freq);%, toi);
%   mous_db_putdata(subjectname, 'meg_bfica_sourcedata', sourcedata, rootdir);
%   
  % broadband gamma frequency
  freq   = mous_db_getdata(subjectname, 'meg_bfica_freq70', rootdir);
  source = mous_db_getdata(subjectname, 'meg_bfica_source70', rootdir);
  sourcedata = mous_bfica_sourcedata(source, freq);%, toi);
  mous_db_putdata(subjectname, 'meg_bfica_sourcedata70', 'sourcedata', rootdir);
  
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

  % broadband gamma frequency
  toi        = -0.2:0.05:0.8;
  sourcedata = mous_db_getdata(subjectname, 'meg_bfica_sourcedata70', rootdir);
  source     = mous_db_getdata(subjectname, 'meg_bfica_source70', rootdir);
  krn        = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo = trialinfo;
  sourcedata.trial     = trial;
  sourcedata.time      = time;
  [tlcksent, tlckseq] = mous_makecontrast(sourcedata, 'sent-seq');
  mous_db_putdata(subjectname, 'meg_bfica_sourcedatasentseq70', 'tlcksent', 'tlckseq', rootdir);

end  
if dowordsentpar,
  toi        = -0.2:0.05:0.8;
  sourcedata = mous_db_getdata(subjectname, 'meg_bfica_sourcedata', rootdir);
  source     = mous_db_getdata(subjectname, 'meg_bfica_source', rootdir);
  krn        = compute_kernel(source);
  [trial,time,trialinfo] = trial2words(krn'*sourcedata.trial{1},sourcedata.trialinfo(:,[1 5 7 2:4 6]),toi);
  sourcedata.trialinfo = trialinfo;
  sourcedata.trial     = trial;
  sourcedata.time      = time;
  [tlck,stat,stat2] = mous_makecontrast(sourcedata, 'wordsent_parametric');
  mous_db_putdata(subjectname, 'meg_bfica_sourcedatawordsentpar', 'tlck', 'stat', 'stat2', rootdir);
end
if sourcedata2avgword
  toi        = -0.2:0.05:0.8;
  sourcedata = mous_db_getdata(subjectname, 'meg_bfica_sourcedata', rootdir);
  source     = mous_db_getdata(subjectname, 'meg_bfica_source', rootdir);
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
  mous_db_putdata(subjectname, 'meg_bfica_sourcedataavgword', 'sourcedata', rootdir);
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
  [f,s]   = mous_db_getfilename(subj, 'meg_bfica_sourcedatasentseq', 0, rootdir);
  subj    = subj(s);
  Nsubj   = numel(subj);
  
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_bfica_sourcedatasentseq', rootdir);
    mous_db_getdata(subj{k}, 'meg_bfica_source', rootdir);
    
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
  stat = ft_sourcestatistics(cfg, sent{:}, seq{:});
  
end
