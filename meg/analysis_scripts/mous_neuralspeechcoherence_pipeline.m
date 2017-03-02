mous_neuralspeechcoherence_pipelineoptions;

% This scripts allows user to toggle the options to calculate coherence
% between the MEG signal and the speech signal

% Speech signal options
% 1. speech envelope
% 2. phase  - not yet developed


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
  if ~exist('gamfoi','var')
      tmp  = tokenize(cohfoi,'');
      suff = [num2str(tmp{1}(1)),'-',num2str(tmp{1}(2)),'Hz']; 
      
  elseif exist('gamfoi','var') && isnumeric(gamfoi)
      tmp  = tokenize(gamfoi,'');
      suff = ['_gamma',num2str(tmp{1}(1)),'-',num2str(tmp{1}(2)),'Hz'];
      
      if ~isnumeric(cohfoi)
        [subjlist,~] = mous_db_getfilename('allA','subjectname');
        root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
        load([root,'/coherencePeakdetect_stage2_thres001_smoothing_sent']);

        idx      = find(ismember(subjlist,subjectname));
        switch cohfoi 
          case 'delta'
            freq     = cohfoi;
            cohfoi   = peakfreqfirst(idx,1);  % if NAN, will not enter next if-clause
          case 'theta' 
            freq     = cohfoi;
            cohfoi   = peakfreqfirst(idx,2);
        end
      else
        tmp  = tokenize(cohfoi,'');
        freq = [num2str(tmp{1}(1)),'-',num2str(tmp{1}(2)),'Hz'];
      end
  end
  
  if exist('gamfoi','var') && ~isnan(cohfoi(1))   % gamma with delta / theta (peak/range, therefore use (1))
    suff = [freq,suff];
    
   [sentcohAX, wlcohAX, sentcohPL, wlcohPL] = mous_neuralspeechcoherence_sensor(subjectname, cohfoi, gamfoi);
    sentcoh = sentcohAX;  wlcoh = wlcohAX;
    mous_db_putdata(subjectname, ['meg_coh_sensor_',suff,'_axial'],'sentcoh','wlcoh',rootdir);

    sentcoh = sentcohPL;  wlcoh = wlcohPL;
    mous_db_putdata(subjectname, ['meg_coh_sensor_',suff,'_planar'],'sentcoh','wlcoh',rootdir);

  elseif ~exist('gamfoi','var')                        % low freqs
    [sentcohAX, wlcohAX, sentcohPL, wlcohPL] = mous_neuralspeechcoherence_sensor(subjectname, cohfoi);
    sentcoh = sentcohAX;  wlcoh = wlcohAX;
    mous_db_putdata(subjectname, ['meg_coh_sensor_',suff,'_axial'],'sentcoh','wlcoh',rootdir);

    sentcoh = sentcohPL;  wlcoh = wlcohPL;
    mous_db_putdata(subjectname, ['meg_coh_sensor_',suff,'_planar'],'sentcoh','wlcoh',rootdir);
  end
end


%% average across subjects (sensor level)
% N.B. 55 subjects have an additional sensor, 274, instead of 273 
% need to fix ft_appendfreq to deal with labelcmb (not just label)
if dosensavg
%   suff               = '0-30Hz_planar';
%   suff               = 'delta_gamma30-50Hz_planar';
%   suff               = 'theta_gamma30-50Hz_planar';
  suff               = '0-20Hz_gamma30-50Hz_planar';
  
  [subjectname, ~ ] = mous_db_getfilename('allA','subjectname');
  [~,s]              = mous_db_getfilename('allA',['meg_coh_sensor_',suff,'.mat']);
  subjectname        = subjectname(s);
  nsubj              = num2str(numel(subjectname));  
  
  param              = 'cohspctrm';
  filename           = ['meg_coh_sensor_',suff];
  [cohgrpavg]        = mous_neuralspeechcoherence_grpavg(subjectname, filename, param,'/project/3011020.09/MEG/');

  cohgrpavg = rmfield(cohgrpavg,'cfg'); % decrease memory
  suff      = [suff,'_',nsubj,'subjs'];
  save(['/project/3011020.09/nielam/groupresults/coh/speechenvelope/grpavg_sensordata_coh_sent_',suff],...
        'cohgrpavg');        
end
%% compute source-level data
% Source-level data is computed for all specified frequency bands in one
% call of qsubfeval
% This allows preprocessed data to be computed once, and used for all low
% frequency bands 

% foi is a string that defines the frequency band (for dosens, it is a number)
% peak frequency for that frequency band is determined inside
% mous_neuralspeechcoherence_sourcedata

