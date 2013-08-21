function mous_corrmnebf_selstatclus(nclust,stat,value,title)

if strcmp(value,'pos')
    selclust = stat.posclusterslabelmat==nclust;
else   % negative cluster
    selclust = stat.negclusterslabelmat==nclust;
end
stat.mask = selclust;

imask = mous_bfica_sourceinterpolate(stat, 'mask', stat.inside);

cfg = [];
cfg.method       = 'slice';  %ortho
cfg.funparameter = 'avg.pow';
%cfg.atlas='/home/common/matlab/fieldtrip/template/atlas/afni/TTatlas+tlrc.BRIK';
cfg.title = title;
ft_sourceplot(cfg,imask);