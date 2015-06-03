function mous_neuralspeechcoherence_lateralization_sensor(frequency,sensortype)

% mous_coherence_lateralization_sensor determines whether there is
% lateralization between the coherence of the speech envelope and cortical
% oscillations at a particular frequency band
% For each hemisphere, 5 sensors with the highest coherence value are
% selected and an average coherence value is determine for each hemisphere

% A coherence value for each hemisphere is obtain per subject
% These values L vs. R are then subjected to statistics at the group level

% peak frequency determine from using all 273 sensors
load('/project/3011020.09/nielam/groupresults/coh/speechenvelope/coherencePeakdetect_stage2_thres001_smoothing_sent.mat');

% track sensors
senslist = cell(102,10);

switch frequency
  case 'delta'
    selfreq = 1;
  case 'theta'
    selfreq = 2;
  case 'gamma'
    error('peak needs to be calculated')
end

% trim subject list to only include those with a peak in foi
[subj,~] = mous_db_getfilename('allA','subjectname');
tmp      = find(~isnan(peakfreqfirst(:,selfreq)));
if ~isempty(tmp)
  subj          = subj(tmp);            % retain subjs with peak
  peakfreqfirst = peakfreqfirst(tmp,:); % retain freqs of relevant subjs
end

switch sensortype
  case 'topfive'
  % calculate mean coherence value for each hemisphere
    for k = 1:numel(subj)

      % load data
      mous_db_getdata(subj{k},'meg_coh_sensor_0-30Hz_axial','/project/3011020.09/MEG/');

      % select frequencies and MEG-audio_avg channel pairs
      cfg = [];
      cfg.frequency  = peakfreqfirst(k,selfreq); % for delta
      cfg.channelcmb = sentcoh.labelcmb;
      data           = ft_selectdata(cfg,sentcoh);
      data.label     = data.labelcmb(:,1); % ft_channelselection only works on label, not labelcmb
      data           = rmfield(data,'labelcmb');

      %%% Left sensors %%%
      cfg = [];
      cfg.channel   = ft_channelselection('ML',data.label);
      dataleft      = ft_selectdata(cfg,data); 
      [y,i1]    = sort(dataleft.cohspctrm,'descend');  % determine top 5 sensors (assumed to be neighbours)
      leftcoh  = mean(dataleft.cohspctrm(i1(1:5)));
      %   dataleft.label(i(1:5),:);

      %%% Right sensors %%%
      cfg = [];
      cfg.channel   = ft_channelselection('MR',data.label);
      dataright     = ft_selectdata(cfg,data);
      [y,i2]    = sort(dataright.cohspctrm,'descend');  % determine top 5 sensors (assumed to be neighbours)
      rightcoh = mean(dataright.cohspctrm(i2(1:5)));

      senslist(k,1:5)  = dataleft.label(i1(1:5))';
      senslist(k,6:10) = dataright.label(i2(1:5))';

      if k == 1
        lateralcoh{k}           = data;
        lateralcoh{k}.label     = lateralcoh{k}.label(1);
        lateralcoh{k}.cohspctrm = (leftcoh-rightcoh)/(leftcoh+rightcoh);   
      else
        lateralcoh{k}           = lateralcoh{1};
        lateralcoh{k}.cohspctrm = (leftcoh-rightcoh)/(leftcoh+rightcoh);
      end
      
      leftcohall{k}           = lateralcoh{k};
      leftcohall{k}.cohspctrm = leftcoh;
       
      rightcohall{k}           = lateralcoh{k};
      rightcohall{k}.cohspctrm = rightcoh;

      dummycoh{k}             = lateralcoh{k};
      dummycoh{k}.cohspctrm   = 0;
      
    end
    
  case 'predeter' % predetermine sensors based on grpavg
    
    listleft  = {'MRF67','MRT13','MRT14','MRT23','MRT24'};
    listright = {'MLF67','MLT13','MLT14','MLT23','MLT24'};
    
    for k = 1:numel(subj)
       % load data
      mous_db_getdata(subj{k},'meg_coh_sensor_0-30Hz_axial','/project/3011020.09/MEG/');

      % select frequencies and MEG-audio_avg channel pairs
      sel = size(sentcoh.labelcmb,1)/2;
      cfg = [];
      cfg.frequency  = peakfreqfirst(k,selfreq); % for delta
      cfg.channelcmb = sentcoh.labelcmb(sel+1:end,:);
      data           = ft_selectdata(cfg,sentcoh);
      data.label     = data.labelcmb(:,1); % ft_channelselection only works on label, not labelcmb
      data           = rmfield(data,'labelcmb');
      
      %%% Left sensors %%%
      cfg = [];
      cfg.channel   = ft_channelselection(listleft,data.label);
      dataleft      = ft_selectdata(cfg,data); 
      leftcoh       = mean(dataleft.cohspctrm);
      %   dataleft.label(i(1:5),:);
      
      %%% Right sensors %%%
      cfg = [];
      cfg.channel   = ft_channelselection(listright,data.label);
      dataright     = ft_selectdata(cfg,data);
      rightcoh      = mean(dataright.cohspctrm);

      if k == 1
        lateralcoh{k}           = data;
        lateralcoh{k}.label     = lateralcoh{k}.label(1);
        lateralcoh{k}.cohspctrm = (leftcoh-rightcoh)/(leftcoh+rightcoh);   
      else
        lateralcoh{k}           = lateralcoh{1};
        lateralcoh{k}.cohspctrm = (leftcoh-rightcoh)/(leftcoh+rightcoh);
      end
      
      dummycoh{k}             = lateralcoh{k};
      dummycoh{k}.cohspctrm   = 0;
    end
