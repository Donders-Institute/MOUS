function [peakfreqfirst,peakfreqsecond,cohallsubj] = mous_neuralspeechcoherence_peakdetect(condition, thres)
%  This function searches for peaks in each channel
%  frequencies with peaks in each channel are contender peaks
%  the contender peak that is (1) found in >25 channels, has (2) highest peak value
%  is the peak frequency for that subject

%  Decisions taken for this peak detection algorithm
%  1. Number of channels: using all channels 
%     Although we don't expect peaks in occipital sensors, but mostly
%     around temporal, lower frontal, and parietal sensors, the precise
%     sensors that best capture the topography of coherence varies in each
%     subject. More objective to use all sensors, and set a higher
%     threshold on the number of sensors required to have a peak in a
%     particular frequency, to consider that frequency to have a true peak.
%  2. Threshold at which a coherence peak is considered
%     0.1 is the heuristic used.  Upon inspecting several ~15 subjects, the
%     peak is between 0.1 to 0.22, and can vary depending on the subject
%     specific SnR
%  3. Rounds of detection: 2
%     The first round gives a rough idea of which peaks to consider
      %  E.g., there are peaks right next to each other(in frequency) 
      %  with almost equal height, which could actually be one true peak.
%     The second round creates well defined peaks:
      % Take the smoothed coherence spectrum and multiply 
      % it to the mean of the standardized coherence spectrum
      % standardization: places all frequencies on the same coherence
      % level, making the lower frequency peaks (with high coherence values)
      % more prominent.
      % ft_preproc_standardize
        % standardize data to have zero mean, unit SD
        % value at each frequency is on same scale -> amplifies peaks

      % ft_preproc_smoothhead
        % smooths out peaks. In some cases there are frequencies side by side with
        % prominent peaks which are smoothed into one.



%% first round of peak detection (rough)
if ischar(condition)
  % Nietzsche's original implementation
  subj = mous_db_getfilename('allA','subjectname');
else
  subj = {condition};
end
allfreq = 0.5:0.5:30;
numpeak = zeros(numel(subj),numel(allfreq)); % subj x frequencies

for k = 1:numel(subj)
  
  if ischar(condition)
    mous_db_getdata(subj{k},'meg_coh_sensor_0-30Hz_axial','/project/3011020.09/MEG/');
  
    switch condition
      case 'wl'
        sentcoh = wlcoh;
      case 'common' head
        sentcoh.cohspctrm = (sentcoh.cohspctrm+wlcoh.cohspctrm)/2;
    end
  else
    sentcoh = subj{k};
  end
  
  cfg = [];
  cfg.frequency = [allfreq(1) allfreq(end)];
  sentcoh       = ft_selectdata(cfg,sentcoh);
  coi           = 1:size(sentcoh.labelcmb,1);

  % allocate memory
  numchan  = size(sentcoh.cohspctrm,1);
  peak     = zeros(numchan,12); % assume not more than 12 peaks detected per channel
  val      = zeros(numchan,12); % keep count which frequencies have peaks in a binary matrix (1 = peak)
  fcohpeak = zeros(numchan,numel(allfreq)); % binary matrix to record pre/absence of peak

  % Difficult to determine subject specific threshold
  % using heuristic of 0.1; option to not set a threshold. 
  if nargin<2
    thres    = 0.02;
  end

  for chancnt = 1:numchan
    % [p,v]  = peakdetect2NL(sentcoh.cohspctrm(coi(chancnt),:),thres);  % peak index in data>thres & value of peak   
    [p,v]  = peakdetect2(sentcoh.cohspctrm(coi(chancnt),:),thres);  % peak index in data>thres & value of peak   
    
    tmp    = allfreq(p);   % determine frequency from peak value

    if ~isempty(p)              
      fcohpeak(chancnt,:) = ismember(allfreq,tmp);
    end

    if ~isempty(p)         % store all peaks and values
      len = numel(p);
      peak(chancnt,1:len) = p;
      val(chancnt,1:len)  = v;
    end
  end                      % channel loop
  numpeak(k,:)            = sum(fcohpeak,1); % numpeak = number of channels with a peak at a certain frequency
end                        % subjloop

dosave = 0;
if dosave,
  switch condition
    case 'wl'
      save('/project/3011020.09/nielam/groupresults/coh/speechenvelope/coherencePeakdetect_stage1_thres001wl','numpeak');
    case 'sent'
      save('/project/3011020.09/nielam/groupresults/coh/speechenvelope/coherencePeakdetect_stage1_thres001sent','numpeak');
    case 'common' 
      save('/project/3011020.09/nielam/groupresults/coh/speechenvelope/coherencePeakdetect_stage1_thres001common','numpeak');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% standardize and smooth at the single-subject level, then do a second round of peak detection
%  after first round, the peaks are still not that clear

