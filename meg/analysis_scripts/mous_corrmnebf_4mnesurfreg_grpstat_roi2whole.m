function mous_corrmnebf_4mnesurfreg_grpstat_roi2whole(subjectnames)

% This function performs group-level statistics on the mne-bf matrix 
% Interpolation is not necessary because we are using surface registered
% MNEs for the correlatoin matrix.
% seed voxel is defined, and the ROI based on the seed is chosen using the 3D sourcemodel
% the 2D sourcemodel is used to create a data structure suitable for ft_sourcestatistics.
% Finally, montecarlo permutation is used for statistics to control for multiple comparisons (but not multiple tests, i.e. multiple ROIs)

% non-interp'd correlation matrix = vox*vert
% interpolate correlation matrix = vert*vox

dostats = true;
dodesc  = false;

% define parameters for analyses
  param.foi         = 5;        
  param.toie        = [0.35 0.45];  % toi for ERFs
  param.selfq       = [-0.12 -0.08];
  param.suff        = num2str(param.foi);
  param.savebf      = regexprep(num2str(mean(param.selfq(:))),'[.]','');
  param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]','');  
  param.cdtn        = 'sen';  
  param.cdtn2       = 'seq'; 
  rootdir = '/project/3011020.09/nielam/'; 


%% randomly pick half the subjects for discovery  (other half for replication)
% ninsubj = numel(subjectnames);
% tmp = randperm(ninsubj);
% tmp = tmp(1:floor(ninsubj/2));
% subjectnames = subjectnames(tmp);

