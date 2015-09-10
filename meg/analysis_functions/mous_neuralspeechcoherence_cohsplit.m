function mous_neuralspeechcoherence_cohsplit(location,freq,depvar,ngrp)

% mous_neuralspeechcoherence_cohsplit divides all 102 auditory subjects
% based on a a set of predetermine criteria.
% The criteria can be divided into:
% #1 Region of interest (ROI): X vertices from group-average coherence,
% subset of X vertices
% #2 Frequency: delta, theta, alpha, beta, gamma
% #3 measure of interest:  mean coherence, median coherence
% #4 number of groups: 2,3,or 4 (taking only 1st and last quarter)
% Note: for #1 tried with brodmann areas - see MOUS_20150819, but this ROI is not
% defendable

% Criteria set 1
% #1: top 80 vertices from group-average coherence with lat index:(L+R)/(L-R)
% #2: vertices are frequency specific
% #3: mean coherence

% single subject data filename
% NOTE: may make switch to add option of data using multiple dipole
sglsubjdata = ['meg_coh_sourcedata_',freq,'_surface_ampnorm_sentpeak'];

%%%%%%%%%%%
% GET ROI %
%%%%%%%%%%%

switch freq
  case 'delta'
    load('/project/3011020.09/nielam/groupresults/coh/speechenvelope/stat_surface_lateralization_sentpeak_delta_102subj_corrmcluster'); 
  case 'theta'
    load('/project/3011020.09/nielam/groupresults/coh/speechenvelope/stat_surface_lateralization_sentpeak_theta_92subj_corrmcluster'); 
end 
load atlas_conte69_8196reg_LR
load cortex_midthickness_8196reg

numv      = 80; % >25 selects left inf. parietal as well.
% not to be selected as ROI
% e.g., exclude pre- and post-central gyrus (that area has coherence
% because of spatial blurring)

ir40   = find(ismember(atlas.parcellationlabel,'L_40_B05'));
ir43   = find(ismember(atlas.parcellationlabel,'L_43_B05'));
ir44   = find(ismember(atlas.parcellationlabel,'L_44_B05'));
ir4    = find(ismember(atlas.parcellationlabel,'L_4_B05'));
ir6    = find(ismember(atlas.parcellationlabel,'L_6_B05'));
ir8    = find(ismember(atlas.parcellationlabel,'L_8_B05'));
ir3    = find(ismember(atlas.parcellationlabel,'L_3_B05'));
ir2    = find(ismember(atlas.parcellationlabel,'L_2_B05'));
ir1    = find(ismember(atlas.parcellationlabel,'L_1_B05'));
leavei = find(ismember(atlas.parcellation,[ir40 ir43 ir44 ir1 ir2 ir3 ir4 ir6 ir8]));

% calculate lateralization index (L-R)/(L+R)
% lat = (leftavg.avg.coh + rightavg.avg.coh)./(leftavg.avg.coh+rightavg.avg.coh);  lat(4099:8196) = 0;

% calculate sum of left and right
lat         = (leftavg.avg.coh + rightavg.avg.coh)./2; lat(4099:8196) = 0;
figure;ft_plot_mesh(sourcemodel,'vertexcolor',lat,'edgecolor','none'); view(-90,0);
lat(leavei) = 0;
figure;ft_plot_mesh(sourcemodel,'vertexcolor',lat,'edgecolor','none'); view(-90,0);
[val,idx]   = sort(lat);
% roi         = idx(end-numv:end); % 82 vertices, instead of 80.
roi         = idx(end-numv-1:end); % CHECK ME, how many vertices?

% visualization for checking
tmp      = zeros(8196,1);
tmp(roi) = 1;
figure;ft_plot_mesh(sourcemodel,'vertexcolor',tmp,'edgecolor','none'); view(-90,0);


%%%%%%%%%%%%%%%%%
%% rank subjects %
%%%%%%%%%%%%%%%%%
[subj,~] = mous_db_getfilename('allA','subjectname');
[~,s]    = mous_db_getfilename('allA',sglsubjdata);
subj     = subj(s);
nsubj    = numel(subj);

for k = 1:nsubj
  mous_db_getdata(subj{k},sglsubjdata);
  sentcoh.avg.coh = sqrt(sentcoh.avg.coh); % take sqrt for coherence
  
  switch location
    case 'alltop'  % take all 80 vertices
