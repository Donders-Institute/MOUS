%%% mous_neuralspeechcoherence_peakdetect
%  This function searches for peaks in each channel, peaks that are most frequently found
%  across all channels (>25) are considered to be true peaks

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
%     The second round creates more defined peaks
      % Take the smoothed coherence spectrum and multiplies 
      % it to the mean of the standardized coherence spectrum
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
allfreq = 0:0.5:100;
numpeak = zeros(numel(subj),numel(allfreq)); % subj x frequencies

%% first round of peak detection (rough)
for k = 1:102
  mous_db_getdata(subj{k},'meg_coh_sensor_0-100Hz_axial','/project/3011020.09/MEG/');
  
  % first set of channels are coherence with MEG speech signal, not original audio signal
  if size(sentcoh.labelcmb,1) == 548
    sentcoh.cohspctrm = sentcoh.cohspctrm(275:end,:);
    sentcoh.labelcmb  = sentcoh.labelcmb(275:end,:);
    coi               = 1:274;
  else
    sentcoh.cohspctrm = sentcoh.cohspctrm(274:end,:);
    sentcoh.labelcmb  = sentcoh.labelcmb(274:end,:);
    coi               = 1:273;
  end

  % allocate memory
  numchan  = size(sentcoh.cohspctrm,1);
  peak     = zeros(numchan,12); % assume not more than 12 peaks detected per channel
  val      = zeros(numchan,12); % keep count which frequencies have peaks in a binary matrix (1 = peak)
  fcohpeak = zeros(numchan,numel(sentcoh.freq)); % binary matrix to record pre/absence of peak

  % Difficult to determine subject specific threshold
  % using heuristic of 0.1; option to not set a threshold. 
  thres    = 0.1;

  for chancnt = 1:numchan
    [p,v]  = peakdetect2NL(sentcoh.cohspctrm(coi(chancnt),:),thres,1);  % peak index in data>thres & value of peak 
    tmp    = sentcoh.freq(p);   % determine frequency from peak value

    if ~isempty(p)              
      fcohpeak(chancnt,:) = ismember(sentcoh.freq,tmp);
    end

    if ~isempty(p)         % store all peaks and values
      len = numel(p);
      peak(chancnt,1:len) = p;
      val(chancnt,1:len)  = v;
    end
  end                      % channel loop
  numpeak(k,:)            = sum(fcohpeak,1);
end                        % subjloop

save('/home/language/nielam/MOUS_AnalysisNotes/Coherence/coherencePeakdetect','numpeak');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% standardize and smooth at the single-subject level, then do a second round of peak detection
%  after first round, the peaks are still not that clear

[subj,s]       = mous_db_getfilename('allA','subjectname');
freq           = 0:0.5:100;
peakallsubj    = zeros(numel(subj),numel(freq)); % exclude 0 Hz
cohallsubj     = zeros(numel(subj),numel(freq));
for k = 1:102
  mous_db_getdata(subj{k},'meg_coh_sensor_0-100Hz_axial','/project/3011020.09/MEG/');
  
  if size(sentcoh.labelcmb,1) == 548
    sentcoh.cohspctrm = sentcoh.cohspctrm(275:end,:);
    sentcoh.labelcmb = sentcoh.labelcmb(275:end,:);
    coi  = 1:274;
  else
    sentcoh.cohspctrm = sentcoh.cohspctrm(274:end,:);
    sentcoh.labelcmb = sentcoh.labelcmb(274:end,:);
    coi  = 1:273;
  end
  
  sentcoh.cohspctrm = ft_preproc_smooth(numpeak(k,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)),2); 
  cohallsubj(k,:)   = sentcoh.cohspctrm; % smoothed and standardized data from all subjs
  
  thres    = 2;  
  [p,v]  = peakdetect2NL(sentcoh.cohspctrm,thres,1); % p = peak index, v = value of peak
  tmp    = sentcoh.freq(p); % determine frequency from peak value
  if ~isempty(p)            % keep count which frequencies have peaks in a binary matrix (1 = peak)
    peakallsubj(k,:) = ismember(sentcoh.freq,tmp);
  end
    
end                         % subj loop

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

allfreq = 0:0.5:100;
peakfreqfirst  = nan(102,5); % matrix to store subject specific peak for each frequency range
peakfreqsecond = nan(102,5); % use 'nan', can differentiate between subjs with no peaks vs. peak at sentcoh.freq(1) i.e. 0 Hz
delta   = 1:7;    % indices of sentcoh.freq
theta   = 9:15;
alpha   = 17:25;
beta    = 27:61;
gamma   = 64:201; % gamma peaks are not reliable, but computed for completeness sake; descriptive data

for sc = 1:102
  for fb = 1:5
    % assign frequency range 
      if fb == 1
        frange = delta;
      elseif fb == 2
        frange = theta;
      elseif fb == 3
        frange = alpha;
      elseif fb == 4
        frange = beta;
      elseif fb == 5
        frange = gamma;
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

save('/home/language/nielam/MOUS_AnalysisNotes/Coherence/coherencePeakdetect_stage2','peakfreqfirst','peakfreqsecond');


