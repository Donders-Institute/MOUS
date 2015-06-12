% MOUS_20150410
% calculate source-level laterality for delta, theta, and gamma
function mous_neuralspeechcoherence_statistics_surface_sentwl(frequency,condition,corrmeth)

% mous_coherence_lateralization_source determines whether there is
% lateralization between the coherence of the speech envelope and cortical% For each hemisphere, 5 sensors with the highest coherence value are
% selected and an average coherence value is determine for each hemisphere
% oscillations at a particular frequency band
% Currently a whole brain approach is used, where homologous voxels in one
% hemisphere (right) are subtracted from the other (left).


%% Determine subject list depending on frequency 
[subj,~] = mous_db_getfilename('allA','subjectname');

switch frequency
  case {'delta' 'gammad'}
    selfreq = 1;
  case {'theta' 'gammat'};
    selfreq = 2;  
  case {'alpha'}
    selfreq = 3;
  case {'beta'}
    selfreq = 4;
end

root     = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
load([root,'/coherencePeakdetect_stage2_thres001_smoothing_',condition]);

tmp      = find(~isnan(peakfreqfirst(:,selfreq)));
if ~isempty(tmp)
  subj          = subj(tmp);            % retain subjs with peak
  peakfreqfirst = peakfreqfirst(tmp,:); % retain freqs of relevant subjs
end

%% load data 

% subjects data are on the cortical sheet (no need template sourcemodel)
% vertex point X in subjA refers to same anatomical location of vertex point X in subjB
for k = 1:numel(subj)
  mous_db_getdata(subj{k},['meg_coh_sourcedata_',frequency,'_surface_ampnorm_',condition,'peak']);
  
  % take sqrt of sentcoh and wlcoh (ft_sourceanalysis return coherence^2)
  sentcoh.avg.coh = sqrt((sentcoh.avg.coh));
  wlcoh.avg.coh   = sqrt((wlcoh.avg.coh));
  
  % control for different number of trials between conditions
  % (Maris,Schoffelen & Fries, 2007)
  sdof  = 2*numel(sentcoh.cumtapcnt)*sentcoh.cumtapcnt(1);
  wdof  = 2*numel(wlcoh.cumtapcnt)*wlcoh.cumtapcnt(1);
  
  denom = sqrt((1/(sdof -2)) + (1/(wdof -2)));
  sentcoh.avg.coh = ((atanh(abs(sentcoh.avg.coh))) - (1/(sdof-2))) / denom;
  wlcoh.avg.coh   = ((atanh(abs(wlcoh.avg.coh)))   - (1/(wdof-2))) / denom;

  if k == 1
    source1{k} = sentcoh;
    source2{k} = wlcoh;
  else
    source1{k} = source1{1};
    source2{k} = source2{1}; % use same pos definition across subjects
    source1{k}.avg.coh = sentcoh.avg.coh;
    source2{k}.avg.coh = wlcoh.avg.coh;
  end

  %%% grp-average coherence %%%
  if k == 1
    senavg = sentcoh;
    wlavg  = wlcoh;
    comavg = allcoh;
  else
    senavg.avg.coh = senavg.avg.coh + sentcoh.avg.coh; 
    wlavg.avg.coh  = wlavg.avg.coh  + wlcoh.avg.coh; 
    comavg.avg.coh = comavg.avg.coh + allcoh.avg.coh; 
  end
end

senavg.avg.coh = senavg.avg.coh/numel(subj);  
wlavg.avg.coh  = wlavg.avg.coh/numel(subj);  
comavg.avg.coh = comavg.avg.coh/numel(subj);  

senavg = rmfield(senavg,'cfg');
wlavg  = rmfield(wlavg,'cfg');
comavg = rmfield(comavg,'cfg');

 

%% statistics
load('/home/language/nielam/MOUS/meg/templates/cortex_midthickness_8196reg.mat')
C = full(tri2connmat(sourcemodel.tri)); % output is sparse, use full()

nsubj  = numel(subj);
cfg    = [];
cfg.method           = 'montecarlo';
cfg.numrandomization = 2000;
cfg.clusterthreshold = 'nonparametric_common';
cfg.correctm         = corrmeth;% try 'max' (but might be too stringent)
cfg.correcttail      = 'alpha';  % each tail tested with alpha = 0.025
cfg.ivar             = 1;
cfg.uvar             = 2;
cfg.design           = [ones(1,nsubj), ones(1,nsubj)*2; 1:nsubj 1:nsubj];
cfg.parameter        = 'avg.coh';
cfg.statistic        = 'statfun_signrankZ'; %  'depsamplesT';
cfg.sminside         = source1{1}.inside;
cfg.connectivity     = C; % neighbours on cortical sheet, binary 
stat = ft_sourcestatistics(cfg,source1{:},source2{:});

root = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
save([root,'stat_surface_sentvswl_',condition,'peak_',frequency,'_',num2str(nsubj),'subj','_corrm',corrmeth],'stat','senavg','wlavg','comavg')


% %% plot
%   cfg = [];
%   cfg.method = 'ortho';
%   cfg.funcolorlim = 'maxabs';
%   cfg.funcolormap = 'jet';
%   cfg.funparameter = 'stat';
%   cfg.maskparameter = 'mask2';
%   ft_sourceplot(cfg,stat); 
%   
%   cfg.method = 'slice';
%   cfg.funparameter = 'pow';
%   ft_sourceplot(cfg,grp);
  