%       diff            = (sentcoh.avg.coh(1:4098) - sentcoh.avg.coh(4099:8196))./(sentcoh.avg.coh(1:4098)+sentcoh.avg.coh(4099:8196));
      diff            = (sentcoh.avg.coh(1:4098) + sentcoh.avg.coh(4099:8196))./2;
      latidx(k,:)     = diff(roi); % 102 x 80 matrix

    case 'indtop'  % take 50 of 80 vertices
%       diff            = (sentcoh.avg.coh(1:4098) - sentcoh.avg.coh(4099:8196))./(sentcoh.avg.coh(1:4098)+sentcoh.avg.coh(4099:8196));
      diff            = (sentcoh.avg.coh(1:4098) + sentcoh.avg.coh(4099:8196))./2;
      [v2,i2]         = sort(diff(roi));
      latidx(k,:)     = diff(roi(i2(1:50)));
  end
end

% Normalize: divide by group mean: does not change anything, ratios between
% subjects are kept the same

switch depvar
  case 'latmean'
    % calculate mean
    latidx(:,end+1) = mean(latidx,2);
  case 'latmed'
    % less influenced by extreme values at the single-subject level
    latidx(:,end+1) = median(latidx,2);
end    
[val,idx]       = sort(latidx(:,end)); % values go from negative to positive (ascending order)

%%%%%%%%%%%%%%%%%%
%% split subjects %
%%%%%%%%%%%%%%%%%%
switch ngrp
  case 'two'
    border = nsubj/2;
    slow   = subj(idx(1:border));
    shigh  = subj(idx(border+1:end));
    
  case 'three'
    border = round(nsubj/3);  % might be fraction
    slow   = subj(idx(1:border));
    smid   = subj(idx(border+1:border*2));
    shigh  = subj((border*2)+1:end);
    
  case 'tbquart'              % top and bottom quarter
    border = round(nsubj/4);  % might be fraction
    slow   = subj(idx(1:border)); 
    shigh  = subj(idx(end-border+1:end));  % numel(shigh) == numel(slow)
end

%%%%%%%%%%%%%%%%%%
%% group-avg maps %
%%%%%%%%%%%%%%%%%%

% applies to all types of ngrp
switch ngrp 
  case 'two'
    nsubj = nsubj/2;

    for k = 1:nsubj
      t1 = mous_db_getdata(slow{k},sglsubjdata);
      t2 = mous_db_getdata(shigh{k},sglsubjdata);

      if k == 1
        low  = t1;
        high = t2;
        source1{1} = t1;
        source2{1} = t1; % same pos definition across subjs
        source2{1}.avg.coh = t2.avg.coh;

      else
        low.avg.coh  = low.avg.coh  + t1.avg.coh;
        high.avg.coh = high.avg.coh + t2.avg.coh;
        source1{k}         = source1{1};
        source1{k}.avg.coh = t1.avg.coh;
        source2{k}         = source1{1};
        source2{k}.avg.coh = t2.avg.coh;
      end     
    end % for-loop

    lavg = low.avg.coh/nsubj;
    havg = high.avg.coh/nsubj;
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(lavg));view(-90,0);
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(lavg));view(90,0);

    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(havg));view(-90,0);
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(havg));view(90,0);

  case 'three'
    nsubj = nsubj/3;

    for k = 1:nsubj
      t1 = mous_db_getdata(slow{k},sglsubjdata);
      t2 = mous_db_getdata(smid{k},sglsubjdata);
      t3 = mous_db_getdata(shigh{k},sglsubjdata);

      if k == 1
        low  = t1;
        mid  = t2;
        high = t3;

        source1{1} = t1;
        source2{1} = t1; % same pos definition across subjs
        source3{1} = t1;

        source2{1}.avg.coh = t2.avg.coh;
        source3{1}.avg.coh = t3.avg.coh;

      else
        low.avg.coh  = low.avg.coh  + t1.avg.coh;
        mid.avg.coh  = mid.avg.coh  + t2.avg.coh;
        high.avg.coh = high.avg.coh + t3.avg.coh;

        source1{k}         = source1{1};
        source1{k}.avg.coh = t1.avg.coh;

        source2{k}         = source1{1};
        source2{k}.avg.coh = t2.avg.coh;

        source3{k}         = source1{1};
        source3{k}.avg.coh = t3.avg.coh;
      end     
    end % for-loop

    low.avg.coh  = low.avg.coh/nsubj;
    mid.avg.coh  = mid.avg.coh/nsubj;
    high.avg.coh = high.avg.coh/nsubj;
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(low.avg.coh));view(-90,0);
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(low.avg.coh));view(90,0);

    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(mid.avg.coh));view(-90,0);
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(mid.avg.coh));view(90,0);
    
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(high.avg.coh));view(-90,0);
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(high.avg.coh));view(90,0);

  case 'tbquart'
    nsubj = nsubj/4;
     
    for k = 1:nsubj
      t1 = mous_db_getdata(slow{k},sglsubjdata);
      t2 = mous_db_getdata(shigh{k},sglsubjdata);

      if k == 1
        low  = t1;
        high = t2;
        source1{1} = t1;
        source2{1} = t1; % same pos definition across subjs
        source2{1}.avg.coh = t2.avg.coh;

      else
        low.avg.coh  = low.avg.coh  + t1.avg.coh;
        high.avg.coh = high.avg.coh + t2.avg.coh;
        source1{k}         = source1{1};
        source1{k}.avg.coh = t1.avg.coh;
        source2{k}         = source1{1};
        source2{k}.avg.coh = t2.avg.coh;
      end     
    end % for-loop

    lavg = low.avg.coh/nsubj;
    havg = high.avg.coh/nsubj;
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(lavg));view(-90,0);
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(lavg));view(90,0);

    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(havg));view(-90,0);
    figure;ft_plot_mesh(sourcemodel,'edgecolor','none','vertexcolor',sqrt(havg));view(90,0);
