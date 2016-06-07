function [peakfreqfirst, peakfreqsecond] = mous_restingstate_peakdetect(duration)
%  This function searches for peaks across all MEG channels, and selects the
%  peak that occurs most often across channels while accounting for the
%  variance in coherence strenght across frequencies.
%  duration is a string variable: '2','3' or '4';

%  Decisions taken for this peak detection algorithm
%  1. Number of channels: using all channels 
%     Mainly expect peaks in temporal regions, together with contributions
%     from nearby frontal and parietal sensors.
%     But, since topography of coherence varies between subjects (as
%     visualised earlier), it is more objective to use all sensors, and set a higher
%     threshold on the number of sensors required to have a peak in a
%     particular frequency, to consider that frequency to have a true peak.
%  2. 2 rounds of peak detection
%     The first round gives a rough idea of which peaks to consider
      %  E.g., there are peaks right next to each other(in frequency) 
      %  with almost equal height, which could actually be one true peak.
%     The second round creates well defined peaks:
      % Take the smoothed spectrum and multiply 
      % it to the mean of the standardized spectrum
      % standardization: places all frequencies on the same coherence
      % level, making the lower frequency peaks (with high coherence values)
      % more prominent.
      % ft_preproc_standardize
        % standardize data to have zero mean, unit SD
        % value at each frequency is on same scale -> amplifies peaks

      % ft_preproc_smooth
        % smooths out peaks. In some cases there are frequencies side by side with
        % prominent peaks which are smoothed into one.


[subj,s] = mous_db_getfilename('allA','subjectname');
if strcmp(duration,'4')
    allfreq = 1:0.25:7;
elseif strcmp(duration,'3')
    allfreq = 3:0.33:7; 
elseif strcmp(duration,'2')
    allfreq = 3.5:0.5:7.5; 
end
    
numpeak = zeros(numel(subj),numel(allfreq)); % subj x frequencies

%% first round of peak detection (rough)

for k = 1:numel(subj)
  if strcmp(duration,'4') && strcmp(subj{k},'A2049')
      continue;
  end
      
  mous_db_getdata(subj{k},['meg_restingstate_pow_',duration,'s'],'/project/3011020.09/nielam/')     
  cfg = [];
  cfg.frequency = [allfreq(1) allfreq(end)];
  freq          = ft_selectdata(cfg,freq);
  coi           = 1:size(freq.label,1); % not all subjs have 273 channels

  % allocate memory
  numchan  = size(freq.powspctrm,1);
  peak     = zeros(numchan,12); % assume not more than 12 peaks detected per channel
  val      = zeros(numchan,12); % keep count which frequencies have peaks in a binary matrix (1 = peak)
  fpeak    = zeros(numchan,numel(allfreq)); % binary matrix to record pre/absence of peak

  % Difficult to determine subject specific threshold
  % using heuristic of 0.1; option to not set a threshold. 
  thres    = 0;

  for chancnt = 1:numchan
    [p,v]  = peakdetect3NL(freq.powspctrm(coi(chancnt),:),thres);  % peak index in data>thres & value of peak   
    tmp    = allfreq(p);   % determine frequency from peak value

    if ~isempty(p)              
      fpeak(chancnt,:) = ismember(allfreq,tmp);
    end

    if ~isempty(p)         % store all peaks and values
      len = numel(p);
      peak(chancnt,1:len) = p;
      val(chancnt,1:len)  = v;
    end
  end                      % channel loop
  numpeak(k,:)            = sum(fpeak,1); % numpeak = number of channels with a peak at a certain frequency
end                        % subjloop

save(['/project/3011020.09/nielam/groupresults/rs/powspctrm_',duration,'s_peakdetect_stage1_allchan_1to7.5'],'numpeak');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% standardize and smooth at the single-subject level, then do a second round of peak detection
%  after first round, the peaks are still not that clear

[subj,s]       = mous_db_getfilename('allA','subjectname');
peakallsubj    = zeros(numel(subj),numel(allfreq)); % exclude 0 Hz
freqallsubj     = zeros(numel(subj),numel(allfreq));
for k = 1:numel(subj)
  if strcmp(duration,'4') && strcmp(subj{k},'A2049')
      continue;
  end
  mous_db_getdata(subj{k},['meg_restingstate_pow_',duration,'s'],'/project/3011020.09/nielam/')

  cfg = [];
  cfg.frequency = [allfreq(1) allfreq(end)];
  freq          = ft_selectdata(cfg,freq);
  coi           = 1:size(freq.label,1); % not all subjs have 273 channels
  
  % standardize matrix
  % mean across channels
  % multiple standardized (mean) by peaks
  freq.powspctrm     = ft_preproc_smooth(numpeak(k,:).*mean(ft_preproc_standardize(freq.powspctrm)),1); 
  freqallsubj(k,:)   = freq.powspctrm; % smoothed and standardized data from all subjs
  
  thres  = 2;     % if set too low, then more peaks (very small ones) are detected than necessary
  [p,v]  = peakdetect3NL(freq.powspctrm,thres); % p = peak index, v = value of peak
  if numel(p) > 1
      
  end
  tmp    = freq.freq(p); % determine frequency from peak value
  if ~isempty(p)            % keep count which frequencies have peaks in a binary matrix (1 = peak)
    peakallsubj(k,:) = ismember(freq.freq,tmp);
  end
end      % subj loop

%% determine peaks after 2nd round
%  Subjects with a peak within the prescribed frequency ranges, log peak
%  i.e. not every subj has a peak in each frequency range
%  including subjs w/o peak may dilute topography
theta = 1:numel(freq.freq);
% use NANs so that if the subsequent stage requires connectivity
% calculations that subjects with no-peaks do not enter the calculation
peakfreqfirst  = nan(102,1); % matrix to store subject specific peak for each frequency range
peakfreqsecond = nan(102,1); % use 'nan', can differentiate between subjs with no peaks vs. peak at sentcoh.freq(1) i.e. 0 Hz

for subjcnt = 1:numel(subj)
  if strcmp(duration,'4') && strcmp(subj{k},'A2049')
      continue;
  end
    % If peak is present in frequency range, assign it to freqrange
    % 1. max peak in one matrix
    % 2. record subjs with >1 max peak.  
    idx = find(peakallsubj(subjcnt,theta));  % get data in foi
    [v,i] = sort(idx,'descend');
    if ~isempty(idx)
        peakfreqfirst(subjcnt) = allfreq(theta(idx(1)));

        if numel(idx) > 1              % data with >1 max peak:
          [v,i] = sort(idx,'descend'); % i(2) is always second largest peak (assuming >2 peaks found)
          peakfreqsecond(subjcnt) = allfreq(theta(idx(2)));
       end  % >1 peak
    end     % presence of peak
end         % subj loop

