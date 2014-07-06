function mous_bfica_grpstatistics(subjectnames,suffix,bslflag)

% suffix.wordtype: 
% suffix.parcel: 
% suffix.oscband:  can reflect a oscillatory band: low/medium/high, or just one
% specific frequency e.g., 25.
% low: '25' '50' '75' '100' '150'};
% medium: '120' '160' '200' '240' '280' '320'};
% high = 400  440  480  520  560   600  640   680   720   760  800  840
% 880  920  960  1000;
  
rootdir = '/project/3011020.09/MEG/';
savedir = '/project/3011020.09/nielam/groupresults/bfica/'
Nsubj   = numel(subjectnames);
% osc = 'low','medium', 'high', or a specific number

if bslflag == 1
  savebsl = 'prewordbsl';
elseif bslflag == 2;
  savebsl = 'presenbsl';
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
else
 mod = 'visual/';
end
  
% earlylate
if regexp(suffix.sourcedata,'sourcedatasentearlylate');
  [statErcLrc statEmxLmx statErcEmx statLrcLmx avgearlyRC avglateRC avgearlyMX avglateMX semearlyRC semlateRC semearlyMX semlateMX] = mous_bfica_sourcestatistics_earlylate(subjectnames, suffix, bslflag, cfg, rootdir);
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',num2str(Nsubj),'subj'],'statErcLrc', 'statEmxLmx', 'statErcEmx', 'statLrcLmx', 'avgearlyRC', 'avglateRC', 'avgearlyMX', 'avglateMX', 'semearlyRC', 'semlateRC', 'semearlyMX', 'semlateMX','-v7.3');

% sentseq / sentseqtar
elseif regexp(suffix.sourcedata,'sourcedatasentseq') 
  [stat,Nsubj,avgsent,avgseq,semsent,semseq] = mous_bfica_sourcestatistics(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgsent','avgseq','semsent','semseq','-v7.3');    

% parametric (word position)
elseif regexp(suffix.sourcedata,'sourcedatasentseqpar');
  tmp = suffix.sourcedata;
  if regexp(tmp,'low')
    suffix.wordtype  = {'sourcedatasentpartar_low_bslabsolute' , 'sourcedataseqpartar_low_bslabsolute'};   
  elseif regexp(tmp,'medium')
    suffix.wordtype  = {'sourcedatasentpartar_medium_bslabsolute' , 'sourcedataseqpartar_medium_bslabsolute'};  
  elseif regexp(tmp,'high')
    suffix.wordtype  = {'sourcedatasentpartar_high_bslabsolute' , 'sourcedataseqpartar_high_bslabsolute'};  
  end

  [stat,Nsubj] = mous_bfica_sourcestatistics_seqsentpar(subjectnames, suffix, 1, cfg, savedir);
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','-v7.3');  

% condition vs. bsl
elseif regexp(suffix.sourcedata,'sourcedatasentvbsl') || regexp(suffix.sourcedata,'sourcedataseqvbsl')      
  [stat,Nsubj,avgact,avgbslcdtn,semact,sembslcdtn] = mous_bfica_sourcestatistics_cdtnvbsl(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgact','avgbslcdtn','semact','sembslcdtn','-v7.3');    

% sentences only RC vs MX.
elseif regexp(suffix.sourcedata,'sourcedatasentRCMX')
  [stat,Nsubj,avgrc,avgmix,semrc,semmix] = mous_bfica_sourcestatistics_RCMX(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgrc','avgmix','semrc','semmix','-v7.3');    

else
  error('unrecognised datatype in suffix.sourcedata');

end
