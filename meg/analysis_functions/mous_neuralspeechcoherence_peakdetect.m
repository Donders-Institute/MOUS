%% mous_neuralspeechcoherence_peakdetect

[subj,s] = mous_db_getfilename('allA','subjectname');

numpeak = zeros(102,201); % subj x frequencies

%% first round of peak detection (rough)
for k = 1:102
  
  mous_db_getdata(subj{k},'meg_coh_sensor_0-100Hz_axial','/project/3011020.09/MEG/');
  
  % using all channels
  % Use all   : get untrue peaks -> set higher threshold for number of sensors to have that peak
  % Use subset: how to know whish subset for which subject?  -> don't, just approximate
  % using all seems to be a less subjective approach
  if size(sentcoh.labelcmb,1) == 548
    sentcoh.cohspctrm = sentcoh.cohspctrm(275:end,:);
    sentcoh.labelcmb = sentcoh.labelcmb(275:end,:);
    coi  = 1:274;
  else
    sentcoh.cohspctrm = sentcoh.cohspctrm(274:end,:);
    sentcoh.labelcmb = sentcoh.labelcmb(274:end,:);
    coi  = 1:273;
  end

  % get peaks
  numchan = size(sentcoh.cohspctrm,1);
  peak = zeros(numchan,12); % assume not more than 12 peaks detected per channel
  val = zeros(numchan,12);
  fcohpeak = zeros(numchan,numel(sentcoh.freq)); % binary matrix to record pre/absence of peak

  % FIXME: what threshold to set?  
  %        subject specific threshold?
  %        first explore data, then determine threshold?
  %        set heuristic, not more than 5 peaks, or only take first 5
  %        peaks?
  thres = 0.1;

  for chancnt = 1:numchan
    % peak index in data>thres & value of peak 
    [p,v] = peakdetect2NL(sentcoh.cohspctrm(coi(chancnt),:),thres,1);

    % determine frequency from peak value
    tmp = sentcoh.freq(p);

    % keep count which frequencies have peaks in a binary matrix
    % matrix: sensor by frequencies, 1 = peak, 0 = no peak
    if ~isempty(p)
      fcohpeak(chancnt,:) = ismember(sentcoh.freq,tmp);
    end

    % store all peaks and values
    if ~isempty(p)
      len = numel(p);
      peak(chancnt,1:len) = p;
      val(chancnt,1:len)  = v;
    end
  end % channel loop
  numpeak(k,:) = sum(fcohpeak,1);
end   % subjloop

save('/home/language/nielam/MOUS_AnalysisNotes/Coherence/coherencePeakdetect','numpeak');

%% standardize and smooth at the single-subject level
%  after first round, the peaks are still not that clear

% prefer a preproc_smoothing of 2 over 3, or 4.
figure;plot(sentcoh.freq,numpeak(102,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)))
hold on;plot(sentcoh.freq,ft_preproc_smooth(numpeak(102,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)),2),'r')
hold on;plot(sentcoh.freq,ft_preproc_smooth(numpeak(102,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm)),3),'k')

ft_preproc_smooth(numpeak(subjcounter,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm),3)
ft_preproc_smooth(numpeak(subjcounter,:).*mean(ft_preproc_standardize(sentcoh.cohspctrm),2)


% ft_preproc_standardize
% standardize data to have zero mean, unit SD
% value at each frequency is on same scale -> amplifies peaks

% ft_preproc_smooth
% smooths out peaks. In some cases there are frequencies side by side with
% prominent peaks which are smoothed into one.
%% second round of peak detection


% IMPLEMENT ME

%% determine peaks after 2nd round
%  If a peak is found within one of the prescribed frequency ranges, then
%  log that subject to have a peak in a particular frequency range
%  i.e. not every subject's dataset may contribute to having a peak in each frequency range

%  Based on the subjects selected to be in each frequency range
%  inspect individual and averaged topographies (are they similar?)
%  individual cohspctrm vs. averaged cohspctrm  (are they similar, is there
%  smoothing?) 


%% determine peak after 1st round within each frequency range
% delta 0   - 3.5  (0.5 - 3)
% theta 3.5 - 7.5  (4   - 7)
% alpha 7.5 - 12.5 (8   - 12)
% beta  13  - 30   (13  - 30)
% gamma 31  - 100

subjspecpeak = zeros(102,5); % matrix to store subject specific peak for each frequency range
allfreq = 0:0.5:100;
delta   = 2:7;
theta   = 9:15;
alpha   = 17:25;
beta    = 27:61;
gamma   = 64:201;

below25sensors = zeros(102,5); % record how many sensors for peak 
 
for sc = 1:102 %numel(subj)
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
    
    % search for peak in current frequency range
    [count,freq] = max(numpeak(sc,frange));  % get peak found in highest number of sensors
    if count > 25                          % if in more than 25 sensors
     subjspecpeak(sc,fb)   = allfreq(frange(freq));            % it is subj specific peak in current frequency range
    else % just take highest peak, but make a note
     subjspecpeak(sc,fb)   = allfreq(frange(freq));
     below25sensors(sc,fb) = count;
    end

  end % freqband  loop
end   % subj loop


figure;subplot(5,1,1), hist(subjspecpeak(:,1),0:0.5:3);
subplot(5,1,2), hist(subjspecpeak(:,2),4:0.5:7);
subplot(5,1,3), hist(subjspecpeak(:,3),8:0.5:12);
subplot(5,1,4), hist(subjspecpeak(:,4),13:0.5:30);
subplot(5,1,5), hist(subjspecpeak(:,5),31:0.5:100);





%% notes
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

numpeak = sum(fcohpeak,1);
idx     = find(numpeak >5); 
consistentpeak = sentcoh.freq(idx)

% retina peaks that are in >10 sensors
numpeak = sum(fcohpeak,1);
idx     = find(numpeak >10); 
consistentpeak = sentcoh.freq(idx)
% axialgrad:  61 peaks; almost every peak from 0 to 11
% planargrad:  0 0.5 1.5 2 | 4 4.5 5 5.5. 6.5 | 9 10 11.5 12 | 36.5

numpeak = sum(fcohpeak,1);
idx     = find(numpeak >20); 
consistentpeak = sentcoh.freq(idx)
%axial: 0 0.5 1.5 2 | 4 5.5. 6.5 7 8 9 11 12 | 21.5 22.5 26 31.5 |and more
%olanar: 0.5 1.5  | 4  6.5 | 9 | nothing

numpeak = sum(fcohpeak,1);
idx     = find(numpeak >25); 
consistentpeak = sentcoh.freq(idx)













