% This script generates the figures for the supramodal MOUS project

%% Load atlas and sourcemodel
load atlas_conte69_8196reg_LR_brodmann_subparc.mat
load cortex_inflated_8196reg.mat
atlas.pos = sourcemodel.pnt;
atlas_orig = atlas;
%separate sourcemodel positions singl, both, right & left
n = 4098;
posAll = atlas.pos;
posAll(1:n,2) = posAll(1:n,2)+220;
posAll(1:n,1:2) = -posAll(1:n,1:2);
posAll(1:n,1) = posAll(1:n,1)-25;
posmedial = posAll;
posmedial(1:n,2) = posmedial(1:n,2)+450;
posright = posAll;
posright(1:n,:) = NaN;
posrightm = posmedial;
posrightm(1:n,:) = NaN;
posleft = posAll;
posleft(n+1:end,:) = NaN;
posleftm = posmedial;
posleftm(n+1:end,:) = NaN;

%% Colormaps
ft_hastoolbox('brewermap',1);
n = 90;
cmap1 = permute(repmat(brewermap(n, 'Blues'),  [1 1 n]),[1 3 2]);
cmap1 = cmap1(1:64,1:64,:);
cmap2 = permute(repmat(brewermap(n, 'Greens'),  [1 1 n]),[3 1 2]);
cmap2 = cmap2(1:64,1:64,:);
map2D  = cmap1.*cmap2;
figure;image(map2D);axis xy
set(gca,'XTick',[0.5 32.5 64.5])
set(gca,'XTickLabel',[0 0.5 1])
set(gca,'YTick',[32.5 64.5])
set(gca,'YTickLabel',[0.5 1])
set(gca,'Color','None')
box off
save('/project/3011020.09/sopara/figures/final/colorbar_sensory','map2D')
export_fig('/project/3011020.09/sopara/figures/final/fig0/colorbar_sensory','-eps');

% create the 'upsampling matrix', to map parcels onto the vertices of the
% cortical sheet
x = zeros(0,1);
y = zeros(0,1);
for k = 1:numel(atlas.parcellationlabel)
    sel = atlas.parcellation==k;
    x = cat(1,x(:),find(sel));
    y = cat(1,y(:),ones(sum(sel),1)*k);
end
P = sparse(x,y,ones(numel(x),1),size(atlas.pos,1),numel(atlas.parcellationlabel));
save('/project/3011020.09/sopara/figures/final/parcel2vertices','P')

%%get colorbar
cmap = brewermap(63,'Reds');
rgb=bg_rgba2rgb([199 194 169]/255,linspace(0,0.015,30),cmap,[0 0.015],[linspace(0,1,10) ones(1,20)],'rampup',[0 1]);
figure;image(rgb);
set(gca,'tickdir','out');
set(gca,'xticklabel',(1:6).*(0.015./6));
export_fig('/project/3011020.09/sopara/figures/final/fig1/colorbar_crossmod','-eps');

%colorbar
cmap = brewermap(63,'Blues');
figure;
rgbplot(cmap)
hold on
colormap(cmap)
ax = gca;
ax.CLim = [0.4 0.56];
colorbar('Ticks',[0.4 0.46 0.5 0.56])
export_fig('/project/3011020.09/sopara/figures/final/fig3/colorbar_gamma','-eps');

%% Figure 0A: Sensory maps
clearvars -except atlas posAll posright posleft posmedial;clc
load('/project/3011020.09/sopara/figures/final/colorbar_sensory','map2D')
load('/project/3011020.09/sopara/figures/final/parcel2vertices','P')
twin  = [0.15 0.2]; % time window to average over
%load data
scenario = 1;
trcname = '';
datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
%Compute correlations (this will also do cluster permutation test, which is
%not necessary)
[s, T, Tshuf] = mous_multisetcca_stats(datadir,scenario,'trcname', trcname,'modality','visual');
Tvis = T;
[s, T, Tshuf] = mous_multisetcca_stats(datadir,scenario,'trcname', trcname,'modality','auditory');
Taud = T;

i1 = nearest(s.time,twin(1));
i2 = nearest(s.time,twin(2));

Tv = Tvis(:,i1:i2);
Tv= Tv./max(Tv(:));
Tv(Tv<0)=0;
Tv(~isfinite(Tv)) = 0;
Tv = ceil(Tv.*(64-1))+1;
Tv = double(Tv);
Ta = Taud(:,i1:i2);
Ta= Ta./max(Ta(:));
Ta(Ta<0)=0;
Ta(~isfinite(Ta)) = 0;
Ta = ceil(Ta.*(64-1))+1;
Ta = double(Ta);