end

% convert to +ve or -ve value
% L-R
% +ve = left lateralized
% -ve = right lateralized
coh2 = lateralcoh;
for k = 1:numel(subj)
  if coh2{k}.cohspctrm > 0
    coh2{k}.cohspctrm = 1;
  elseif coh2{k}.cohspctrm < 0
    coh2{k}.cohspctrm = -1;
  end
end

for k = 1:numel(subj)
  value(k) = lateralcoh{k}.cohspctrm;
  value2(k) = coh2{k}.cohspctrm;
end

%% statistics

nsubj = numel(subj);
cfg = [];
cfg.method      = 'montecarlo';
cfg.channel     = 'MLC11';        % dummy channel
cfg.correctm    = 'no';           % at sensor-level, only comparing 1 value across subjects
cfg.numrandomization = 2000;
cfg.alpha       = 0.05;
cfg.correcttail = 'alpha';
cfg.design      = [ones(1,nsubj) ones(1,nsubj)*2; 1:nsubj, 1:nsubj];
cfg.ivar        = 1;
cfg.uvar        = 2;
cfg.parameter   = 'cohspctrm';

cfg.statistic   = 'statfun_signrankZ';
stat   = ft_freqstatistics(cfg,leftcohall{:},rightcohall{:});
% 
% cfg.statistic   = 'statfun_signrankZ'; % non-parametric depsamplesT
% stat2   = ft_freqstatistics(cfg, coh2{:},dummycoh{:});
%  
% cfg.statistic   = 'depsamplesT';     % parametric test, depsamplesT
% stat3  = ft_freqstatistics(cfg, coh2{:},dummycoh{:});
% stat3o = ft_freqstatistics(cfg, lateralcoh{:},dummycoh{:});

stat  = rmfield(stat,'cfg');

switch sensortype
  case 'topfive'
    save(['/project/3011020.09/nielam/groupresults/coh/speechenvelope/sensordata_coh_lateral_top5sens',frequency,'_',num2str(nsubj),'subjs.mat'],'stat','subj','senslist')
  case 'predeter'
    save(['/project/3011020.09/nielam/groupresults/coh/speechenvelope/sensordata_coh_lateral_allsubjsamesens',frequency,'_',num2str(nsubj),'subjs.mat'],'stat','subj','listleft')
end

    
end 