if dostats
%% define ROIs 
    if param.foi == 16
        roi(1).x = 6;    
        roi(1).y = 7;
        roi(1).z = 17;
        roi(1).seed = 'TFRseed';
        roi(1).cdtn = param.cdtn;
        roi(1).area = 'Lparietal';

        roi(2).x = 16;   
        roi(2).y = 8;
        roi(2).z = 17;
        roi(2).seed = 'TFRseed';
        roi(2).cdtn = param.cdtn;
        roi(2).area = 'Rparietal2';

        roi(3).x = 7; 
        roi(3).y = 20;
        roi(3).z = 16;
        roi(3).seed = 'TFRseed';
        roi(3).cdtn = param.cdtn;
        roi(3).area = 'Lfrontal2';

        roi(4).x = 5;
        roi(4).y = 17;
        roi(4).z = 17;
        roi(4).seed = 'TFRseed';
        roi(4).cdtn = param.cdtn;
        roi(4).area = 'Rfrontal2';

        roi(5).x = 5; 
        roi(5).y = 18;
        roi(5).z = 12;
        roi(5).seed = 'ERFseed';
        roi(5).cdtn = param.cdtn;
        roi(5).area = 'LIFG2';

    elseif param.foi == 5
        roi(1).x = 8;    
        roi(1).y = 6;
        roi(1).z = 14;
        roi(1).seed = 'TFRseed';
        roi(1).cdtn = param.cdtn;
        roi(1).area = 'Lparietal5Hz';

        roi(2).x = 14;   
        roi(2).y = 4;
        roi(2).z = 13;
        roi(2).seed = 'TFRseed';
        roi(2).cdtn = param.cdtn;
        roi(2).area = 'Rparietal5Hz';

        roi(3).x = 7; 
        roi(3).y = 17;
        roi(3).z = 13;
        roi(3).seed = 'TFRseed';
        roi(3).cdtn = param.cdtn;
        roi(3).area = 'Lfrontal5Hz';

        roi(4).x = 5; 
        roi(4).y = 18;
        roi(4).z = 12;
        roi(4).seed = 'ERFseed';
        roi(4).cdtn = param.cdtn;
        roi(4).area = 'LIFG2';
    end 

       
    for rcnt = 1:numel(roi)
        allsdata(rcnt).cdtnone = cell(numel(subjectnames),1);  % sen
        allsdata(rcnt).cdtntwo = cell(numel(subjectnames),1);  % seq
    end 
    
    %% get sourcemodel (grid)        
    % defines source positions for MNE (same across all subjects)
    load('/home/language/nielam/MOUS/meg/templates/cortex_midthickness_8196reg');
    sourcemodel2d          = sourcemodel;
    sourcemodel2d.pos      = sourcemodel2d.pnt; sourcemodel2d = rmfield(sourcemodel2d,'pnt');
    sourcemodel2d.dim      = [8196 1 1];
    sourcemodel2d.outside  = [];
    sourcemodel2d.inside   = 1:8196;
    clear source bnd h sourcemodel

    % get 3D sourcemodel to select ROI
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    load(fname);
    % adjust sourcemodel size from [1 x 5798] to [1 x 5782], & limit the inside sources
    mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn],rootdir);
    sourcemodel.inside    = source.inside;
    sourcemodel.outside   = setdiff(1:size(sourcemodel.pos,1), source.inside);
    if isfield(sourcemodel,'cfg')
     sourcemodel = rmfield(sourcemodel,'cfg');
    end
    rmf = {'xgrid','ygrid','zgrid','unit'}; sourcemodel = rmfield(sourcemodel,rmf);

    % get voxel coordinates for ROI
    if param.foi == 16
        load /home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_wholeheadcoord.mat
    elseif param.foi == 5
        load /home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_wholeheadcoord_5Hz.mat
    end 
        
    % get subject contribution for each voxel (dof); same for both cdtns
    % mous_db_getdata('groupresults',['meg_corrmnebf_grpavg_corVoxvert8mm_mnesurfreg_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen_',num2str(Nsubj)]);
    tmp = mous_db_getdata('groupresults',['meg_corrmnebf_grpavg_corVoxvert8mm_mnesurfreg_jack_indregword_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen_101'],rootdir);
    dof = tmp{3};
    clear tmp;
        
     
    %% load data for each individual subject and select ROI 
    Nsubj = numel(subjectnames);
    
    for scnt = 1:Nsubj      
        corsen = mous_db_getdata(subjectnames{scnt},['meg_corrmnebf_corVoxvert8mm_mnesurfreg_jack_indregword_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_sen'],rootdir);
        corseq = mous_db_getdata(subjectnames{scnt},['meg_corrmnebf_corVoxvert8mm_mnesurfreg_jack_indregword_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_seq'],rootdir); 
               
        for rcnt = 1:numel(roi)
            % select necessary data for stats for each ROI        
            dum=zeros(stat.dim);
            dum(roi(rcnt).x-1:roi(rcnt).x+1,roi(rcnt).y-1:roi(rcnt).y+1,roi(rcnt).z-1:roi(rcnt).z+1)=1;
            sel = find(dum);
            idxROI = find(ismember(sourcemodel.inside,sel));

            % cor = 5786 vox & 8196 vert
            if strcmp(roi(rcnt).seed,'TFRseed')   
               tmp  = corsen(idxROI,:);  % select appropriate voxels (rows)
               tmp  = nanmean(tmp,1);    % average across voxels           

               tmp2 = corseq(idxROI,:);
               tmp2 = nanmean(tmp2,1);
                
               allsdata(rcnt).cdtnone{scnt} = sourcemodel2d;
               allsdata(rcnt).cdtnone{scnt}.avg.pow = tmp;
               % in dof, all rows are the same
               allsdata(rcnt).cdtnone{scnt}.inside(dof(:,1) < Nsubj) = [];  % .inside determines which voxels are tested for stats
               allsdata(rcnt).cdtnone{scnt}.outside = setdiff(1:8196,allsdata(rcnt).cdtnone{scnt}.inside);
               
               allsdata(rcnt).cdtntwo{scnt} = allsdata(rcnt).cdtnone{scnt}; 
               allsdata(rcnt).cdtntwo{scnt}.avg.pow = tmp2;                
                
            elseif strcmp(roi(rcnt).seed,'ERFseed')   
               % get atlas for select ERF ROI
               [p,f,e] = fileparts('mous_mne_groupanalysis_parcellated');
               sel     = strfind(p, '/');
               fname   = fullfile(p(1:sel),'templates','atlas_conte69_8196reg_LR');
               load(fname);
               
               %L45 = atlas.parcellation2label(15); % left hemisphere, approx broca's area 45
               %L44 = atlas.parcellation2label(14); % left hemisphere, approx broca's area 44
               %lifg45 = find(atlas.parcellation2 == 15);
               %lifg44 = find(atlas.parcellation2 == 14);
               lifgAll = [14 15];
               idxlifgall = find(ismember(atlas.parcellation2,lifgAll));  % find vertices corresponding to ROI
               idxdofpres = find(dof(1,idxlifgall) == 0);   % determine which vertices in ROI are zero (no subjs contribute)
                              
               % with interpolate MNEs, the vertices not submitted to statistics defined by sourcemodel.outside
               % Surfreg'd MNEs, and only when seeding with ERFs: vertices not submitted to stats
               % are removed prior to averaging across vertices
               if ~isempty(idxdofpres)
                   idxlifgall = setdiff(idxlifgall,idxdofpres);
               end                    
               
               tmp = corsen(:,idxlifgall); % select vertices of interest (columns)
               tmp = nanmean(tmp,2);       % column vector [5782 x 1]
               
               tmp2 = corseq(:,idxlifgall);
               tmp2 = nanmean(tmp2,2);
               
               allsdata(rcnt).cdtnone{scnt} = sourcemodel;
               allsdata(rcnt).cdtnone{scnt}.avg.pow = zeros(1,11000);
               allsdata(rcnt).cdtnone{scnt}.avg.pow(sourcemodel.inside) = tmp;
               allsdata(rcnt).cdtnone{scnt}.outside = setdiff(1:11000,allsdata(rcnt).cdtnone{scnt}.inside); 
               
               allsdata(rcnt).cdtntwo{scnt} = allsdata(rcnt).cdtnone{scnt}; 
               allsdata(rcnt).cdtntwo{scnt}.avg.pow(sourcemodel.inside) = tmp2;
            end
        end 
    end 
    
    dumdata = allsdata(1).cdtnone(:);  % create one dummy variable to compare against sen or seq.
    for k = 1:numel(allsdata(1).cdtnone)
      dumdata{k}.avg.pow(:) = 0;
    end 
    
    % separate dummy condition when seeding with ERFs because this requires
    % the 3D sourcemodel (for the TFRs)
    dumdataerfseed = allsdata(end).cdtnone(:);
    for k = 1:numel(allsdata(end).cdtnone)
      dumdataerfseed{k}.avg.pow(:) = 0;
    end 
    
    