indx1 = round(nanmean(Ta,2));
indx2 = round(nanmean(Tv,2));
cdat = nan+zeros(386,3);
for k = 1:numel(indx1)
    if indx2(k)>0 && isfinite(indx1(k))
        cdat(k,1:3) = squeeze(map2D(indx1(k),indx2(k),:));
    else
        cdat(k,1:3) = 0;
    end
end
% this function is in fieldtrip/plotting/private
atlas.pos = posAll; 
%lateral view
figure('position',[1 1 900 900]);
ft_plot_mesh(atlas,'facecolor', 'cortex','edgecolor','none','vertexcolor',P*cdat);
lighting gouraud;
material dull;
view([90 0]);
h=light('position',[10 0 0]);
set(gcf,'color','w')
title(sprintf('time = %d-%d',round(1000.*s.time(i1)),round(1000.*s.time(i2))),'position',[33 -104 100]);
fname = strcat('/project/3011020.09/sopara/figures/final/fig0/',sprintf('sensory_time%d2',i1));
export_fig(fname,'-png','-transparent','-m5');
%medial view
atlas.pos = posmedial; 
mask = zeros(1,386);
mask(175) = 1;
figure('position',[1 1 900 900]);
ft_plot_mesh(atlas,'facecolor', 'cortex','edgecolor','none','vertexcolor',P*cdat,'contour',P*mask','contourlinewidth',2);
lighting gouraud;
material dull;
view([-90 0]);
h=light('position',[-10 0 0]);
set(gcf,'color','w')
title(sprintf('time = %d-%d',round(1000.*s.time(i1)),round(1000.*s.time(i2))),'position',[33 -104 100]);
fname = strcat('/project/3011020.09/sopara/figures/final/fig0/',sprintf('sensory_time%d_medial',i1));
export_fig(fname,'-png','-transparent','-m5');

%% Figure 0B: Time course for parcel
clearvars -except atlas posAll posright posleft posleftm;clc
load('/project/3011020.09/sopara/figures/final/colorbar_sensory','map2D')

scenario = 1;
parcel_indx = 95; % run this part for each parcel (175 BA17 visual, 95 BA43 auditory)
filename = sprintf('/project/3011020.09/sopara/figures/final/fig0/trcdata_parcel%03d',parcel_indx);
load(strcat(filename,'_trc'),'trc','trcshuf2')

if isfile(filename)
    load(filename);
else
if exist('scenario', 'var')
  subj = mous_db_getfilename('allAV', 'subjectname');
  sce  = mous_db_getfilename(subj,    'scenario');
  sel  = false(numel(subj,1));
  for m = 1:numel(scenario)
    sel = strncmp(sce, num2str(scenario(m)), 1) | sel;
  end
  subj = subj(sel);
  sce  = sce(sel);
end
shift   = zeros(1,numel(subj));
stretch = ones(1,numel(subj));
for k = 1:numel(subj)
    % load in the data
    load mous_stimuli
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_data%s', ''));
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_timinginfo%s',''));
    mous_db_getdata(subj{k}, sprintf('meg_multisetcca_lcmv_parc%s',  ''));
    groupinfo = mous_db_getdata(subj{k}, sprintf('meg_multisetcca_groupinfo%s',''));
    source_parc.filterlabel = filterlabel; % for checking channel order
    subjectdata{k} = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
    subjecttiming{k} = timinginfo; % subject specific information about timing
    if strncmp(subj{k}, 'A', 1)
        tmp = subjectdata{k}.time;
        stim_id = subjectdata{k}.trialinfo(:,end);
        for kk = 1:numel(tmp)
            tmp{kk} = tmp{kk}-stimuli(stim_id(kk)).timinginfo(1,2);
            tmp{kk} = tmp{kk}-tmp{kk}(nearest(tmp{kk},0)); % include 0 explicitly
        end
        subjectdata{k}.time = tmp;
    end
    for kk = 1:numel(subjectdata{k}.trial)
        tmp = subjectdata{k}.trial{kk};
        tmp = tmp - nanmean(tmp,2)*ones(1,size(tmp,2));
        subjectdata{k}.trial{kk} = tmp;
    end
    groupdata{k} = mous_multisetcca_getparceldata(subj{k}, subjectdata{k}, subjecttiming{k}, groupinfo, shift(k), stretch(k));%,true);
    
    cfg            = [];
    cfg.method     = 'acrosschannel';
    groupdata{k} = ft_channelnormalise(cfg, groupdata{k});
    for kk = 1:numel(groupdata{k}.trial)
        sel = nearest(groupdata{k}.time{kk},-0.1);
        groupdata{k}.trial{kk} = groupdata{k}.trial{kk}(:,sel:end);
        groupdata{k}.time{kk}  = groupdata{k}.time{kk}(sel:end);
    end
