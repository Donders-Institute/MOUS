function [trc, trc_nooverlap, trcshuf, trcshuf_nooverlap] = mous_multisetcca_revision2_jon2(parcel_indx)

if nargin==0
  datadir = '/project/3011020.09/jansch/mscca_group/scenario1';
  d = dir(fullfile(datadir,'*checkoverlap.mat'));
  
  load atlas_conte69_8196reg_LR_brodmann_subparc.mat
  load cortex_inflated_8196reg.mat
  
  for k = 1:numel(d)
    parcel_indx(k,1) = str2num(d(k).name(18:20));
    load(fullfile(datadir,d(k).name), 'trc', 'trc_nooverlap', 'trcshuf_nooverlap', 'trcshuf');
    R1(:,k) = trc.rho(:,3);
    R2(:,k) = trc_nooverlap.rho(:,3);
    Rshuf(:,k,:) = trcshuf_nooverlap.rho;
    Rshuf1(:,k,:) = trcshuf.rho;
  end
  nrand = size(Rshuf1,3);
  
  indx = 1:386;
  indx([1 2 194 195]) = [];
  dat1 = zeros(386, numel(trc.time))+nan;
  dat2 = zeros(386, numel(trc.time))+nan;
  dat1shuf = zeros(386, numel(trc.time), nrand)+nan;
  dat2shuf = zeros(386, numel(trc.time), nrand)+nan;
  
  
  dat1(indx,:) = R1';
  dat2(indx,:) = R2';
  dat1shuf(indx,:,:) = permute(Rshuf1, [2 1 3]);
  dat2shuf(indx,:,:) = permute(Rshuf,  [2 1 3]);
  
  cfg     = [];
  cfg.dim = size(dat1);
  cfg.dimord = 'chan_time';
  cfg.numrandomization = nrand;

  cfg.connectivity = parcellation2connmat(atlas);
  cfg.tail = 1;
  cfg.clustertail = 1;
  cfg.clusterthreshold = 'nonparametric_individual';
  cfg.clusteralpha = 0.01;
  cfg.feedback   = 'text';
  cfg.clusterstatistic = 'maxsum';
  stat_nooverlap = clusterstat(cfg, reshape(dat2shuf,[],nrand), reshape(dat2,[],1));
  stat           = clusterstat(cfg, reshape(dat1shuf,[],nrand), reshape(dat1,[],1));
  
  figure;hold on;
  plot(trc.time, dat1, 'color', 'r');
  plot(trc.time, reshape(permute(dat1shuf(1:2:end,:,1:100:end),[1 3 2]),[],133), 'color', [0.6 0.6 0.6])
  
  
  dat1 = dat1.*double(reshape(stat.posclusterslabelmat, size(dat1))==1);
  dat2 = dat2.*double(reshape(stat_nooverlap.posclusterslabelmat, size(dat2))==1);
  
  datadir = '/project/3011020.09/jansch/mscca_group/scenario1';
  save(fullfile(datadir, 'stats_scenario1_trc_nooverlap'), 'stat', 'stat_nooverlap', 'dat1', 'dat2');
  
  atlas.pos             = sourcemodel.pnt;
  atlas.pos(4099:end,:) = atlas.pos(4099:end,:)*diag([-1 -1 1]);
  m1 = mean(atlas.pos(1:4098,:)); atlas.pos(1:4098,:) = atlas.pos(1:4098,:)-m1;
  m2 = mean(atlas.pos(4099:end,:)); atlas.pos(4099:end,:) = atlas.pos(4099:end,:)-m2;
  atlas.pos(1:4098,2) = atlas.pos(1:4098,2)+110;
  atlas.pos(4099:end,2) = atlas.pos(4099:end,2)-110;

  
  beg1 = nearest(trc.time, 0.38);
  end1 = nearest(trc.time, 0.42);
  
  figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat1(atlas.parcellation,beg1:end1),2));
  view([-90 0]);
  h1 = light('position',[-100 0 50]);
  h2 = light('position',[-100 0 -50]);
  lighting gouraud;material dull;
  set(gcf,'color','w');
  caxis([-0.002 0.025]);
  title('content words [0.38 0.42]');
  colorbar
  export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_cross_topo_orig.png' -png -m2;

  figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat2(atlas.parcellation,beg1:end1),2));
  view([-90 0]);
  h1 = light('position',[-100 0 50]);
  h2 = light('position',[-100 0 -50]);
  lighting gouraud;material dull;
  set(gcf,'color','w');
  caxis([-0.002 0.025]);
  title('content words [0.38 0.42], ''no-overlap'' model');
  colorbar
  export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_cross_topo_nooverlap.png' -png -m2;

  figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat2(atlas.parcellation,beg1:end1)-dat1(atlas.parcellation,beg1:end1),2));
  view([-90 0]);
  h1 = light('position',[-100 0 50]);
  h2 = light('position',[-100 0 -50]);
  lighting gouraud;material dull;
  set(gcf,'color','w');
  caxis([-0.01 0.01])
  title('difference between models');
  colorbar
  export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_cross_topo_delta.png' -png -m2;

else
  
  load mous_stimuli;
  load(sprintf('/project/3011020.09/jansch/mscca_group/scenario1/mscca_sce1_parcel%03d',parcel_indx));
  [tlck1] = mous_multisetcca_extractwords(comp, stimuli, [-.1 1]);
  
  [tlck, Trl_id,model_visual,model_audio] = mous_multisetcca_extractwords_nooverlap(comp, stimuli,[], [-.1 1]);
  
  % identify the nouns, adjectives and verbs
  sel =       double(strncmp(tlck.trialinfo.POS, 'N',   1))*1;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'WW',  2))*2;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'ADJ', 3))*3;
  
  cfg         = [];
  cfg.trials  = find(sel);
  tlck        = ft_selectdata(cfg, tlck);
  tlck1       = ft_selectdata(cfg, tlck1);
  
  % smooth data only once
  for m = 4:numel(tlck.label)
    tlck.trial(:,m,:) = ft_preproc_smooth(squeeze(tlck.trial(:,m,:)),5);
    tlck1.trial(:,m,:) = ft_preproc_smooth(squeeze(tlck1.trial(:,m,:)),5);
  end
  
  trc           = mous_multisetcca_trc(tlck1, stimuli);
  trc_nooverlap = mous_multisetcca_trc(tlck, stimuli);
  
  rng('default');
  tlckshuf = tlck;
  tlck1shuf = tlck1;
  trcshuf_nooverlap = trc_nooverlap;
  trcshuf_nooverlap.rho = trc_nooverlap.rho(:,3);
  trcshuf = trc;
  trcshuf.rho = trc.rho(:,3);
  
  nobs = size(tlck.trial,1);
  for k = 1:500
    for m = 4:numel(tlckshuf.label)
      indx = randperm(nobs);
      tlckshuf.trial(:,m,:)  = tlck.trial(indx,m,:);
      tlck1shuf.trial(:,m,:) = tlck1.trial(indx,m,:);
    end
    tmp = mous_multisetcca_trc(tlckshuf, stimuli);
    trcshuf_nooverlap.rho(:,k) = tmp.rho(:,3);
    tmp = mous_multisetcca_trc(tlck1shuf, stimuli);
    trcshuf.rho(:,k) = tmp.rho(:,3);
    
  end
  
  save(sprintf('/project/3011020.09/jansch/mscca_group/scenario1/mscca_sce1_parcel%03d_trc_checkoverlap',parcel_indx), 'trc', 'trc_nooverlap', 'trcshuf_nooverlap', 'trcshuf', 'model_audio', 'model_visual');
end
