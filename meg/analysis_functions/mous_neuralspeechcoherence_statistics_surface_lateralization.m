% MOUS_20150410
% calculate source-level laterality for delta, theta, and gamma
function mous_neuralspeechcoherence_statistics_surface_lateralization(frequency,condition,corrmeth)

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
for k = 1:numel(subj)
   
  mous_db_getdata(subj{k},['meg_coh_sourcedata_',frequency,'_surface_ampnorm_',condition,'peak']);
  
  % no need to load a sourcemodel 
  % all subjects' data are transformed to a cortical sheet
  % subjects have been normalized, so vertex point X in subjA refers to
  % same anatomical location of vertex point X in subjB
  
  % create second (right) condition by flipping left<>right dimension
  tmp     = zeros(size(sentcoh.avg.coh));
  tmp     = [sentcoh.avg.coh(4099:8196);sentcoh.avg.coh(1:4098)]; 
  
%   sentcoh.inside(1:numvert/2)  = false;  % limit testing to first half of the vertices 
  
  if k == 1
    source1{k} = sentcoh;
    source2{k} = sentcoh;
    source2{k}.avg.coh = tmp;
  else
    source1{k} = source1{1};
    source2{k} = source2{1}; % use same pos definition across subjects
    source1{k}.avg.coh = sentcoh.avg.coh;
    source2{k}.avg.coh = tmp;
  end
  
   %%% grp-average coherence %%%
  if k == 1
    leftavg   = sentcoh;
    rightavg  = sentcoh;
    rightavg.avg.coh = tmp;
  else
    leftavg.avg.coh   = leftavg.avg.coh  + sentcoh.avg.coh; 
    rightavg.avg.coh  = rightavg.avg.coh + tmp; 
  end
end

leftavg.avg.coh   = leftavg.avg.coh/numel(subj);  
rightavg.avg.coh  = rightavg.avg.coh/numel(subj);  

leftavg   = rmfield(leftavg,'cfg');
rightavg  = rmfield(rightavg,'cfg');


%% statistics
load('/home/language/nielam/MOUS/meg/templates/cortex_midthickness_8196reg.mat')
C = full(tri2connmat(sourcemodel.tri)); % output is sparse, use full()

nsubj  = numel(subj);
cfg    = [];
cfg.method           = 'montecarlo';
cfg.numrandomization = 2000;
cfg.clusterthreshold = 'nonparametric_common';
cfg.correctm         = corrmeth;
cfg.correcttail      = 'alpha';  % each tail tested with alpha = 0.025
cfg.ivar             = 1;
cfg.uvar             = 2;
cfg.design           = [ones(1,nsubj), ones(1,nsubj)*2; 1:nsubj 1:nsubj];
cfg.parameter        = 'avg.coh';
cfg.statistic        = 'statfun_signrankZ';       % 'depsamplesT';
cfg.sminside         = source1{1}.inside(1:4098); % test one hemisphere 
cfg.connectivity     = C; 
stat = ft_sourcestatistics(cfg,source1{:},source2{:});

root = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
save([root,'stat_surface_lateralization_',condition,'peak_',frequency,'_',num2str(nsubj),'subj_corrm',corrmeth,'.mat'],'stat','leftavg','rightavg');


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
  