end
tmpdata              = mous_multisetcca_groupdata2singlestruct(groupdata(1,:), subj); % first row only
for i = 1:length(tmpdata.trial)
    tmpdata.trial{i} = tmpdata.trial{i}(1:5:165,:);
end
tmpdata.label = tmpdata.label(1:5:165);
trc_pre       = mous_multisetcca_trc(tmpdata, stimuli);
save(sprintf('/project/3011020.09/sopara/figures/final/fig0/trcdata_parcel%03d',parcel_indx), 'trc_pre', 'trc', 'trcshuf2');
end

%Plot
twin  = [0.15 0.2]; % time window for sensory maps average
timsel= [-0.1 0.8];
n1 = nearest(trc.time,timsel(1));
n2 = nearest(trc.time,timsel(2));
figure;hold on
p1 = plot(trc.time(n1:n2),squeeze(trcshuf2.rho((n1:n2),2,:)),'Linewidth',1,'Color',[0 0 0]+0.7);
p2 = plot(trc.time(n1:n2),squeeze(trc.rho((n1:n2),2)),'Linewidth',3,'Color',map2D(40,50,:));
p3 = plot(trc_pre.time(n1:n2),squeeze(trc_pre.rho((n1:n2),2)),'Linewidth',3,'Color',[0 0 0]+0.5);
ax = gca(); % this Gets the Current Axis so we can set properties
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
ax.TickDir = 'out';
ylim([-0.025 0.05])
xlim(timsel)
patch( [twin(1) twin(1), twin(2) twin(2)],[min(ylim) max(ylim) max(ylim) min(ylim)], [0 0 0],'LineStyle','none')
alpha(0.1)
% Remove the box around the plot, while we're at it:
box off;
set(ax ,'Layer', 'Top')
yticks([-0.02 0.02 0.04])
xticks([0.15 0.3 0.6])
set(gca,'xticklabel',[])
export_fig(sprintf('/project/3011020.09/sopara/figures/final/fig0/parcel%03d_timecourse',parcel_indx),'-eps','-transparent');

%% Figure 1: Cluster-corrected permutation results for scenario 1
clearvars -except atlas posAll posright posleft posleftm;clc
cmap = brewermap(63,'Reds');

scenario = 1;
cluster = 1;

%load data
datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
outdir = sprintf('/project/3011020.09/sopara/figures/final');
load(fullfile(datadir, sprintf('scenario%d_results',scenario)))

%create source structure for plotting
source                = [];
source.brainordinate  = atlas;
source.brainordinate.pos = posleft;
source.label          = atlas.parcellationlabel;
source.time           = s.time;
source.dimord         = 'chan_time';
source.pow            = T;
source.mask           = double(s.posclusterslabelmat==cluster);

xs = source;
xs = ft_checkdata(xs,'datatype','source');

%find where first cluster begins and plot from there to end
[~, firstcol] = find(s.posclusterslabelmat==cluster,1);
[~, lastcol] = find(s.posclusterslabelmat==cluster,1,'last');

splot = xs;
figure('position',[1 1 900 900]);
for k = firstcol:1:lastcol
    splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
    splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
    ft_plot_mesh(splot,'edgecolor','none','vertexcolor',splot.pow,'facealpha', splot.mask, 'clim', [0 0.015], 'alphalim', [0 0.005], 'alphamap', 'rampup', 'colormap', cmap, 'maskstyle', 'colormix');
    lighting gouraud;material dull;view([90 0]);h=light('position',[10 0 0]);
    set(gcf,'color','w');
    title(sprintf('time = %d',round(1000.*s.time(k))),'position',[33 -204 100]);
    fname = strcat(outdir,sprintf('/fig1/crossmod_sce%d_timestamp%03d_trc_cluster%d',scenario,k,cluster));
    export_fig(fname,'-png','-transparent','-m5');
    clf;
