function [stats, T, Tshuf] = mous_multisetcca_stats(rootdir,scenario,varargin)

modality            = ft_getopt(varargin, 'modality', 'supramodal');
trcname             = ft_getopt(varargin, 'trcname', '');       %filename of the trc on original order
shufflefname        = ft_getopt(varargin, 'shufflefname', 'shuf2');%filename of the trc on shuffled order (can be shuf2 before mscca or after mscca)
shuffle             = ft_getopt(varargin, 'shuffle', 'trcshuf');   %variable name of the shuffled trc (pre mscca:trcshuf, post pscca: trcshuf2)
onesided            = ft_getopt(varargin, 'onesided', 1);

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
  
    load(fullfile(rootdir,trcd(k).name),'trc');
    shuf = load(fullfile(rootdir,shuffled(k).name),shuffle);
    shuf = shuf.(shuffle);
    n = 1:size(shuf.rho,3);
    
    if size(trc.rho,2) > 3
        %in case average have not been computed yet eg when running
        %mous_multisetcca_trc with option 'single_cross'
        trc.rho = nanmean(trc.rho)';
        shuf.rho = squeeze(nanmean(shuf.rho));
    else
        trc.rho = trc.rho(:,moda);
        shuf.rho = squeeze(shuf.rho(:,moda,:));
    end
    
    indx = pindx(str2double(trcd(k).name(18:20)));
    T(indx,:) = trc.rho;
    Tshuf(indx,:,n) = shuf.rho;
    if k==1,
        T(386,end)=0;
        Tshuf(386,end,end)=0;
    end
    
    
    tim = trc.time;
    clear trc shuf
end

T(T==0) = nan;
Tshuf(Tshuf==0) = nan;
statobs  = reshape(T,[],1);
statrand = reshape(Tshuf,[],size(Tshuf,3));

cfg                  = [];
cfg.connectivity     = parcellation2connmat(atlas);
cfg.tail             = onesided;
cfg.clustertail      = onesided;
cfg.clusterthreshold = 'nonparametric_individual';
cfg.clusteralpha     = 0.01;
cfg.feedback         = 'text';
cfg.clusterstatistic = 'maxsum';
cfg.dim              = size(Tshuf(:,:,1));
cfg.numrandomization = size(Tshuf,3);

stats = clusterstat(cfg, statrand, statobs);
fn = fieldnames(stats);
for k = 1:numel(fn)
    try
        stats.(fn{k}) = reshape(stats.(fn{k}),cfg.dim);
    end
end

stats.time = tim;
stats.dimord = 'chan_time';
stats.label  = atlas.parcellationlabel;
stats.stat   = T;
stats.stat(~isfinite(stats.stat)) = 0; stats.stat([1 2 194 195],:) = nan;
stats.brainordinate = atlas;

