function mous_bfica_grpstatistics(subjectnames,suffix,bslflag)

% oscband:  can reflect a oscillatory band: low/medium/high, or just one
% specific frequency e.g., 25.
% low: '25' '50' '75' '100' '150'};
% medium: '120' '160' '200' '240' '280' '320'};
% high = 400  440  480  520  560   600  640   680   720   760  800  840
% 880  920  960  1000;
  
rootdir = '/project/3011020.09/MEG/';
savedir = '/project/3011020.09/nielam/';
Nsubj   = numel(subjectnames);
% oscband needs to have an underscore if referring to _low, _medium, _high
% if just a single frequency band, then underscore is not necessary

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
cfg.numrandomization    = 600; %600 for 30 1200 for 68 subjs;  %2000 for 102 subjs
%  cfg.correcttail         = 'prob';
    
switch suffix.wordtype
  case {'sourcedatasentseq' , 'sourcedatasentseqtar'};
     if strcmp(subjectnames{1}(1),'A')     % auditory single subject data in nielam dir.
      [stat,Nsubj,avgsent,avgseq,semsent,semseq] = mous_bfica_sourcestatistics(subjectnames, suffix, bslflag, cfg, savedir);    %#ok<*ASGLU>
      save([savedir,'/groupresults/bfica/auditory/',suffix.wordtype,suffix.oscband,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgsent','avgseq','semsent','semseq','-v7.3');  
    
    elseif strcmp(subjectnames{1}(1),'V')  % visual single subject data in MEG dir (finalised)
      [stat,Nsubj,avgsent,avgseq,semsent,semseq] = mous_bfica_sourcestatistics(subjectnames, suffix, bslflag, cfg, rootdir); %
      save([savedir,'/groupresults/bfica/visual/',suffix.wordtype, suffix.oscband,'_',savebsl,'_',num2str(Nsubj),'subj',suffix.suff3],'stat','Nsubj','avgsent','avgseq','semsent','semseq','-v7.3');    
     end
    
   
  case {'sourcedatasentseqpar' , 'sourcedatasentseqpartar'}; 
    if regexp(suffix.wordtype,'tar')
      suffix  = {['sourcedatasentpartar',suffix.oscband] , ['sourcedataseqpartar',suffix.oscband]};   
    else
      suffix  = {['sourcedatasentpar',suffix.oscband] , ['sourcedataseqpar',suffix.oscband]};
    end 

    if strcmp(subjectnames{1}(1),'A')      
      [stat,Nsubj] = mous_bfica_sourcestatistics_seqsentpar(subjectnames, suffix, 1, cfg, savedir);
      save([savedir,'/groupresults/bfica/auditory/',suffsave,'_',savesuff,'_',suffix.wordtype,suffix.oscband,'_',num2str(Nsubj),'subj'],'stat','Nsubj','-v7.3');  
      
    elseif strcmp(subjectnames{1}(1),'V')     
      [stat,Nsubj] = mous_bfica_sourcestatistics_seqsentpar(subjectnames, suffix, 1, cfg,rootdir);
      save([savedir,'/groupresults/bfica/visual/',suffix.wordtype,suffix.oscband,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','-v7.3');    
    end

  case {'sourcedatasentvbsl' , 'sourcedataseqvbsl'}
     
    if strcmp(subjectnames{1}(1),'A')     
      [stat,Nsubj,avgsent,avgseq,semsent,semseq] = mous_bfica_sourcestatistics_cdtnvbsl(subjectnames, suffix, bslflag, cfg, savedir);   %
      save([savedir,'/groupresults/bfica/auditory/',suffix.wordtype,suffix.oscband,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgsent','avgseq','semsent','semseq','-v7.3');  
    
    elseif strcmp(subjectnames{1}(1),'V') 
      [stat,Nsubj,avgact,avgbslcdtn,semact,sembslcdtn] = mous_bfica_sourcestatistics_cdtnvbsl(subjectnames, suffix, bslflag, cfg, rootdir); %
      save([savedir,'/groupresults/bfica/visual/',suffix.wordtype, suffix.oscband,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgact','avgbslcdtn','semact','sembslcdtn','-v7.3');    
    end
    
  case {'sourcedatasentMXRC'}
    if strcmp(subjectnames{1}(1),'A')     
      [stat,Nsubj,avgrc,avgmix,semrc,semmix] = mous_bfica_sourcestatistics_MXRC(subjectnames, suffix, bslflag, cfg, savedir); %
      save([savedir,'/groupresults/bfica/visual/',suffix.wordtype, suffix.oscband,'_',savebsl,'_',num2str(Nsubj),'subj'],'stat','Nsubj','avgrc','avgmix','semrc','semmix','-v7.3');    
    
    elseif strcmp(subjectnames{1}(1),'V') 
      [stat,Nsubj,avgrc,avgmix,semrc,semmix] = mous_bfica_sourcestatistics_MXRC(subjectnames, suffix, bslflag, cfg, rootdir); %
      save([savedir,'/groupresults/bfica/visual/',suffix.wordtype, suffix.oscband,'_',savebsl,'_',num2str(Nsubj),'subj',suffix.suff3],'stat','Nsubj','avgrc','avgmix','semrc','semmix','-v7.3');    
    end
end