if dosource_low
  % determine how many frequency bands to calculate (number of loops)
  [subjlist,~] = mous_db_getfilename('allA','subjectname');
  root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
  load([root,'/coherencePeakdetect_stage2_thres001_smoothing_',condition]);
  
  idx      = find(ismember(subjlist,subjectname));
  tmp      = peakfreqfirst(idx,1:4);  % get index of frequencies with a peak
  
  idx1  = find(~isnan(tmp));
  idx2 = find(~cellfun(@isempty,foi));
  foi      = foi(intersect(idx1,idx2));
  
  switch condition
    case 'common'
      % source-localize for each freq
      [sentcoh, wlcoh, allcoh, preprocdat]  = mous_neuralspeechcoherence_sourcedata(subjectname,foi{1},condition);
      mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{1},'_surface_ampnorm_',condition,'peak'],'sentcoh','wlcoh','allcoh',rootdir,1);  

      if numel(foi) > 1
        for k = 2:numel(foi)
          [sentcoh, wlcoh,allcoh]  = mous_neuralspeechcoherence_sourcedata(subjectname,foi{k},condition,preprocdat);
          mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{k},'_surface_ampnorm_',condition,'peak'],'sentcoh','wlcoh','allcoh',rootdir,1);  
        end
      end
      
    case 'sent'
      [sentcoh, preprocdat] = mous_neuralspeechcoherence_sourcedata(subjectname,foi{1},condition);
      mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{1},'_surface_ampnorm_',condition,'peak'],'sentcoh',rootdir,1);  
      if numel(foi) > 1
        for k = 2:numel(foi)
          [sentcoh]  = mous_neuralspeechcoherence_sourcedata(subjectname,foi{k},condition,preprocdat);
          mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{k},'_surface_ampnorm_',condition,'peak'],'sentcoh',rootdir,1);  
        end
      end
  end
end

%% Gamma envelope - speech envelope (cross-frequency coupling) source-level
if dosource_high % gamma 
  % mous_neuralspeechcoherence_sourcedata_freqhigh is called multiple times
  % because computation of all sources is too demanding for memory
  
%%% list of subjects with a delta/theta  peak %%%
  [subjlist,~] = mous_db_getfilename('allA','subjectname');
  root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
  load([root,'/coherencePeakdetect_stage2_thres001_smoothing_',condition]);
  
  idx      = find(ismember(subjlist,subjectname));
  tmp      = peakfreqfirst(idx,1:4);  % get index of frequencies with a peak
 
  idx1  = find(~isnan(tmp));
  idx2 = find(~cellfun(@isempty,foi));
  foi      = foi(intersect(idx1,idx2));
  
  if ~isempty(foi) && ischar(foi{1})
    range                        = [num2str(sourcerange(1)),'to',num2str(sourcerange(2))];
    [sentcoh, source]  = mous_neuralspeechcoherence_sourcedata_freqhigh(subjectname,gamfoi,foi{1},sourcerange,condition);
    mous_db_putdata(subjectname,['meg_coh_sourcedata_gamma30to50Hz_source',range,'_',foi{1},'_surface_ampnorm_',condition,'peak'],'sentcoh',rootdir,1);
    
    if numel(foi) > 1
      for k = 2:numel(foi)
        [sentcoh]  = mous_neuralspeechcoherence_sourcedata_freqhigh(subjectname,gamfoi,foi{k},sourcerange,condition,source);
        mous_db_putdata(subjectname,['meg_coh_sourcedata_gamma30to50Hz_source',range,'_',foi{k},'_surface_ampnorm_',condition,'peak'],'sentcoh',rootdir,1);
      end
    end
    
  end
end


%% MEG-sentence random pair
if doshuffle_low
  
 [subjlist,~] = mous_db_getfilename('allA','subjectname');
  root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
  load([root,'/coherencePeakdetect_stage2_thres001_smoothing_sent']);  % decide to only use sent  26.06.2015 
  condition = 'sent';
  
  idx      = find(ismember(subjlist,subjectname));
  tmp      = peakfreqfirst(idx,1:4);  % get index of frequencies with a peak

  idx1  = find(~isnan(tmp));
  idx2  = find(~cellfun(@isempty,foi));
  foi   = foi(intersect(idx1,idx2));
  
  [sentcohshuf,pidx, preprocdat] = mous_neuralspeechcoherence_sourcedata_speechshuffle(subjectname,foi{1},numshuffle);
  mous_db_putdata(subjectname,['meg_coh_sourcedata_sentshuffle',foi{1},'_surface_ampnorm_',condition,'peak'],'sentcoh','sentcohshuf',rootdir,1);  
  
  if numel(foi) > 1
    for k = 2:numel(foi)
      [sentcohshuf,pidx]  = mous_neuralspeechcoherence_sourcedata_speechshuffle(subjectname,foi{k},numshuffle,preprocdat);
      mous_db_putdata(subjectname,['meg_coh_sourcedata_sentshuffle',foi{k},'_surface_ampnorm_',condition,'peak'],'sentcoh','sentcohshuf',rootdir,1);  
    end
  end
  