%% montecarlo permutation statistics 
    totalcomp = numel(roi)*3;
    
    for qq = 1:totalcomp  % 3 comparisons (svs, sen v. 0, seq v. 0) for each ROI

        if qq < numel(roi)+1                              % svs comparison 
          sdat1 = allsdata(qq).cdtnone;
          sdat2 = allsdata(qq).cdtntwo;
          statsavename = ['meg_corrmnebf_grpstats_corVoxvert8mm_mnesurfreg_jack_indregword_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',roi(qq).area,'_',roi(qq).seed,'_svs_',num2str(Nsubj)];
        elseif qq > numel(roi) && qq < (numel(roi)*2)+1   % sent vs. 0
          sdat1 = allsdata(qq-numel(roi)).cdtnone;
          if mod(qq,numel(roi)) == 0
              sdat2 = dumdataerfseed;
          else
              sdat2 = dumdata;
          end 
          statsavename = ['meg_corrmnebf_grpstats_corVoxvert8mm_mnesurfreg_jack_indregword_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',roi(qq-numel(roi)).area,'_',roi(qq-numel(roi)).seed,'_sen_',num2str(Nsubj)];
        elseif qq > numel(roi)*2                                    % seq vs. 0
          sdat1 = allsdata(qq-numel(roi)*2).cdtntwo;
          if mod(qq,numel(roi)) == 0
              sdat2 = dumdataerfseed;
          else
              sdat2 = dumdata;
          end 
          statsavename = ['meg_corrmnebf_grpstats_corVoxvert8mm_mnesurfreg_jack_indregword_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',roi(qq-numel(roi)*2).area,'_',roi(qq-numel(roi)*2).seed,'_seq_',num2str(Nsubj)];
        end       

        % do stats       
        cfg = [];
        cfg.method = 'montecarlo';
        cfg.statistic = 'depsamplesT';
        cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
        cfg.ivar = 1;
        cfg.uvar = 2;
        cfg.numrandomization = 2000;  % with 72 subjects, can do at least 2000 permutations
        cfg.parameter = 'avg.pow';
        cfg.correctm  = 'no';  % 'max' - compare with maximum statistic (max. of cluster-level statistic)
        cfg.clusteralpha = 0.05;
        %cfg.clusteralpha = 0.005;
        cfg.clusterthreshold = 'nonparametric_individual'; % is "nonpar_common" determined across all subjects?
        stat2 = ft_sourcestatistics(cfg, sdat1{:}, sdat2{:}); 
        
        mous_db_putdata('groupresults',statsavename,'stat2',rootdir);
    end 
 
