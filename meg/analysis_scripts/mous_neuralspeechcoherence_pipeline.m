mous_neuralspeechcoherence_pipelineoptions;

% This scripts allows user to toggle the options to calculate coherence
% between the MEG signal and the speech signal

% Speech signal options
% 1. speech envelope
% 2. phase  - not yet developed

tmp  = tokenize(foi,'');
suff = [num2str(tmp{1}(1)),'-',num2str(tmp{1}(2)),'Hz']; 

%% compute sensor-level coherence
%  Determine which frequencies have coherence
if dosens
  [sentcohAX, wlcohAX, sentcohPL, wlcohPL] = mous_neuralspeechcoherence(subjectname, foi);
  
  sentcoh = sentcohAX;  wlcoh = wlcohAX;
  mous_db_putdata(subjectname, ['meg_coh_sensor_',suff,'_axial'],'sentcoh','wlcoh',rootdir);
  
  sentcoh = sentcohPL;  wlcoh = wlcohPL;
  mous_db_putdata(subjectname, ['meg_coh_sensor_',suff,'_planar'],'sentcoh','wlcoh',rootdir);

end

%% average across subjects (sensor level)
% N.B. 55 subjects have an additional sensor, 274, instead of 273 
% fix ft_appendfreq to deal with labelcmb instead of label
if dosensavg
  [subjectnames, ~ ] = mous_db_getfilename('allA','subjectname');
  nsubj              = num2str(numel(subjectnames));
  filename           = ['meg_coh_sensor_',suff,'_planar'];
  [cohgrpavg]        = mous_neuralspeechcoherence_grpavg(subjectnames, filename, rootdir);

  cohgrpavg = rmfield(cohgrpavg,'cfg'); % decrease memory
  suff      = [suff,'_',nsubj,'subjs'];
  save(['/project/3011020.09/nielam/groupresults/coh/speechenvelope/sensordata_coh_',suff],...
        'cohgrpavg');        
end
%% compute source-level data
% Call once for each frequency of interest
if dosource
  [x]   = mous_neuralspeechcoherence_sourcedata(subjectname,foi);
  mous_db_putdata(subjectname,['meg_coh_sourcedata',suff],'sentcoh','wlcoh',rootdir);  
end


