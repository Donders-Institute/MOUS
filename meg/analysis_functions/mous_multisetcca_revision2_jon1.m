function [trc, trc_all] = mous_multisetcca_revision2_jon1(parcel_indx)

if nargin==0

datadir = '/project/3011020.09/jansch/mscca_group/scenario1';
d = dir(fullfile(datadir,'*sentenceonset*'));

for k = 1:numel(d)
  parcel_indx(k,1) = str2num(d(k).name(18:20));
  load(fullfile(datadir,d(k).name), 'trc', 'trc_all');
  R(:,k) = trc.rho(:,2);
  Rall(:,k) = trc_all.rho(:,2);
  
end
indx = 1:386;
indx([1 2 192 193 194 195 385 386]) = [];
dat_onset = zeros(386, numel(trc.time));
dat_long  = zeros(386, numel(trc_all.time));
 
dat_onset(indx,:) = R';
dat_long(indx,:)  = Rall';


load atlas_conte69_8196reg_LR_brodmann_subparc.mat
load cortex_inflated_8196reg.mat
atlas.pos             = sourcemodel.pnt;
atlas.pos(4099:end,:) = atlas.pos(4099:end,:)*diag([-1 -1 1]);
m1 = mean(atlas.pos(1:4098,:)); atlas.pos(1:4098,:) = atlas.pos(1:4098,:)-m1;
m2 = mean(atlas.pos(4099:end,:)); atlas.pos(4099:end,:) = atlas.pos(4099:end,:)-m2;
atlas.pos(1:4098,2) = atlas.pos(1:4098,2)+110;
atlas.pos(4099:end,2) = atlas.pos(4099:end,2)-110;

figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat_long(atlas.parcellation,:),2), 'contour', ismember(atlas.parcellation, [95 96]))
view([-90 0]); 
h1 = light('position',[-100 0 50]); 
h2 = light('position',[-100 0 -50]);
lighting gouraud;material dull;
set(gcf,'color','w');
caxis([-0.07 0.07]);
title('average correlation [-1 2] content words');
colorbar

addpath('~/matlab/toolboxes/export_fig/');
export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_aud_topo_long.png' -png -m2;

figure;ft_plot_mesh(atlas,'vertexcolor',nanmean(dat_onset(atlas.parcellation,1:121),2))
view([-90 0]); 
h1 = light('position',[-100 0 50]); 
h2 = light('position',[-100 0 -50]);
lighting gouraud;material dull;
set(gcf,'color','w');
caxis([-0.007 0.007]);
title('average correlation [-0.5 0] sentence onset words');
colorbar
export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_aud_topo_onset.png' -png -m2;

figure; plot(trc.time, ft_preproc_smooth(mean(dat_long(95:96,:)),10), 'k', 'linewidth', 2);
xlim([-1 2]);
xlabel('time (s)');
ylabel('aud-aud correlation');
ylim([-0.01 0.1]);
set(gca, 'tickdir', 'out');
set(gcf, 'color', 'w');
export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_aud_timecourse_long.png' -png -m2;

figure; plot(trc.time, ft_preproc_smooth(mean(dat_onset(95:96,:)),10), 'k', 'linewidth', 2);
xlim([-0.5 1.2]);
xlabel('time (s)');
ylabel('aud-aud correlation');
ylim([-0.01 0.1]);
set(gca, 'tickdir', 'out');
set(gcf, 'color', 'w');
export_fig '/project/3011020.09/jansch/mscca_group/scenario1/corr_aud_timecourse_onset.png' -png -m2;


  
else
  

% mous_multisetcca_revision2_jon1 tries to do analysis to address reviewer
% 1's comment with respect to the bias in the trc for the auditory subject
% pairs. In order to argue that we think that this is caused by the
% continuous nature of the acoustic stimulation, causing shared variance
% across auditory subjects, which is not necessary locked to the perceived
% word onsets, we'd need to show that the trc goes down overall prior to
% the sentence onset. To this end, we need to re-compile the 'comp'
% structure including a longer pre-sentence window (in the stored analysis
% results the minimum time was -0.1). This function collects the single
% subject data that went into the mcca analysis, but pertaining the -0.5-0
% window pre sentence. Next, using the stored unmixing weights, the
% parcel-level component data are restored, and the trc is computed, using
% a longer latency, on all words, and using only the first words in the
% sentence.


load mous_stimuli;
nfold = 5;
suffix = '';
subj = {'A2006'
    'A2007'
    'A2009'
    'A2013'
    'A2019'
    'A2025'
    'A2037'
    'A2049'
    'A2055'
    'A2061'
    'A2065'
    'A2067'
    'A2079'
    'A2085'
    'A2091'
    'A2097'
    'V1001'
    'V1013'
    'V1019'
    'V1025'
    'V1031'
    'V1049'
    'V1055'
    'V1061'
    'V1073'
    'V1079'
    'V1085'
    'V1097'
    'V1100'
    'V1103'
    'V1105'
    'V1109'
    'V1116'};
  