end


if dosource_low_regAC
   % determine how many frequency bands to calculate (number of loops)
  [subjlist,~] = mous_db_getfilename('allA','subjectname');
  root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
  load([root,'/coherencePeakdetect_stage2_thres001_smoothing_sent']);
  
  idx   = find(ismember(subjlist,subjectname));
  tmp   = peakfreqfirst(idx,1:4);  % get index of frequencies with a peak
  
  idx1  = find(~isnan(tmp));
  idx2  = find(~cellfun(@isempty,foi));
  foi   = foi(intersect(idx1,idx2));

  [sentcoh, preprocdat] = mous_neuralspeechcoherence_regAC_sourcedata(subjectname,foi{1});
  mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{1},'_regAC_seedLRAC_RHbased_surface_ampnorm_sentpeak'],'sentcoh',rootdir,1);  
  
  if numel(foi) > 1
    for k = 2 %:numel(foi)
      [sentcoh]  = mous_neuralspeechcoherence_regAC_sourcedata(subjectname,foi{k},preprocdat);
      mous_db_putdata(subjectname,['meg_coh_sourcedata_',foi{k},'_regAC_seedLRAC_RHbased_surface_ampnorm_sentpeak'],'sentcoh',rootdir,1);  
    end
  end  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE PART BELOW IS ADDED BY JM

if ~exist('subjectname', 'var'),
  error('a subjectname is required input');
end

if ~exist('dosens_ax',   'var'), dosens_ax   = false; end
if ~exist('dosens_peak', 'var'), dosens_peak = false; end
if ~exist('dosource_peak', 'var'), dosource_peak = false; end

if dosens_ax
  cfgpreproc          = [];
  cfgpreproc.hpfilter = 'no';
  [sentcoh, wlcoh, ~, ~, sentpow, wlpow, ~, ~] = mous_neuralspeechcoherence(subjectname, [0 60], 'doplanar', false,'cfgpreproc',cfgpreproc);
  mous_db_putdata(subjectname, 'meg_coh_sensor','sentcoh','wlcoh','sentpow','wlpow',rootdir,0);
end

if dosens_peak
  filename = mous_db_getfilename(subjectname, 'meg_coh_sensor');
  [sentpeak, sentcoh, wlpeak, wlcoh] = mous_neuralspeechcoherence_peakdetect(subjectname);
  save(filename{1}, 'sentpeak', 'wlpeak', 'sentcoh', 'wlcoh', '-append');
end

if dosource_peak
  if ~exist('condition', 'var'), condition = 'sent'; end
  source = mous_neuralspeechcoherence_source(subjectname, [], 'condition', condition);
  mous_db_putdata(subjectname, ['meg_coh_source',condition], 'source');
end

if dosens_cca
  [comp, compsent, compseq] = mous_neuralspeechcoherence_cca(subjectname);
  comp = rmfield(comp, 'trial');
  compsent = rmfield(compsent, 'trial');
  compseq  = rmfield(compseq, 'trial');
  mous_db_putdata(subjectname, 'meg_coh_sensor_cca','comp','compsent','compseq');
end

if dosource_groupresults
  subj  = mous_db_getfilename('allA', 'subjectname');
  [f,s] = mous_db_getfilename(subj, 'meg_coh_sourcesent');
  subj  = subj(s);
  
  delta = nan+zeros(8196,sum(s));
  theta = nan+zeros(8196,sum(s));
  for k = 1:numel(subj)
    mous_db_getdata(subj{k}, 'meg_coh_sourcesent');
    foi = [source.freq];
    seldelta = find(foi<=3 & foi>=1);
    seltheta = find(foi<=8 & foi>=4);
    
    if ~isempty(seldelta)
      D{k} = foi(seldelta);
      tmp = zeros(8196,1);
      for m = 1:numel(seldelta)
        tmp = tmp+source(seldelta(m)).avg.coh;
      end
      tmp = tmp./m;
      delta(:,k) = tmp;
    else
      delta(:,k) = nan;
    end
    if ~isempty(seltheta)
      T{k} = foi(seltheta);
      tmp = zeros(8196,1);
      for m = 1:numel(seltheta)
        tmp = tmp+source(seltheta(m)).avg.coh;
      end
      tmp = tmp./m;
      theta(:,k) = tmp;
    else
      theta(:,k) = nan;
    end
  end
  save('/project/3011020.09/jansch/results/20170103_audioentrainment/groupresults_delta', 'delta', 'D');
  save('/project/3011020.09/jansch/results/20170103_audioentrainment/groupresults_theta', 'theta', 'T');
  
end