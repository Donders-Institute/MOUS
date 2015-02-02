% This scripts allows user to toggle the options to calculate coherence
% between the MEG signal and the speech signal

% Speech signal options
% 1. speech envelope
% 2. phase  - not yet developed

tmp  = tokenize(foi,'');
suff = [num2str(tmp{1}(1)),'_',num2str(tmp{1}(2)),'Hz']; 

%% do sensor
%  Determine which frequencies have coherence
if dosens
  [sentcohAX, wlcohAX, sentcohPL, wlcohPL] = mous_neuralspeechcoherence(subjectname, foi);
  
  sentcoh = sencohAX;  wlcoh = whcohAX;
  mous_db_putdata(subjectname, ['meg_coh_sensor',suff,'_axial'],'sentcoh','wlcoh',rootdir);
  
  sentcoh = sencohPL;  wlcoh = whcohPL;
  mous_db_putdata(subjectname, ['meg_coh_sensor',suff,'_planar'],'sentcoh','wlcoh',rootdir);

end

%% do average at sensor level
if dosensavg
  nsubj     = num2str(numel(subjectnames));
  filename  = ['meg_coh_sensor',suff,'_planar'];
  cohgrpavg = mous_neuralspeechcoherence_grpavg(subjectnames, filename, rootdir);
  
  suff      = [suff,'_',nsubj,'subjs'];
  save(['/project/3011020.09/nielam/groupresults/coh/speechenvelope/sensordata_speechenvcoh_',suff],...
        'cohgrpavg','-v7.3');        
end
%% do source
% Call once for each frequency of interest
if dosource
  [x]   = mous_neuralspeechcoherence_sourcedata(subjectname,foi);
  mous_db_putdata(subjectname,['meg_coh_sourcedata',suff],'sentcoh','wlcoh',rootdir);  
end