%% plot histogram of peak frequencies
figure;subplot(5,1,1), hist(peakfreqfirst(:,1),0:0.5:3);
subplot(5,1,2), hist(peakfreqfirst(:,2),4:0.5:7);
subplot(5,1,3), hist(peakfreqfirst(:,3),8:0.5:12);
subplot(5,1,4), hist(peakfreqfirst(:,4),13:0.5:30);
subplot(5,1,5), hist(peakfreqfirst(:,5),31:0.5:100);

figure;subplot(5,1,1), hist(peakfreqsecond(:,1),0:0.5:3);
subplot(5,1,2), hist(peakfreqsecond(:,2),4:0.5:7);
subplot(5,1,3), hist(peakfreqsecond(:,3),8:0.5:12);
subplot(5,1,4), hist(peakfreqsecond(:,4),13:0.5:30);
subplot(5,1,5), hist(peakfreqsecond(:,5),31:0.5:100);

[subj,s] = mous_db_getfilename('allA','subjectname');
allfreq = 0:0.5:100;
x = 1:10
figure; subplot(numel(x),1,1), plot(allfreq,cohallsubj(x(1),:));
for m = x(2):numel(x)
  subplot(numel(x),1,m), plot(allfreq,cohallsubj(m,:));
end
% fprintf('speech-MEG coherence frequency peaks: subj %s - %s',subj{x(1)}, subj{x(end)});

s = 11:20
figure;subplot(numel(x),1,1), plot(allfreq,cohallsubj(s(1),:));
for m = 2:10
  subplot(numel(x),1,m), plot(allfreq,cohallsubj(s(m),:));
end

s = 61:70
figure;subplot(numel(x),1,1), plot(allfreq,cohallsubj(s(1),:));
for m = 2:10
  subplot(numel(x),1,m), plot(allfreq,cohallsubj(s(m),:));
end

s = 91:100
figure;subplot(numel(x),1,1), plot(allfreq,cohallsubj(s(1),:));
for m = 2:10
  subplot(numel(x),1,m), plot(allfreq,cohallsubj(s(m),:));
end


%% notes

% 1 prefer a preproc_smoothing of 2 over 3, or 4.
% figure;plot(sentcoh.freq,numpeak(102,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)))
% hold on;plot(sentcoh.freq,ft_preproc_smooth(numpeak(102,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)),2),'r')
% hold on;plot(sentcoh.freq,ft_preproc_smooth(numpeak(10g2,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)),3),'k')

% 2 Checked peaks from algorithm with manual detection (in original signal)
% Algorithm peaks are similar to manual detection
% algorithm peaks do select frequecies that have a reasonable topography
% (specific, not blobs everywhere)


% define trial
% FIXME: do we need a long baseline? No, just highest value from zero
% FIXME: vanPelt et al.(2012) excluded beginning of trial to avoid 
% "response onset transient"  <- response to stimulus change on screen?

% redefine trials to improve spectral estimation
% vanPelt et al.(2012) had 50% overlap for 600 ms epochs
cfg = [];
cfg.length  = 2;    
cfg.overlap = 0.5; 

%% how to determine 'same peak' across channels 
% Problem:  local maxima in defined frequency range in each channel ~= same local
% maxima between channels
% Solution1: consider as same peak if overlaps within 1 Hz. 
%           Test if this is too wide.
% Solution2: consider same peak, as long as there is one peak with defined
%            frequency range of interest

% sentcoh.labelcmb(137) = MRC15
% sentcoh.labelcmb(187) = MRF65

% peakdetect2
% get data above threshold
% group data points together if they are less than the minimum distance
% find a max peak for each group of data points

% peakdetect3
% get data above threshold
% find all peaks using deriative 
  % if index in difference between data points >0 and difference between data points <0 
  % are both true, then we have a peak
% from all detected peaks, remove those that are less than the defined
% minimum distance apart.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% when using all sensors %%%
% retain peaks that are in >5 sensors (and within 1 Hz of each other?)
% leads to 0:0.5:10 all are consistent peaks
% 
% numpeak = sum(fcohpeak,1);
% idx     = find(numpeak >5); 
% consistentpeak = sentcoh.freq(idx)
% 
% % retina peaks that are in >10 sensors
% numpeak = sum(fcohpeak,1);
% idx     = find(numpeak >10); 
% consistentpeak = sentcoh.freq(idx)
% % axialgrad:  61 peaks; almost every peak from 0 to 11
% % planargrad:  0 0.5 1.5 2 | 4 4.5 5 5.5. 6.5 | 9 10 11.5 12 | 36.5
% 
% numpeak = sum(fcohpeak,1);
% idx     = find(numpeak >20); 
% consistentpeak = sentcoh.freq(idx)
% %axial: 0 0.5 1.5 2 | 4 5.5. 6.5 7 8 9 11 12 | 21.5 22.5 26 31.5 |and more
% %olanar: 0.5 1.5  | 4  6.5 | 9 | nothing
% 
% numpeak = sum(fcohpeak,1);
% idx     = find(numpeak >25); 
% consistentpeak = sentcoh.freq(idx)













