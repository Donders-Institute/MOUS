% this script contains the the two sets of analyses in the neuralspeechcoherence_covariation_pipeline
% To test for a correlation between the peaks in the coherence spectrum
% (from oscillatory entrainment to the speech envelope) and
% (1) peak in the power spectrum of MEG resting state data 
% (2) peak in the powe spectrum of the frequency domain representation of
% evoked potentials in response to the onsets of the ramps in the speech
% signal

% $Id: mous_neuralspeechcoherence_covariation_pipeline.m 2016-07-06 NL

if ~exist('rootdir', 'var'),             rootdir = '/project/3011020.09/MEG'; end

if ~exist('dorestingpreproc', 'var'),    dorestingpreproc = 0; end
if ~exist('dorestingprewhite_powcalc', 'var'),    dorestingprewhite_powcalc = 0; end
if ~exist('dorestingpeakdetect', 'var'), dorestingpeakdetect = 0; end

if ~exist('doevokedcalc', 'var'),        doevokedcalc = 0; end
if ~exist('doevokedpeakdetect', 'var'),  doevokedpeakdetect = 0; end


%% resting state power
if dorestingpreproc
    
    % dodss
    [subj,~] = mous_db_getfilename('allA','subjectname');
    rootdir = '/project/3011020.09/nielam/';
    dodss =  1;
    for k = 1:102
        subjectname = subj{k};
        mous_restingstate_pipeline
    end 
    
    % check how much data is retained in resting state
    [remain] = mous_restingstate_datarentention;
        %  All 102 subjects have restingstate data
        %  mean:    85%
        %  median:  88%
        %  13 individuals with <75% data
end

if dorestingprewhite_powcalc
    mous_restingstate_prewhite_calcpow(subj,len)
end

if dorestingpeakdetect % not to be run as part of pipeline since this runs for all subjects at once; included for completeness
    % duration = length of trial: 2,3, or 4 (seconds) as a string variable
    [peakfreqfirst, ~] = mous_restingstate_peakdetect(duration);
    peakfreqfirst(isnan(peakfreqfirst)) = 0;
    save(['/project/3011020.09/nielam/groupresults/rs/powspctrm_',duration,'s_peakdetect_stage2_allchan_1to7.5.mat'],'peakfreqfirst','peakfreqsecond','freqallsubj');
    
    % correlate to coherence peak spectrum, across individuals
    peakfreqfirstrs = peakfreqfirst;
    load coherencePeakdetect_stage2_thres001_smoothing_sent.mat      % coherence peak spectrum of neural entrainment to speech (sentences only)
    a   = [peakfreqfirstrs,peakfreqfirst(:,2)];
    idx = find(isnan(a(:,2)));
    a(idx,:) = [];
    idx = find(a(:,1) == 0)
    a(idx,:) = [];

    figure;scatter(a(:,1),a(:,2),'jitter','on','jitterAmount',0.06)
    [r,p] = corr(a)
    % r = -0.0248; p = 0.8284
    
    [r,p] = corr(a,'type','spearman') 
    % r = 0.02;    p = 0.8649 (spearman)
end

%% evoked potentials
if doevokedcalc  % copied from mous_erf_pipeline 'doerf_speech_tlck'
    [tlck, tlck_sent, tlck_seq, tlck_seq2] = mous_neuralspeechtimelocked_sensor(subjectname, 'up');
    mous_db_putdata(subjectname, 'meg_erf_speech_tlck' ,'tlck', 'tlck_sent', 'tlck_seq', 'tlck_seq2', outrootdir,1);
end

if doevoke2freq
    [subj,~] = mous_db_getfilename('allA','subjectname');
    for k = 1:numel(subj)
        subjectname = subj{k};
        [freq] = mous_neuralspeechcoherence_evoke2freq(subjectname);
        mous_db_putdata(subjectname,'meg_erf_speech_tlck2freq_2s_nochanavg','freq');
    end 
end

if doevokedpeakdetect % not to be run as part of pipeline since this runs for all subjects at once; included for completeness
    duration       = '2';
    filename       = ['meg_erf_speech_tlck2freq_',duration,'s_nochanavg'];
    [peakfreqfirst, peakfreqsecond] = mous_tlck2freq_peakdetect(filename);
    save(['/project/3011020.09/nielam/groupresults/coh/speechenvelope/tlck2freq',duration,'s_powspctrmtheta_allchan_stage2'],'peakfreqfirst','peakfreqsecond');
    
    % calculate correlation
    peakfreqfirst_pow = peakfreqfirst;
    load coherencePeakdetect_stage2_thres001_smoothing_sent.mat
    a   = [peakfreqfirst_pow,peakfreqfirst(:,2)]
    idx = find(isnan(a(:,2)));
    a(idx,:) = [];
    idx = find(a(:,1) == 0);
    a(idx,:) = [];

    figure; scatter(a(:,1),a(:,2),'jitter','on','jitterAmount',0.06)
    % http://stackoverflow.com/questions/13778799/scatterplot-visualize-the-same-points-in-matlab
           
    [r,p] = corr(a) 
    % r = -0.1424; p = 0.1756
end

