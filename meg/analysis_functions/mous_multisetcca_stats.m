function [stats, T, Tshuf] = mous_multisetcca_stats(rootdir,scenario,varargin)

modality            = ft_getopt(varargin, 'modality', 'supramodal');
trcname             = ft_getopt(varargin, 'trcname', '');       %filename of the trc on original order
shufflefname        = ft_getopt(varargin, 'shufflefname', 'shuf2');%filename of the trc on shuffled order (can be shuf2 before mscca or after mscca)
shuffle             = ft_getopt(varargin, 'shuffle', 'trcshuf');   %variable name of the shuffled trc (post mscca can be trcshuf,trcshuf2,trcshuf3)
onesided            = ft_getopt(varargin, 'onesided', 1);
do_diff             = ft_getopt(varargin, 'do_diff', 0);
correction          = ft_getopt(varargin, 'correction','cluster');
if do_diff; shuffle   = [shuffle '_*'];  end

load atlas_conte69_8196reg_LR_brodmann_subparc.mat

% files may not be unambiguous if trcname = '';
trcfiles = fullfile(rootdir,sprintf('mscca_sce%d*%s.mat',scenario,trcname));
trcd     = dir(trcfiles);
if numel(trcd)>382
  ok = false(numel(trcd),1);
  for k = 1:numel(trcd)
    ok(k) = ~isempty(regexp(trcd(k).name, sprintf('mscca_sce%d_parcel[0-9][0-9][0-9]%s.mat',scenario,trcname)));
  end
  trcd = trcd(ok);
end

shufflefiles = fullfile(rootdir,sprintf('mscca_sce%d*%s.mat',scenario,shufflefname));
shuffled     = dir(shufflefiles);

switch modality
  case 'visual'
    moda = 1;
  case 'auditory'
    moda = 2;
  case 'supramodal'
    moda = 3;
end

pindx = 1:length(atlas.parcellationlabel);
pindx([1 2 194 195]) = []; %ignore medial wall parcels
for k = 1:numel(trcd)
  k
  
  if do_diff
    alltrc    = load(fullfile(rootdir,trcd(k).name),'trc_*');
    trcnames  = fieldnames(alltrc);
    trc       = alltrc.(trcnames{1});
    trc.rho   = alltrc.(trcnames{1}).rho - alltrc.(trcnames{2}).rho;
    allshuf   = load(fullfile(rootdir,shuffled(k).name),shuffle);
    shufnames = fieldnames(allshuf);
    shuf      = allshuf.(shufnames{1});
    shuf.rho  = allshuf.(shufnames{1}).rho - allshuf.(shufnames{2}).rho;
  else
    load(fullfile(rootdir,trcd(k).name),'trc');
    shuf = load(fullfile(rootdir,shuffled(k).name),shuffle);
    shuf = shuf.(shuffle);
  end
  
  n = 1:size(shuf.rho,3);
  
  indx = pindx(str2double(trcd(k).name(18:20)));
  T(indx,:) = trc.rho(:,moda);
  Tshuf(indx,:,n) = squeeze(shuf.rho(:,moda,:));
  if k==1,
    T(386,end)=0;
    Tshuf(386,end,end)=0;
  end
  tim = trc.time;
  
  clear trc shuf
end

cfg                  = [];
cfg.connectivity     = parcellation2connmat(atlas);
cfg.tail             = onesided;
cfg.clustertail      = onesided;
cfg.clusterthreshold = 'nonparametric_individual';
cfg.clusteralpha     = 0.01;
cfg.feedback         = 'text';
cfg.clusterstatistic = 'maxsum';

cfg.dim = size(Tshuf(:,:,1));
cfg.numrandomization = size(Tshuf,3);

T(T==0) = nan;
Tshuf(Tshuf==0) = nan;
statobs  = reshape(T,[],1);
statrand = reshape(Tshuf,[],size(Tshuf,3));

cfg     = [];
cfg.dim = size(Tshuf(:,:,1));
cfg.numrandomization = size(Tshuf,3);

switch correction
    case 'cluster'
        cfg.connectivity = parcellation2connmat(atlas);
        cfg.tail = onesided;
        cfg.clustertail = onesided;
        cfg.clusterthreshold = 'nonparametric_individual';
        cfg.clusteralpha=0.01;
        cfg.feedback = 'text';
        cfg.clusterstatistic = 'maxsum';
        
        stats = clusterstat(cfg, statrand, statobs);
        fn = fieldnames(stats);
        for k = 1:numel(fn)
            try
                stats.(fn{k}) = reshape(stats.(fn{k}),cfg.dim);
            end
        end
    case 'max'   
        cfg.correctm = 'max';
        
        prb_pos   = zeros(size(statobs));
        for i=1:size(Tshuf,3)
                % compare each data element with the maximum statistic
                prb_pos = prb_pos + (statobs<max(statrand(:,i)));
                posdistribution(i) = max(statrand(:,i));
        end
        stats.prob = prb_pos./size(Tshuf,3);
        stats.prob = reshape(stats.prob,cfg.dim);
        stats.mask = stats.prob<=0.05;
        stats.posdistribution = posdistribution;
end
stats.time = tim;
stats.dimord = 'chan_time';
stats.label  = atlas.parcellationlabel;
stats.stat   = T;
stats.stat(~isfinite(stats.stat)) = 0; stats.stat([1 2 194 195],:) = nan;
stats.brainordinate = atlas;