end
  

%%%%%%%%%%%%%%
% Statistics %
%%%%%%%%%%%%%%
load('/home/language/nielam/MOUS/meg/templates/cortex_midthickness_8196reg.mat')
C = full(tri2connmat(sourcemodel.tri)); % output is sparse, use full()

cfg = [];
cfg.method            = 'montecarlo';
cfg.numrandomization  = 3000;
cfg.clusterthreshold  = 'nonparametric_common';
cfg.correctm          = 'cluster';
cfg.correcttail       = 'alpha';
cfg.ivar              = 1;
cfg.uvar              = 2;
cfg.design            = [ones(1,nsubj), ones(1,nsubj)*2; 1:nsubj, 1:nsubj];
cfg.parameter         = 'avg.coh';
cfg.statistic         = 'depsamplesT';
cfg.connectivity      = C; 

stat = ft_sourcestatistics(cfg,source1{:},source2{:}); % low vs. high
stat.cfg = rmfield(stat.cfg,'previous');

if strcmp(ngrp,'three')
  statlm = ft_sourcestatistics(cfg,source1{:},source3{:}); % low vs. med
  statlm.cfg = rmfield(statlm.cfg,'previous');

  statmh = ft_sourcestatistics(cfg,source2{:},source3{:}); % med vs. high
  statmh.cfg = rmfield(statmh.cfg,'previous');
end

root = '/project/3011020.09/nielam/groupresults/coh/speechenvelope/';
fname = [root,'stat_surface_cohsplit_lateralization_sentpeak_',freq,'_ttest',num2str(nsubj),'subj_corrm',corrmeth,'.mat'];
save(fname,'stat','slow','shigh','-v7.3');

if strcmp(ngrp,'three')
  save(fname,'stat','statlm','statmh','subj','-v7.3');
end


%%%%%%%%%%
% TO TRY %
%%%%%%%%%%

% Criteria set 3 
% #1: a) define a ROI around auditory cortex: (L+R)/2 that has ~200
%     b) pick subject-specific top 60 vertices (map blurry anyway)
% #2: vertices are frequency specific
% #3: mean coherence

% Criteria set 2 - DONE
% #1: top 80 vertices from group-average coherence
% #2: vertices are frequency specific
% #3: median coherence

% Criteria set 4 - DONE
% #1: top 80 vertices from group-average coherence, normalize across
% subjects
% #2: vertices are frequency specific
% #3: mean coherence 
% #4: 3 groups