end
% Plot medial view
source.brainordinate.pos = posleftm;
xs = source;
xs = ft_checkdata(xs,'datatype','source');
splot = xs;
figure('position',[1 1 900 900]);
for k = 43:1:68
    splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
    splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
    ft_plot_mesh(splot,'edgecolor','none','vertexcolor',splot.pow,'facealpha', splot.mask, 'clim', [0 0.015], 'alphalim', [0 0.005], 'alphamap', 'rampup', 'colormap', cmap, 'maskstyle', 'colormix');
    lighting gouraud;material dull;view([-90 -20]);h=light('position',[-10 0 0]);
    set(gcf,'color','w');
    title(sprintf('time = %d',round(1000.*s.time(k))),'position',[33 204 100]);
    fname = strcat(outdir,sprintf('/fig1/crossmod_sce%d_timestamp%03d_trc_cluster%d_medialview',scenario,k,cluster));
    export_fig(fname,'-png','-transparent','-m5');
    clf;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Figure 2
clearvars -except atlas posAll posright posleft posmedial;clc
cmap = brewermap(63,'Reds');
%load data
load('/project/3011020.09/jansch/mscca_group/allscenarios_results_supra_Tclustermask.mat')
load(fullfile('/project/3011020.09/sopara/prevalence/12-Nov-2018.mat'), 'time', 'mT','results','params');
datadir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',1);
%get cluster-based stats for masking prevalence stats
load(fullfile(datadir, sprintf('scenario%d_results',1)),'s')
mask = double(s.posclusterslabelmat==1);
load(fullfile(datadir, sprintf('scenario%d_max_results',1)),'s');
time = s.time; clear s

%create source structure for plotting
source                = [];
source.brainordinate  = atlas;
source.brainordinate.pos = posleft;
source.label          = atlas.parcellationlabel;
source.time           = time;
source.dimord         = 'chan_time';
source.pow            = meanT;%results.aTypical;%Tmap%squeeze(nanmean(allT));%mT;
source.mask           = double(mask | results.pcMN < 0.05);
source.mask2          = double(results.pcMN < 0.05);

xs = source;
xs = ft_checkdata(xs,'datatype','source');

%find where first cluster begins and plot from there to end
[~, firstcol]   = find(source.mask2,1);
[~, lastcol]    = find(source.mask2,1,'last');

splot = xs;
figure('position',[1 1 900 900]);
for k = firstcol:1:lastcol
    splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
    splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
    splot.mask2 = xs.mask2(:,k); splot.mask2(~isfinite(splot.mask2))=0;
    ft_plot_mesh(splot,'vertexcolor',splot.pow, ...
        'clim', [0 0.015], ...
        'facealpha', splot.mask, ...
        'colormap',cmap, ...
        'maskstyle', 'colormix',...
        'contour',splot.mask2);
    lighting gouraud;
    material dull;
    view([90 0]);
    h=light('position',[10 0 0]);
    title(sprintf('time = %d',round(1000.*time(k))),'position',[33 -204 100]);
    set(gcf,'color','w');
    fname = strcat('/project/3011020.09/sopara/prevalence/',sprintf('/crossmod_timestamp%03d_mean_pcMN',k));
    export_fig(fname,'-png','-transparent','-m5');
    clf;
end

% Plot medial view
figure('position',[1 1 900 900]);
for k = firstcol:1:lastcol
    splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
    splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
    splot.mask2 = xs.mask2(:,k); splot.mask2(~isfinite(splot.mask2))=0;
    ft_plot_mesh(splot,'vertexcolor',splot.pow, ...
        'clim', [0 0.015], ...
        'facealpha', splot.mask, ...
        'colormap',cmap, ...
        'maskstyle', 'colormix',...
        'contour',splot.mask2);
    lighting gouraud;material dull;view([-90 -20]);h=light('position',[-10 0 0]);
    set(gcf,'color','w');
    title(sprintf('time = %d',round(1000.*time(k))),'position',[33 -204 100]);
    fname = strcat('/project/3011020.09/sopara/prevalence/',sprintf('/crossmod_timestamp%03d_mean_pcMN_medial',k));
    export_fig(fname,'-png','-transparent','-m5');
    clf;
end 

%% Fig 3.
cmap = brewermap(63,'Blues');

source                = [];
source.brainordinate  = atlas;
source.brainordinate.pos = posleft;
source.label          = atlas.parcellationlabel;
source.time           = time;
source.dimord         = 'chan_time';
source.pow            = results.gamma0c;
source.mask           = double(results.pcGN < 0.05);