%[subj,s]       = mous_db_getfilename('allA','subjectname');
%allfreq           = 0.5:0.5:30;
peakallsubj    = zeros(numel(subj),numel(allfreq)); % exclude 0 Hz
cohallsubj     = zeros(numel(subj),numel(allfreq));
for k = 1:numel(subj)
  
%   mous_db_getdata(subj{k},'meg_coh_sensor_0-30Hz_axial','/project/3011020.09/MEG/');
% 
%   switch condition  % default is using sentences only
%   case 'wl'
%     sentcoh = wlcoh;
%   case 'common' 
%     sentcoh.cohspctrm = (sentcoh.cohspctrm+wlcoh.cohspctrm)/2;
%   end
  
  cfg = [];
  cfg.frequency = [allfreq(1) allfreq(end)];
  sentcoh       = ft_selectdata(cfg,sentcoh);
  coi           = 1:size(sentcoh.labelcmb,1);
  
  % standardize matrix
  % mean across channels
  % multiple standardized (mean) by peaks
  sentcoh.cohspctrm = ft_preproc_smooth(numpeak(k,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)),1); 
  cohallsubj(k,:)   = sentcoh.cohspctrm; % smoothed and standardized data from all subjs
  
  thres  = 2;     % standardzation means part of signal is below 2. 
                  % the 10 subjs without peaks is because (i) too few
                  % channels with theta peak (ii) threshold is stringent;
                  % when lowered to -2 7 out of these 10 subjs will have a
                  % peak (But this also means more peak in alpha /beta band
                  % that are noise)

  %[p,v]  = peakdetect3NL(sentcoh.cohspctrm,thres); % p = peak index, v = value of peak
  [p,v]  = peakdetect3(sentcoh.cohspctrm,thres); % p = peak index, v = value of peak
  tmp    = sentcoh.freq(p); % determine frequency from peak value
  if ~isempty(p)            % keep count which frequencies have peaks in a binary matrix (1 = peak)
    peakallsubj(k,:) = ismember(sentcoh.freq,tmp);
  end
    
end      % subj loop

%% determine peaks after 2nd round
%  Subjects with a peak within the prescribed frequency ranges, log peak
%  i.e. not every has a peak in each frequency range
%  H1: specific spatial topography for each frequency range; 
%      including subjs w/o peak may dilute topography
% delta 0   - 3.5  (0.5 - 3)
% theta 3.5 - 7.5  (4   - 7)
% alpha 7.5 - 12.5 (8   - 12)
% beta  13  - 30   (13  - 30)
% gamma 31  - 100

allfreq = 0.5:0.5:30;
peakfreqfirst  = nan(numel(subj),4); % matrix to store subject specific peak for each frequency range
peakfreqsecond = nan(numel(subj),4); % use 'nan', can differentiate between subjs with no peaks vs. peak at sentcoh.freq(1) i.e. 0 Hz
delta   = 1:6;    % indices of sentcoh.freq
theta   = 8:14;
alpha   = 16:24;
beta    = 26:60;


for sc = 1:numel(subj)
  for fb = 1:4
    % assign frequency range 
      if fb == 1
        frange = delta;
      elseif fb == 2
        frange = theta;
      elseif fb == 3
        frange = alpha;
      elseif fb == 4
        frange = beta;
      end

      % If peak is present in frequency range, assign it to freqrange
      % 1. max peak in one matrix
      % 2. record subjs with >1 max peak.  
      idx = find(peakallsubj(sc,frange));  % get data in foi
      [v,i] = sort(idx,'descend');
      if ~isempty(idx)
        peakfreqfirst(sc,fb) = allfreq(frange(idx(1)));

        if numel(idx) > 1              % data with >1 max peak:
          [v,i] = sort(idx,'descend'); % i(2) is always second largest peak (assuming >2 peaks found)
          peakfreqsecond(sc,fb) = allfreq(frange(idx(2)));

        end
      end
  end
end

% if no peak found, change '0' to 'NaN'
% otherwise, connectivity calculated for subjects with '0' (doesn't make sense)
% Subjects with 0 in commonpeak usually have a peak in each condition but
%   the average cancels out the peak
idx = find(peakfreqfirst == 0);
peakfreqfirst(idx) = nan;

if dosave,
  switch condition
    case 'wl'
      save('/project/3011020.09/nielam/groupresults/coh/speechenvelope/coherencePeakdetect_stage2_thres001_smoothing_wl','peakfreqfirst','peakfreqsecond','cohallsubj');
    case 'sent'
      save('/project/3011020.09/nielam/groupresults/coh/speechenvelope/coherencePeakdetect_stage2_thres001_smoothing_sent','peakfreqfirst','peakfreqsecond','cohallsubj');
    case 'common'
      save('/project/3011020.09/nielam/groupresults/coh/speechenvelope/coherencePeakdetect_stage2_thres001_smoothing_common','peakfreqfirst','peakfreqsecond','cohallsubj');
  end
end
