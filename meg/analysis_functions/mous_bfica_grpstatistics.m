function mous_bfica_grpstatistics(subjectnames,suffix,bslflag)

% suffix.wordtype: 
% suffix.parcel: 
% suffix.oscband:  can reflect a oscillatory band: low/medium/high, or just one
% specific frequency e.g., 25 for 2.5Hz
% suffix.selfreq: [min max] 
% if selfreq is specified, then specify if need averaging
% suffix.avg = 'yes' or 'no';
% suffix.toi: [min max]

  
rootdir = '/project/3011020.09/MEG/';
savedir = '/project/3011020.09/nielam/groupresults/bfica/';
Nsubj   = numel(subjectnames);
% osc = 'low','medium', 'high', or a specific number

if bslflag == 1
  savebsl = 'prewordbsl';
elseif bslflag == 2;
  savebsl = 'presenbsl';
elseif bslflag == 3;
  savebsl = 'zero';
end

% statistical test parameters 
cfg     = [];
cfg.correctm            = 'cluster';
%cfg.clusterthreshold = 'parametric_common'; % estimate threshold from the randomization distribution. The threshold is common to all channel-time-frequency points
cfg.clusterthreshold    = 'parametric';
cfg.clusteralpha        = 0.01;
cfg.numrandomization    = 2000; %600 for 30 1200 for 68 subjs;  %2000 for 102 subjs
%  cfg.correcttail         = 'prob';

% save folder (modality determined)
if strcmp(subjectnames{1}(1),'A')     % auditory single subject data in nielam dir.
 mod = 'auditory/';
elseif strcmp(subjectnames{1}(1),'V')
 mod = 'visual/';
else
  error('subject type is not visual or auditory');
end

% determine frequency choice, and update choice in savename
if isfield(suffix,'selfreq')
  if suffix.selfreq(1) == suffix.selfreq(2)
    suffixfreq = [num2str(suffix.selfreq(1)),'Hz'];
  elseif suffix.selfreq(1) ~= suffix.selfreq(2)
    suffixfreq = [num2str(suffix.selfreq(1)),'to',num2str(suffix.selfreq(2)),'Hz'];
  end
  if isfield(suffix,'avg') && strcmp(suffix.avg,'yes')
    suffixfreq = [suffixfreq,'avg'];
  else
    suffix.avg = 'no';
  end
end

if isfield(suffix,'toi')
  a = num2str(suffix.toi(1)); a = [a(1) a(3)];
  b = num2str(suffix.toi(2)); b = [b(1) b(3)];
  suffend = [a,b,'s'];
else
  suffend = '';
end
  
% earlylate
if ~isempty(strfind(suffix.sourcedata,'sourcedataearlylate'))
  tmp = suffix.sourcedata;
  if regexp(tmp,'low')
    suffix.wordtype = {'sourcedataearlylateRC_matched_low','sourcedataearlylateMX_matched_low'};
    
  elseif regexp(tmp,'medium')
    suffix.wordtype = {'sourcedataearlylateRC_matched_medium','sourcedataearlylateMX_matched_medium'};
    
  elseif regexp(tmp,'high')
    suffix.wordtype = {'sourcedataearlylateRC_matched_high','sourcedataearlylateMX_matched_high'};
  end
  
  [stattime statcomplex stattimecomp avgearlyRC avglateRC avgearlyMX avglateMX semearlyRC semlateRC semearlyMX semlateMX] = mous_bfica_sourcestatistics_timecomplexity(subjectnames, suffix, bslflag, cfg, rootdir);
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',suffixfreq,'_',suffend,'_',num2str(Nsubj),'subj'],'stattime','statcomplex','stattimecomp', 'avgearlyRC', 'avglateRC', 'avgearlyMX', 'avglateMX', 'semearlyRC', 'semlateRC', 'semearlyMX', 'semlateMX','-v7.3');

% sentseq / sentseqtar
elseif (~isempty(strfind(suffix.sourcedata,'sourcedatasentseq')) && isempty(regexp(suffix.sourcedata,'par'))) || (~isempty(strfind(suffix.sourcedata,'sourcedatasentseqtar')) && isempty(regexp(suffix.sourcedata,'par')))
  [stat,Nsubj,avgsent,avgseq,semsent,semseq] = mous_bfica_sourcestatistics(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',suffixfreq,'_',suffend,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgsent','avgseq','semsent','semseq','-v7.3');    

% parametric (word position)
elseif ~isempty(strfind(suffix.sourcedata,'sourcedatasentseqpar'))
  tmp = suffix.sourcedata;
  if isempty(strfind(suffix.sourcedata,'tar'))
    if regexp(tmp,'low')
      suffix.wordtype  = {'sourcedatasentpar_low' , 'sourcedataseqpar_low'};   
    elseif regexp(tmp,'medium')
      suffix.wordtype  = {'sourcedatasentpar_medium' , 'sourcedataseqpar_medium'};  
    elseif regexp(tmp,'high')
      suffix.wordtype  = {'sourcedatasentpar_high' , 'sourcedataseqpar_high'};  
    end
  elseif ~isempty(strfind(suffix.sourcedata,'tar'))
    if regexp(tmp,'low')
      suffix.wordtype  = {'sourcedatasentpartar_low' , 'sourcedataseqpartar_low'};   
    elseif regexp(tmp,'medium')
      suffix.wordtype  = {'sourcedatasentpartar_medium' , 'sourcedataseqpartar_medium'};  
    elseif regexp(tmp,'high')
      suffix.wordtype  = {'sourcedatasentpartar_high' , 'sourcedataseqpartar_high'};  
    end
  end

  [stat,Nsubj] = mous_bfica_sourcestatistics_seqsentpar(subjectnames, suffix, 1, cfg, rootdir);
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',suffixfreq,'_',suffend,'_',num2str(Nsubj),'subj'],'stat','Nsubj','-v7.3');  

% condition vs. bsl/zero  - use flag
elseif ~isempty(strfind(suffix.sourcedata,'sourcedatasentvbz')) || ~isempty(strfind(suffix.sourcedata,'sourcedataseqvbz'))
  if bslflag == 1
    bz = 'pre-word bsl';
  elseif bslflag == 2
    bz = 'pre-sent bsl';
  elseif bslflag == 3
    bz = 'zero';
  end
  warning('testing condition (sent or seq) against %s',bz)
  [stat,Nsubj,avgact,avgbslcdtn,semact,sembslcdtn] = mous_bfica_sourcestatistics_cdtnvbsl(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata(1:end-2),savebsl,'_',suffixfreq,'_',suffend,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgact','avgbslcdtn','semact','sembslcdtn','-v7.3');    

% sentences only RC vs MX.
elseif ~isempty(strfind(suffix.sourcedata,'sourcedatasentRCMX'))
  [stat,Nsubj,avgrc,avgmix,semrc,semmix] = mous_bfica_sourcestatistics_RCMX(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',suffixfreq,'_',suffend,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgrc','avgmix','semrc','semmix','-v7.3');    

else
  error('unrecognised datatype in suffix.sourcedata');

end