xs = source;
xs = ft_checkdata(xs,'datatype','source');

%find where first cluster begins and plot from there to end
[~, firstcol]   = find(source.mask,1);
[~, lastcol]    = find(source.mask,1,'last');
splot = xs;
figure('position',[1 1 900 900]);
for k = firstcol:1:lastcol
    splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
    splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
    ft_plot_mesh(splot,'vertexcolor',splot.pow, ...
        'clim', [0.4 0.56], ...
        'facealpha', splot.mask, ...
        'colormap',cmap, ...
        'maskstyle', 'colormix')
    lighting gouraud;
    material dull;
    view([90 0]);
    h=light('position',[10 0 0]);
    title(sprintf('time = %d',round(1000.*time(k))),'position',[33 -204 100]);
    set(gcf,'color','w');
    fname = strcat('/project/3011020.09/sopara/prevalence/',sprintf('/crossmod_timestamp%03d_gamma0',k));
    export_fig(fname,'-png','-transparent','-m5');
    clf;
end

% Plot medial view
figure('position',[1 1 900 900]);
for k = firstcol:1:lastcol
    splot.pow = xs.pow(:,k); splot.pow(~isfinite(splot.pow)) = 0;
    splot.mask = xs.mask(:,k); splot.mask(~isfinite(splot.mask))=0;
    ft_plot_mesh(splot,'vertexcolor',splot.pow, ...
        'clim', [0.4 0.56], ...
        'facealpha', splot.mask, ...
        'colormap',cmap, ...
        'maskstyle', 'colormix')
    lighting gouraud;material dull;view([-90 -20]);h=light('position',[-10 0 0]);
    set(gcf,'color','w');
    title(sprintf('time = %d',round(1000.*time(k))),'position',[33 -204 100]);
    fname = strcat('/project/3011020.09/sopara/prevalence/',sprintf('/crossmod_timestamp%03d_gamma0_medialview',k));
    export_fig(fname,'-png','-transparent','-m5');
    clf;
end 
% Plot average Figure
source.pow            = nanmean(results.gamma0c,2);
[rows,~] = find(results.pcGN < 0.05);
source.mask           = zeros(size(source.pow));
source.mask(rows)     = 1;
xs = source;
xs = ft_checkdata(xs,'datatype','source');

figure('position',[1 1 900 900]);
xs.pow(~isfinite(xs.pow)) = 0;
ft_plot_mesh(xs,'vertexcolor',xs.pow, ...
    'clim', [0.4 0.56], ...
    'facealpha', xs.mask, ...
    'colormap',cmap, ...
    'maskstyle', 'colormix')
lighting gouraud;
material dull;
view([90 0]);
h=light('position',[10 0 0]);
title('average over time');
set(gcf,'color','w');
fname = strcat('/project/3011020.09/sopara/figures/final/fig3/',sprintf('crossmod_avg_gamma0_avg'));
export_fig(fname,'-png','-transparent','-m5');

% Plot medial view
figure('position',[1 1 900 900]);
ft_plot_mesh(xs,'vertexcolor',xs.pow, ...
    'clim', [0.4 0.56], ...
    'facealpha', xs.mask, ...
    'colormap',cmap, ...
    'maskstyle', 'colormix')
lighting gouraud;material dull;view([-90 -20]);h=light('position',[-10 0 0]);
set(gcf,'color','w');
title('average over time');
fname = strcat('/project/3011020.09/sopara/figures/final/fig3/',sprintf('crossmod_avg_gamma0_avg_medialview'));
export_fig(fname,'-png','-transparent','-m5');
% Plot medial right
source.brainordinate.pos = posright;
xs = source;
xs = ft_checkdata(xs,'datatype','source');
figure('position',[1 1 900 900]);
ft_plot_mesh(xs,'vertexcolor',xs.pow, ...
    'clim', [0.4 0.56], ...
    'facealpha', xs.mask, ...
    'colormap',cmap, ...
    'maskstyle', 'colormix')
lighting gouraud;material dull;view([-90 -20]);h=light('position',[-10 0 0]);
set(gcf,'color','w');
title('average over time');
fname = strcat('/project/3011020.09/sopara/figures/final/fig3/',sprintf('crossmod_avg_gamma0_avg_Rmedialview'));
export_fig(fname,'-png','-transparent','-m5');