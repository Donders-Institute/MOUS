function mous_corrmnebf_oscpowbin_grpstat_roi2whole(subjectnames)

% This function performs group-level statistics on the mne-bf matrix 
% The function is written to interpolate only once (this is because interpolation is extremely time consuming).
% Then for defined ROI,  the necessary dataset for statistical analyses are create (i.e. select ROI from interpolated matrix) 
% Finally, montecarlo permutation is used for statistics to control for multiple comparisons (but not multiple tests, i.e. multiple ROIs)

% non-interp'd correlation matrix = vox*vert
% interpolate correlation matrix = vert*vox

% roi = 4:
% 1:  Left parietal
% 2:  Right parietal
% 3:  Left frontal
% 4:  Right frontal

dostats = true;
dodesc  = false;

% define parameters for analyses
    param.foi         = 16;        
    param.toie        = [0.35 0.45];  % toi for ERFs
    param.selfq       = [-0.12 -0.08];
    param.suff        = num2str(param.foi);
    param.savebf      = regexprep(num2str(mean(param.selfq(:))),'[.]','');
    param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]','');  
    param.cdtn        = 'sen';  
    param.cdtn2       = 'seq'; 
    param.numroi      = 4;
        
%% randomly pick half the subjects for discovery  (other half for replication)
% ninsubj = numel(subjectnames);
% tmp = randperm(ninsubj);
% tmp = tmp(1:floor(ninsubj/2));
% subjectnames = subjectnames(tmp);