groupdata     = cell(numel(suffix),numel(subj));
subjectdata   = cell(numel(suffix),numel(subj));
subjecttiming = cell(numel(suffix),numel(subj));
for k = 1:numel(subj)
  
  % load in the data
  mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data%s',       suffix));
  mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s', suffix));
  mous_db_getdata(subj{k}, sprintf('meg_multisetcca_lcmv_parc%s',  suffix));
  groupinfo{1} = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo%s',suffix));
  
  source_parc.filterlabel = filterlabel; % for checking channel order
  
  % convert the sensor-level data into  parcel-level data, for the
  % requested
  subjectdata{1,k}   = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
  subjecttiming{1,k} = timinginfo; % subject specific information about timing
  
  if strncmp(subj{k}, 'A', 1)
    % align the trials' time axes to the onset of the first word, rather
    % than the onset of the audio file
    tmp = subjectdata{1,k}.time;
    stim_id = subjectdata{1,k}.trialinfo(:,end);
    for kk = 1:numel(tmp)
      tmp{kk} = tmp{kk}-stimuli(stim_id(kk)).timinginfo(1,2);
      tmp{kk} = tmp{kk}-tmp{kk}(nearest(tmp{kk},0)); % include 0 explicitly
    end
    subjectdata{1,k}.time = tmp;
  end
  for kk = 1:numel(subjectdata{1,k}.trial)
    tmp = subjectdata{1,k}.trial{kk};
    tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
    subjectdata{1,k}.trial{kk} = tmp;
  end
  
  
  % align the subject-specific parcel data to match all others subjects
  % in terms of timing and trial-order
  groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{1,k}, subjecttiming{1,k}, groupinfo{1}, 0, 1);
    
  cfg            = [];
  cfg.method     = 'acrosschannel';
  groupdata{1,k} = ft_channelnormalise(cfg, groupdata{1,k});
  %for kk = 1:numel(groupdata{1,k}.trial)
  %  sel = nearest(groupdata{1,k}.time{kk},-0.1);
  %  groupdata{1,k}.trial{kk} = groupdata{1,k}.trial{kk}(:,sel:end);
  %  groupdata{1,k}.time{kk}  = groupdata{1,k}.time{kk}(sel:end);
  %end
end
% in the stored results the order seems to be visual first, then auditory.
groupdata = groupdata([find(strncmp(subj(:)','V',1)) find(strncmp(subj(:)','A',1))]);

tmpdata = mous_multisetcca_groupdata2singlestruct(groupdata(1,:), subj); % first row only
results = load(sprintf('/project/3011020.09/jansch/mscca_group/scenario1/mscca_sce1_parcel%03d',parcel_indx));

nobs  = numel(tmpdata.trial);
ix    = round(linspace(0,nobs,nfold+1));

% reorder the sentences to match the computed comp output, so that we have
% the folds together
reorder = zeros(nobs,1);
for k = 1:nobs
  reorder(k,1) = find(tmpdata.trialinfo(:,end)==results.comp.trialinfo(k,end));
end
tmpdata.trial     = tmpdata.trial(reorder);
tmpdata.time      = tmpdata.time(reorder);
tmpdata.trialinfo = tmpdata.trialinfo(reorder,:);
assert(isequal(results.comp.trialinfo(:,end),tmpdata.trialinfo(:,end)));
for k = 1:nfold
  for m = 1:numel(subj)
    this_w(m, (m-1)*5 + (1:5)) = results.W(1,:,m,k);
  end
  idx = (ix(k)+1):ix(k+1);
  for m = idx(:)'
    tmp = tmpdata.trial{m};
    notfinite = ~isfinite(tmp(1:5:end,:));
    tmp(~isfinite(tmp)) = 0;
    trial{1,m} = this_w*tmp;
    trial{1,m}(notfinite) = nan;
  end
end
comp       = results.comp;
comp.trial = trial;
comp.time  = tmpdata.time;

tlck        = mous_multisetcca_extractwords(comp, stimuli,[-1 2]);
cfgx.trials = find(tlck.trialinfo.index==1);

trc_all = mous_multisetcca_trc(tlck, stimuli, 'dosmooth', 5, 'contentwords_only', true);
trc     = mous_multisetcca_trc(ft_selectdata(cfgx, rmfield(tlck, 'trialinfo')), stimuli, 'dosmooth', 5);
save(sprintf('/project/3011020.09/jansch/mscca_group/scenario1/mscca_sce1_parcel%03d_trc_sentenceonset',parcel_indx), 'trc', 'trc_all');

end


