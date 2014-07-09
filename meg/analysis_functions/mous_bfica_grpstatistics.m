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
savedir = '/project/3011020.09/nielam/groupresults/bfica/';
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
elseif strcmp(subjectnames{1}(1),'V')
 mod = 'visual/';
else
  error('subject type is not visual or auditory');
end

% determine frequency choice, and place in savename
  if isfield(suffix,'selfreq')
    if suffix.selfreq(1) == suffix.selfreq(2)
      suffixfreq = [num2str(suffix.selfreq(1)),'Hz'];
    elseif suffix.selfreq(1) ~= suffix.selfreq(2)
      suffixfreq = [num2str(suffix.selfreq(1)),'to',num2str(suffix.selfreq(2)),'Hz'];
        if strcmp(suffix.avg,'yes')
          suffixfreq = [suffixfreq,'avg'];
        end
    end
  end
  if isfield(suffix,'toi')
    a = num2str(suffix.toi(1)); a = [a(1) a(3)];
    b = num2str(suffix.toi(2)); b = [b(1) b(3)];
    suffend = [a,b,'s'];
  end
  
% earlylate
if ~isempty(strfind(suffix.sourcedata,'sourcedataearlylate'))
  tmp = suffix.sourcedata;
  if regexp(tmp,'low')
    suffix.wordtype = {'sourcedataearlylateRC_low_bslabsolute','sourcedataearlylateMX_low_bslabsolute'};
    
  elseif regexp(tmp,'medium')
    suffix.wordtype = {'sourcedataearlylateRC_medium_bslabsolute','sourcedataearlylateMX_medium_bslabsolute'};
    
  elseif regexp(tmp,'high')
    suffix.wordtype = {'sourcedataearlylateRC_high_bslabsolute','sourcedataearlylateMX_high_bslabsolute'};
  end
  
  [stattime statcomplex stattimecomp avgearlyRC avglateRC avgearlyMX avglateMX semearlyRC semlateRC semearlyMX semlateMX] = mous_bfica_sourcestatistics_earlylate(subjectnames, suffix, bslflag, cfg, rootdir);
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

% condition vs. bsl
elseif ~isempty(strfind(suffix.sourcedata,'sourcedatasentvbsl')) || ~isempty(strfind(suffix.sourcedata,'sourcedataseqvbsl'))
  [stat,Nsubj,avgact,avgbslcdtn,semact,sembslcdtn] = mous_bfica_sourcestatistics_cdtnvbsl(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',suffixfreq,'_',suffend,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgact','avgbslcdtn','semact','sembslcdtn','-v7.3');    

% sentences only RC vs MX.
elseif ~isempty(strfind(suffix.sourcedata,'sourcedatasentRCMX'))
  [stat,Nsubj,avgrc,avgmix,semrc,semmix] = mous_bfica_sourcestatistics_RCMX(subjectnames, suffix, bslflag, cfg, rootdir); %
  save([savedir,mod,suffix.sourcedata,'_',savebsl,'_',suffixfreq,'_',suffend,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgrc','avgmix','semrc','semmix','-v7.3');    

else
  error('unrecognised datatype in suffix.sourcedata');

end
