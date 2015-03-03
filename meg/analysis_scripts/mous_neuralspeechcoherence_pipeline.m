mous_neuralspeechcoherence_pipelineoptions;

% This scripts allows user to toggle the options to calculate coherence
% between the MEG signal and the speech signal

% Speech signal options
% 1. speech envelope
% 2. phase  - not yet developed

if isnumeric(cohfoi)
  tmp  = tokenize(cohfoi,'');
  suff = [num2str(tmp{1}(1)),'-',num2str(tmp{1}(2)),'Hz']; 
  if exist('gamfoi','var') && isnumeric(gamfoi)
    tmp  = tokenize(gamfoi,'');
    suff = [suff,'_gamma',num2str(tmp{1}(1)),'-',num2str(tmp{1}(2)),'Hz'];
  end
end

%% compute sensor-level coherence for low frequencies
%  Determine which frequencies have coherence
 % hilbert transform shifts phase by 90
%  default hilbert transform parameters:
%  - butterworth filter (flat - no ripples at roll-off, but slow roll-off,
%  not sharp transition at cut off) 
%  - 4th order:  roll-off at -24dB; 
%              higher order = wider width, computing cost...
%  - 2way direction (forward and reverse)
%  - wdith of 1: width of transition band
%  - http://www.electronics-tutorials.ws/filter/filter_8.html
%  - use firws, is better than butterworth, but takes longer to compute

if dosens
  
  if exist('gamfoi','var')
    [sentcohAX, wlcohAX, sentcohPL, wlcohPL] = mous_neuralspeechcoherence_sensor(subjectname, cohfoi, gamfoi);
  else
    [sentcohAX, wlcohAX, sentcohPL, wlcohPL] = mous_neuralspeechcoherence_sensor(subjectname, cohfoi);
  end
  
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
  param              = 'cohspctrm';
  filename           = ['meg_coh_sensor_',suff,'_planar'];
  [cohgrpavg]        = mous_neuralspeechcoherence_grpavg(subjectnames, filename, param,'/project/3011020.09/MEG/');

  cohgrpavg = rmfield(cohgrpavg,'cfg'); % decrease memory
  suff      = [suff,'_',nsubj,'subjs'];
  save(['/project/3011020.09/nielam/groupresults/coh/speechenvelope/sensordata_coh_',suff],...
        'cohgrpavg');        
end
%% compute source-level data
% 
% First call to source-level computation requires preprocessing raw data,
% which will be subsequently used for all other frequencies of interest

% foi is a string for source-level data (for dosens, it is a number)
% Not every subject has a peak in each frequency range (delta, theta, alpha, beta)
% the frequency ranges in foi are determined prior to beginning
% source-level computations

if dosource
  [subjlist,~] = mous_db_getfilename('allA','subjectname');
  load('/home/language/nielam/MOUS_AnalysisNotes/Coherence/coherencePeakdetect_stage2_thres5_pd3');
  idx      = find(ismember(subjlist,subjectname));
  tmp      = peakfreqfirst(idx,1:4);
  foi      = cohfoi(~isnan(tmp));        % defined when calling pipeline
  tmp      = tmp(~isnan(tmp));

  [sentcoh, wlcoh, preprocdat]  = mous_neuralspeechcoherence_sourcedata(subjectname,foi{1});
  mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{1},'_thres5_pd3'],'sentcoh','wlcoh',rootdir,1);  
  
  if numel(foi) > 1
    for k = 2:numel(foi)
      [sentcoh, wlcoh]  = mous_neuralspeechcoherence_sourcedata(subjectname,foi{k},preprocdat);
      mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{k},'_thres5_pd3'],'sentcoh','wlcoh',rootdir,1);  
    end
  end
end