if dostats    
    %% get sourcemodel (grid)        
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    load(fname);
    mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn]);

    % adjust sourcemodel size from [1 x 5798] to [1 x 5782], then limit the inside sources
    % sourcemodel.insideold = sourcemodel.inside;
    sourcemodel.inside    = source.inside;
    sourcemodel.outside   = setdiff(1:size(sourcemodel.pos,1), source.inside);
    if isfield(sourcemodel,'cfg')
        sourcemodel = rmfield(sourcemodel,'cfg');
    end
    rmf = {'xgrid','ygrid','zgrid','unit'};
    sourcemodel = rmfield(sourcemodel,rmf);

    %% load data for each individual subject 
    Nsubj = numel(subjectnames);
    for rcnt = 1:4
                 
        if rcnt == 1
            param.roi = 'Lparietal';
        elseif rcnt == 2
            param.roi = 'Rparietal2';
        elseif rcnt == 3
            param.roi = 'Lfrontal2';
        elseif rcnt == 4
            param.roi = 'Rfrontal2';
        end 
                      
        % files to use in interpolation
        cfginterp = [];
        cfginterp.cor = ['meg_corrmnebf_corVoxvert8mm_oscpowbin_avgregwordord_',param.roi,'_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];
        cfginterp.erf = 'meg_anatomy_sourcemodel2D';
        cfginterp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_4powbin_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];
        % don't need roi/bin-specific source data because just need beamforming locations

        if isfield(param,'cdtn2')
          cfginterp2 = cfginterp;
          cfginterp2.cor = ['meg_corrmnebf_corVoxvert8mm_oscpowbin_avgregwordord_',param.roi,'_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn2];
          cfginterp2.tfr  = ['meg_corrmnebf_bfsourcesingletrial8mm_4powbin_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn2];
        end 
        
        for scnt = 1:Nsubj

            [source3dsen] = mous_corrmnebf_interpolate(subjectnames{scnt},cfginterp);  % output is verts X voxels
            if isfield(source3dsen, 'cfg')
                source3dsen = rmfield(source3dsen,'cfg');
            end

            [source3dseq] = mous_corrmnebf_interpolate(subjectnames{scnt},cfginterp2);  % output is verts X voxels
            if isfield(source3dseq, 'cfg')
                source3dseq = rmfield(source3dseq,'cfg');
            end

            load /home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_wholeheadcoord.mat  % ROI seed
            mous_db_getdata('groupresults',['meg_corrmnebf_grpavg_corVoxvert8mm_avgregwordord_oscpowbin_',param.roi,'_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn,'_37subj']); % dof data

            allsdata(rcnt).cdtnone{scnt} = sourcemodel;
            allsdata(rcnt).cdtnone{scnt}.avg.pow = zeros(1,11000);
            allsdata(rcnt).cdtnone{scnt}.avg.pow(sourcemodel.inside) = mean(source3dsen.corrmat,2);
            allsdata(rcnt).cdtnone{scnt}.inside(dof(:,1) < Nsubj) = [];  % .inside determines which voxels are tested for stats
            allsdata(rcnt).cdtnone{scnt}.outside = setdiff(1:11000,allsdata(rcnt).cdtnone{scnt}.inside);

            allsdata(rcnt).cdtntwo{scnt} = allsdata(rcnt).cdtnone{scnt}; 
            allsdata(rcnt).cdtntwo{scnt}.avg.pow(sourcemodel.inside) = mean(source3dseq.corrmat,2);
            % dof info already copied from cdtnone, no need to assign again          
        end 

        dumdata = allsdata(1).cdtnone(:);  % create one dummy variable to compare against sen or seq.
        for k = 1:numel(allsdata(1).cdtnone)
          dumdata{k}.avg.pow(:) = 0;
        end 
    end 
    
      %% montecarlo permutation statistics
      
    for qq = 1:param.numroi*3  % 3 comparisons (svs, sen v. 0, seq v. 0) for each ROI
        
        if qq == 1 || qq == 5 || qq == 9
            param.roi = 'Lparietal';
        elseif qq == 2 || qq == 6 || qq == 10
            param.roi = 'Rparietal2';
        elseif qq == 3 || qq == 7 || qq == 11
            param.roi = 'Lfrontal2';
        elseif qq == 4 || qq == 8 || qq == 12
            param.roi = 'Rfrontal2';
        end 
        
        if qq < param.numroi+1            % 1 to 4  % svs comparison 
          sdat1 = allsdata(qq).cdtnone;
          sdat2 = allsdata(qq).cdtntwo;
          statsavename = ['meg_corrmnebf_groupStats_',param.roi,'_svs_',num2str(Nsubj)];
        elseif qq > param.numroi && qq < (param.numroi*2)+1  % 5 - 8 sent vs. 0
          sdat1 = allsdata(qq-param.numroi).cdtnone;
          sdat2 = dumdata;
          statsavename = ['meg_corrmnebf_groupStats_',param.roi,'_sen_',num2str(Nsubj)];
        elseif qq > param.numroi*2            % >9;  seq vs. 0
          sdat1 = allsdata(qq-param.numroi*2).cdtntwo;
          sdat2 = dumdata;
          statsavename = ['meg_corrmnebf_groupStats_',param.roi,'_seq_',num2str(Nsubj)];
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
        cfg.correctm  = 'cluster';
        cfg.clusteralpha = 0.05;
        %cfg.clusteralpha = 0.005;
        cfg.clusterthreshold = 'nonparametric_individual'; % is "nonpar_common" determined across all subjects?
        stat2 = ft_sourcestatistics(cfg, sdat1{:}, sdat2{:}); 

        mous_db_putdata('groupresults',statsavename,'stat2');
    end 
 
end % end dostats

if dodesc 
    
    ROI = 'LIFG';
    seed = 'ERFseed';  % 'ERFseed'
    cdtn = 'sent'; 
    
    mous_db_getdata('groupresults',statsavename);
    
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
    cfg.title       = 'test';
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
    
%     cfg = [];
%     cfg.method  = 'slice';
%     cfg.funparameter = 'pow';
%     cfg.maskparameter = iprob3;
%     ft_sourceplot(cfg,iprob);
    
        nclust = 1;
        value  = 'neg'; % 'neg'
        %title  = [ROI,' ',seed,' ', cdtn,' ', value,' clust 1'];
        mous_corrmnebf_selstatclus(nclust,stat2,value,[]);
        
        nclust = 1;
        value  = 'pos'; % 'neg'
        %title  = [ROI,' ',seed,' ', cdtn,' ', value,' clust 1'];
        mous_corrmnebf_selstatclus(nclust,stat2,value,[]);


    % summary of t- and p-values of all clusters 
    % columns: +t +p  -t  -p
    
end  % dodesc % descriptives
    

    
