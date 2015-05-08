% MOUS_20150410
% calculate source-level laterality for delta, theta, and gamma
function mous_neuralspeechcoherence_statistics_lat_source(frequency)

% mous_coherence_lateralization_source determines whether there is
% lateralization between the coherence of the speech envelope and cortical% For each hemisphere, 5 sensors with the highest coherence value are
% selected and an average coherence value is determine for each hemisphere
% oscillations at a particular frequency band
% Currently a whole brain approach is used, where homologous voxels in one
% hemisphere (right) are subtracted from the other (left).


%% Determine subject list depending on frequency 
[subj,~] = mous_db_getfilename('allA','subjectname');

switch frequency
  case 'delta'
    selfreq = 1;
  case 'theta'
    selfreq = 2;
  case 'gamma'
    error('peak needs to be calculated')
end

load('/home/language/nielam/MOUS_AnalysisNotes/Coherence/coherencePeakdetect_stage2_thres5_pd3');
tmp      = find(~isnan(peakfreqfirst(:,selfreq)));
if ~isempty(tmp)
  subj          = subj(tmp);            % retain subjs with peak
  peakfreqfirst = peakfreqfirst(tmp,:); % retain freqs of relevant subjs
end

%% load data 
% load sourcemodel
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);
sourcemodeltemplate = sourcemodel;

for k = 1:numel(subj)
  if k == 1
    % sourcemodel.pos is updated from sourcemodeltemplate.pos
    % sourcemodel gets 'freq','time','dimord' updated below as well
    % sourcemodel 'inside' and 'outside' stay the same, and are the same
    % for all subjects
    % that's why sourcemodel is only called once
    mous_db_getdata(subj{k}, 'meg_bfica_leadfield8mm', '/project/3011020.09/nielam/');
    sourcemodel = rmfield(sourcemodel, 'leadfield');
    if isfield(sourcemodel, 'cfg')
      sourcemodel = rmfield(sourcemodel, 'cfg');
    end
  end
    
  mous_db_getdata(subj{k},['meg_coh_sourcedata_',frequency,'_thres5_pd3']);
  
  %% create two conditions, 1 left and 1 right
  % Right created by flipping left with right 
  % condition 1 left = left 
  % condition 2 left = right
  
  % x           y         z
  % leftright  sup/inf   antpost
  tmp        = reshape(sentcoh.avg.coh,sentcoh.dim); % 11000 -> [20 25 22]
  tmp        = tmp(end:-1:1,:,:); % flip x-axis; alternative use flipdim
  flipsource = tmp(:);            % reshape into 11000 x 1
  
  if k == 1
  %% find  left size voxels
%     tmp  = reshape(sentcoh.avg.coh,sentcoh.dim);
%     tmp2 = tmp;
%     tmp2(sentcoh.inside) = 0;
%     for x = 1:10
%       for y = 1:25
%         for z = 1:22
%           if ~isnan(tmp(x,y,z))
%             tmp2(x,y,z) = 1;   % index left size voxels
%           end
%         end
%       end
%     end
%     tmp2 = tmp2(:);
%     idx  = find(tmp2 == 1);  % numel = 2863  (5798/2 = 2899; close enough?)
%     sourcemodel = rmfield(sourcemodel,'outside');
%     sourcemodel.inside      = sentcoh.inside;
%     sourcemodel.inside(:)   = false;
%     sourcemodel.inside(idx) = true;
    
    tmp           = zeros(sourcemodel.dim);  % full grid
    tmp(1:10,:,:) = 1;                       % index left with 1
    tmp(sourcemodel.outside) = nan;          % overwrite some of the 1's, and rest of brain with NaNs
    sourcemodel.inside = tmp(:);
    sourcemodel        = rmfield(sourcemodel,'outside');
    i = find(isnan(sourcemodel.inside));
    sourcemodel.inside(i) = false;
     
  end
  %% create data structure for statistics
  % left = left
  sourcemodel.avg.pow = sentcoh.avg.coh;

  source1{k}      = sourcemodel;
  source1{k}.pos  = sourcemodeltemplate.pos;

  % left = right
  source2{k}         = source1{k};
  source2{k}.avg.pow = flipsource;
  
  
  %% grp-average coherence
  tmp    = source1{k}.avg.pow - source2{k}.avg.pow;
  if k == 1
    cohavg = tmp;
  else
    cohavg = cohavg + tmp; 
  end
  cohavg   = cohavg/numel(subj);  
  
  grp = source1{1};
  grp.pow = cohavg;

end


%% statistics
nsubj  = numel(subj);
cfg    = [];
cfg.method           = 'montecarlo';
cfg.numrandomization = 2000;
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'cluster';
cfg.correcttail      = 'alpha';
cfg.ivar             = 1;
cfg.uvar             = 2;
cfg.design           = [ones(1,nsubj), ones(1,nsubj)*2; 1:nsubj 1:nsubj];
cfg.parameter        = 'avg.pow';
% cfg.statistic       5798/2 = 2899 = 'ft_statfun_signrankZ'; % double check name
stat = ft_sourcestatistics(cfg,source1{:},source2{:});

root = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
save([root,'stat_sourcelateralization_',frequency,'_',num2str(nsubj),'subj.mat'],'stat','grp')
%% plot
  cfg = [];
  cfg.method = 'ortho';
  cfg.funcolorlim = 'maxabs';
  cfg.funcolormap = 'jet';
  cfg.funparameter = 'stat';
  cfg.maskparameter = 'mask2';
  ft_sourceplot(cfg,stat); 
  
  cfg.method = 'slice';
  cfg.funparameter = 'pow';
  ft_sourceplot(cfg,grp);
  
