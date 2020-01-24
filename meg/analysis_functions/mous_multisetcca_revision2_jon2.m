function [trc, trc_nooverlap] = mous_multisetcca_revision2_jon2(parcel_indx)

if nargin==0
  datadir = '/project/3011020.09/jansch/mscca_group/scenario1';
  d = dir(fullfile(datadir,'*overlap*'));
  
  for k = 1:numel(d)
    parcel_indx(k,1) = str2num(d(k).name(18:20));
    load(fullfile(datadir,d(k).name), 'trc', 'trc_nooverlap');
    R1(:,k) = mean(trc.rho)';
    R2(:,k) = mean(trc_nooverlap.rho)';
  end
  
  indx = 1:386;
  indx([1 2 194 195]) = [];
  dat1 = zeros(386, numel(trc.time));
  dat2 = zeros(386, numel(trc.time));
  
  dat1(indx,:) = R1';
  dat2(indx,:) = R2';
  
  
  load atlas_conte69_8196reg_LR_brodmann_subparc.mat
  load cortex_inflated_8196reg.mat
  atlas.pos             = sourcemodel.pnt;
  atlas.pos(4099:end,:) = atlas.pos(4099:end,:)*diag([-1 -1 1]);
  m1 = mean(atlas.pos(1:4098,:)); atlas.pos(1:4098,:) = atlas.pos(1:4098,:)-m1;
  m2 = mean(atlas.pos(4099:end,:)); atlas.pos(4099:end,:) = atlas.pos(4099:end,:)-m2;
  atlas.pos(1:4098,2) = atlas.pos(1:4098,2)+110;
  atlas.pos(4099:end,2) = atlas.pos(4099:end,2)-110;

  
  beg1 = nearest(trc.time, 0.32);
  end1 = nearest(trc.time, 0.48);
  
  figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat1(atlas.parcellation,beg1:end1),2));
  view([-90 0]);
  h1 = light('position',[-100 0 50]);
  h2 = light('position',[-100 0 -50]);
  lighting gouraud;material dull;
  set(gcf,'color','w');
  caxis([-0.002 0.012]);
  title('content words [0.32 0.48]');
  colorbar
  export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_cross_topo_orig.png' -png -m2;

  figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat2(atlas.parcellation,beg1:end1),2));
  view([-90 0]);
  h1 = light('position',[-100 0 50]);
  h2 = light('position',[-100 0 -50]);
  lighting gouraud;material dull;
  set(gcf,'color','w');
  caxis([-0.002 0.012]);
  title('content words [0.32 0.48], ''no-overlap'' model');
  colorbar
  export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_cross_topo_nooverlap.png' -png -m2;

  figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat2(atlas.parcellation,beg1:end1)-dat1(atlas.parcellation,beg1:end1),2));
  view([-90 0]);
  h1 = light('position',[-100 0 50]);
  h2 = light('position',[-100 0 -50]);
  lighting gouraud;material dull;
  set(gcf,'color','w');
  caxis([-0.005 0.005])
  title('difference between models');
  colorbar
  export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_cross_topo_delta.png' -png -m2;

else
  
  load mous_stimuli;
  load(sprintf('/project/3011020.09/jansch/mscca_group/scenario1/mscca_sce1_parcel%03d',parcel_indx));
  [tlck] = mous_multisetcca_extractwords(comp, stimuli, [-.1 1]);
  trc = mous_multisetcca_trc(tlck, stimuli, 'dosmooth', 5, 'contentwords_only',true,'output2','single_cross');
  
  [tlck, Trl_id,model_visual,model_audio] = mous_multisetcca_extractwords_nooverlap(comp, stimuli,[], [-.1 1]);
  trc_nooverlap = mous_multisetcca_trc(tlck, stimuli, 'dosmooth', 5, 'contentwords_only',true,'output2','single_cross');
  
  % identify the nouns, adjectives and verbs
  sel =       double(strncmp(tlck.trialinfo.POS, 'N',   1))*1;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'WW',  2))*2;
  sel = sel + double(strncmp(tlck.trialinfo.POS, 'ADJ', 3))*3;
  
  cfg         = [];
  cfg.trials  = find(sel);
  tlck        = ft_selectdata(cfg, tlck);

  % smooth data only once
  for m = 4:numel(tlck.label)
    tlck.trial(:,m,:) = ft_preproc_smooth(squeeze(tlck.trial(:,m,:)),5);
  end
  
  trc_nooverlap = mous_multisetcca_trc(tlck, stimuli, 'contentwords_only',true);
  
  rng('default');
  tlckshuf = tlck;
  trcshuf_nooverlap = trc_nooverlap;
  trcshuf_nooverlap.rho = trc_nooverlap.rho(:,2);
  
  
  nobs = size(tlck.trial,1);
  for k = 1:250
    for m = 4:numel(tlckshuf.label)
      tlckshuf.trial(:,m,:) = tlck.trial(randperm(nobs),m,:);
    end
    tmp = mous_multisetcca_trc(tlckshuf, stimuli, 'contentcwords_only', true, 'output2', 'single_cross');
    trcshuf_nooverlap.rho(:,k) = tmp.rho(:,2);
  end
  
  
  
  save(sprintf('/project/3011020.09/jansch/mscca_group/scenario1/mscca_sce1_parcel%03d_trc_checkoverlap',parcel_indx), 'trc', 'trc_nooverlap', 'model_audio', 'model_visual');
end
