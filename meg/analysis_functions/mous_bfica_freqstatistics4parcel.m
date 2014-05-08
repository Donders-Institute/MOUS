function [stat] = mous_bfica_freqstatistics4parcel(subjectnames,datatype,rootdir)

if nargin<3
  rootdir = '/project/3011020.09/MEG/';
end

% Statistical analyses on an AAL-parcellated 8mm grid
% input = freqstructure
% each parcel is treated as a ROI

% create structure for statistics
sent = cell(1,numel(subjectnames));
seq = cell(1,numel(subjectnames));
for k = 1:numel(subjectnames)
  mous_db_getdata(subjectnames{k},datatype,rootdir);
  sent{k} = tlcksent;
  seq{k}  = tlckseq;
end 

% subtract baseline
  
ix = find(sent{1}.time<=-0.1);  % baseline duration
for k = 1:numel(sent)
  tmp = sent{k}.powspctrm;
  bsl = nanmean(tmp(:,:,ix),3);
  sent{k}.powspctrm = tmp - repmat(bsl,[1,1,size(tmp,3)]); % subtract baseline (repmat)

  tmp = seq{k}.powspctrm;
  bsl = nanmean(tmp(:,:,ix),3);
  seq{k}.powspctrm = tmp - repmat(bsl,[1,1,size(tmp,3)]);
end


% parameters for stats calculation
Nsubj = numel(subjectnames);
cfg = [];
cfg.statistic = 'depsamplesT';
cfg.method = 'montecarlo';
cfg.clusterthreshold = 'parametric';
cfg.clusteralpha = 0.01;
% cfg.alpha = 0.05; % default
cfg.correctm = 'max';
cfg.numrandomization = 600;
              % conditionA  %conditionB      %subj   %subj
cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2; 1:Nsubj 1:Nsubj];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.parameter = 'powspctrm';
[stat] = ft_freqstatistics(cfg, sent{:},seq{:});

savedir = '/project/3011020.09/nielam/groupresults/bfica/visual/';
suff = 'explorationset';
save([savedir, datatype(11:end),'_',num2str(Nsubj),'subj',suff],'stat');

%% revert to sourcemodel for better visualisation
% load aal parcellated sourcemodel
load('/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm_parcellated_aal_sub');
aal = sourcemodel;

% load regular sourcemodel (3d8mm)
[p,n,e] = fileparts(which('mous_anatomy_sourcemodel3D'));
load([p(1:end-18),'templates/sourcemodel/standard_sourcemodel3d8mm']);

% load statistics
savedir = '/project/3011020.09/nielam/groupresults/bfica/visual/';
freq = 'low';
load([savedir,'sourcedatasentseq_',freq,'_parcelavg_30subjexplorationset']);

% create structure for ft_sourceplot
% all gridpoints belonging to the same parcel will have same TFR
sourcemodel.avg.pow = zeros(size(sourcemodel.pos,1),size(stat.stat,2),size(stat.stat,3));
for k = 1:numel(aal.tissuelabel)
  i = find(aal.tissue == k);
  for kk = 1:numel(i)
    sourcemodel.avg.pow(i(kk),:,:) = stat.stat(k,:,:);
  end
end
sourcemodel.freq = stat.freq;  % necessary field for ft_sourceplot to work
sourcemodel.time = stat.time;  % " 
sourcemodel.dimord = stat.dimord; % "
fields = {'xgrid','ygrid','zgrid','unit'};
sourcemodel = rmfield(sourcemodel,fields);

cfg2 = [];
cfg2.method = 'ortho';
cfg2.funcolorlim = 'maxabs';
cfg2.funparameter = 'avg.pow';
ft_sourceplot(cfg2,sourcemodel); colorbar;
%% plotting
% % k = check number corresponding to tissue label
% 
% % plot single subject TFR:
%   imagesc(source.time,source.freq,squeeze(tmpnew(k,:,:)));axis xy;
%   
% % plot sourcemodel aal template:
% load('/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm_parcellated_aal_sub');
% cfgp = [];
% cfgp.funparameter ='tissue';
% ft_sourceplot(cfgp,sourcemodel)
%   
% % plot stats
% figure;imagesc(stat.time,stat.freq,squeeze(stat.stat(k,:,:))); axis xy;

%% 
% subjexp
% subjectnames= {'V1003', 'V1007', 'V1010',...
%   'V1022', 'V1023', 'V1024', 'V1029',...
%   'V1033', 'V1042', 'V1044', 'V1046', 'V1049',...
%   'V1054', 'V1057',...
%   'V1061', 'V1065',...
%   'V1073', 'V1075', 'V1078',...
%   'V1080', 'V1083', 'V1084', 'V1086',...
%   'V1093', 'V1094', 'V1095', 'V1098',...
%   'V1101', 'V1103', 'V1106'};