end % end dostats

if dodesc % plot results
    %% plotting for TFR seed (i.e. looking at ERFs, using 2D sourcemodel)
    % get 2D sourcemodel: defines source positions (same across all subjects)
    sourcemodel2d = load('/home/language/nielam/MOUS/meg/templates/cortex_midthickness_8196reg');
    sourcemodel2d = sourcemodel2d.sourcemodel;
   
    dat = sourcemodel2d;
    dat.avg.pow = zeros(1,8196);
    %dat.avg.pow = stat2.prob;
    tmp = -log10(stat2.prob);
    %idx = find(tmp > 0.005);
    %tmp(idx) = NaN;
    dat.avg.pow = tmp;
    %figure; ft_plot_mesh(dat, 'edgecolor','none','vertexcolor',dat.avg.pow);
    figure; ft_plot_mesh(dat, 'edgecolor','none','vertexcolor',dat.avg.pow);
    clear title;
    title('Rparietal2 TFR seed to ERF whole head; surf reg; SEN')
    colorbar; caxis([0 0.005]);
    %title('Lfrontal2 TFR seed to ERF whole head; surf reg; svs')
    
    %% plotting for ERF seed (i.e. looking at TFRs, using 3D sourcemodel)
       
    if ndims(stat2.stat)>2 %i.e. being a 3d matrix, rather than space x something else
      stat2.stat=stat2.stat(:);
      stat2.prob=stat2.prob(:);
      stat2.mask=stat2.mask(:);
    end
     
    i1    = mous_bfica_sourceinterpolate(stat2, 'stat', stat2.inside);
    iprob = mous_bfica_sourceinterpolate(stat2, 'prob', stat2.inside);
    %imask = mous_bfica_sourceinterpolate(stat3, 'mask', stat2.inside);
    
    cfg = [];
    cfg.method      = 'slice';  %ortho
    cfg.funparameter = 'pow';
    cfg.funcolorlim = [-5 5];
    % superimpose ROIs onto afni brain atlas
    % cfg.atlas='/home/common/matlab/fieldtrip/template/atlas/afni/TTatlas+tlrc.BRIK';
    ft_sourceplot(cfg,i1);
    
    row = max(length(stat2.posclusters),length(stat2.negclusters));
    statval = zeros(row,4);
    for k = 1:numel(stat2.posclusters)
        if k > length(stat2.negclusters)
            statval(k,3) = NaN;        % negative p-value
            statval(k,4) = NaN; % t-value
        elseif k > length(stat2.negclusters) 
            statval(k,1) = NaN;        % positive cluster p-value  
            statval(k,2) = Nan; 
        else        
            statval(k,1) = stat2.posclusters(k).prob;        % positive cluster p-value
            statval(k,2) = stat2.posclusters(k).clusterstat; % t-value
            statval(k,3) = stat2.negclusters(k).prob;        % negative p-value
            statval(k,4) = stat2.negclusters(k).clusterstat; % t-value
        end 
    end 
    
    
end  % dodesc % descriptives
    