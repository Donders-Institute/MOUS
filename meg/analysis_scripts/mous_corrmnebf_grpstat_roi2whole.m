function mous_corrmnebf_grpstat_roi2whole(param)

% This function performs group-level statistics on the mne-bf matrix 
% The function is written to interpolate only once (this is because interpolation is extremely time consuming).
% Then for defined ROI,  the necessary dataset for statistical analyses are create (i.e. select ROI from interpolated matrix) 
% Finally, montecarlo permutation is used for statistics to control for multiple comparisons (but not multiple tests, i.e. multiple ROIs)

% corrmat is vertices by voxels!

% define parameters for analyses

% param.foi         = 16;        
% param.toie        = [0.35 0.45];  % toi for ERFs
% param.selfq       = [-0.12 -0.08];
% param.suff        = num2str(foi);
% param.savebf      = regexprep(num2str(mean(selfq(:))),'[.]','');
% param.savemne     = regexprep([num2str(toie(1)) num2str(toie(2))],'[.]','');  
% param.cdtn        = 'sen';


if dostats
    %% define ROIs
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

    roi(3).x = 5; 
    roi(3).y = 17;
    roi(3).z = 17;
    roi(3).seed = 'TFRseed';
    roi(3).cdtn = param.cdtn;
    roi(3).area = 'Rfrontal2';

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
    
    for q = 1:numel(roi)
        allsdata(q).cdtnone = cell(numel(subjectnames),1);
        allsdata(q).cdtntwo = cell(numel(subjectnames),1);
    end 

    %% subjects
    subjectnames = {'V1001' 'V1002' 'V1003' 'V1004' 'V1005' 'V1007' 'V1008' ...
                     'V1010' 'V1011' 'V1012' 'V1013' 'V1015' 'V1016' 'V1017' 'V1019'...
                     'V1020' 'V1021' 'V1022' 'V1023' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028'...
                     'V1030' 'V1031' 'V1032' 'V1036' 'V1037' ...
                     'V1040' 'V1044' 'V1045' 'V1049'...
                     'V1050' 'V1052' 'V1053' 'V1054' 'V1055' 'V1057' 'V1058' 'V1059'...
                     'V1061' 'V1062' 'V1064' 'V1065' 'V1066' 'V1068' 'V1069'... 
                     'V1071' 'V1073' 'V1074' 'V1076' 'V1077' 'V1079'...
                     'V1080' 'V1081' 'V1083' 'V1084' 'V1085' 'V1087' 'V1088' 'V1089'...
                     'V1090' 'V1092'  'V1095' 'V1099'...
                     'V1100' 'V1102' 'V1103' 'V1104' 'V1106' 'V1107'};   


     %% get sourcemodel (grid)        
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    load(fname);
    if ~isempty(foi)  
       mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn]);
    else
       mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_',cdtn]);
    end

    % adjust sourcemodel size from [1 x 5798] to [1 x 5782], then limit the inside sources
    sourcemodel.insideold = sourcemodel.inside;
    sourcemodel.inside    = source.inside;
    sourcemodel.outside   = setdiff(1:size(sourcemodel.pos,1), source.inside);
    if isfield(sourcemodel,'cfg')
        sourcemodel = rmfield(sourcemodel,'cfg');
    end
    
    %% load data for each individual subject and select ROI from corrmat
    cfginterp = [];
    cfginterp.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
    cfginterp.erf = ['meg_corrmnebf_mnesingletrial_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
    cfginterp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];

    % k = subj count
    % q = roi count 
    
    for k = 1:numel(subjectnames)
        % interpolate
        % [source3d, singlegrid] = mous_corrmnebf_interpolate(subjectnames{k},cfginterp);  % output is verts X voxels
        source3d = mous_corrmnebf_interpolate(subjectnames{k},cfginterp);  % output is verts X voxels
        if isfield(source3d, 'cfg')
            source3d = rmfield(source3d,'cfg');
        end

        load /home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_wholeheadcoord.mat
        
        for q = 1:numel(roi)
        % select necessary data for stats for each ROI
                     
            dum=zeros(stat.dim);
            sub2ind(stat.dim,roi(q).x,roi(q).y,roi(q).z);
            dum(roi(q).x-1:roi(q).x+1,roi(q).y-1:roi(q).y+1,roi(q).z-1:roi(q).z+1)=1;
            sel = find(dum);
            idxROI = find(ismember(sourcemodel.inside,sel));

            if strcmp(roi(q).seed,'TFRseed')   %% Osc as source
                
                tmp = source3d.corrmat(:,idxROI);
                tmp = nanmean(tmp,2);                 % average across vertices; sometimes, a certain column = NaNs
                
%                 sdata{k} = sourcemodel;
%                 sdata{k}.avg.pow = zeros(1,11000);
%                 sdata{k}.avg.pow(sourcemodel.inside) = tmp;
%                 
%                 sdata2{k} = sdata{k};
%                 sdata2{k}.avg.pow(:) = 0;
                
               allsdata(q).cdtnone{k} = sourcemodel;
               allsdata(q).cdtnone{k}.avg.pow = zeros(1,11000);
               allsdata(q).cdtnone{k}.avg.pow(sourcemodel.inside) = tmp;
                
               allsdata(q).cdtntwo{k} = allsdata(q).cdtnone{k}; 
               allsdata(q).cdtntwo{k}.avg.pow(:) = 0;
                
                
            elseif strcmp(seed,'ERFseed')      %% erfs as source
               tmp = source3d.corrmat(idxROI,:);       % specify vertices of interest
               tmp = nanmean(tmp,1);                      % average across voxels
               
               allsdata(q).cdtnone{k} = sourcemodel;
               allsdata(q).cdtnone{k}.avg.pow = zeros(1,11000);
               allsdata(q).cdtnone{k}.avg.pow(sourcemodel.inside) = tmp;
                
               allsdata(q).cdtntwo{k} = allsdata(q).cdtnone{k}; 
               allsdata(q).cdtntwo{k}.avg.pow(:) = 0;
               
            end
        end 
    end 
    
      %% montecarlo permutation statistics
      
    for qq = 1:numel(roi)
        
        % assign data structure for analysis
        sdat1 = allsdata(qq).cdtnone;
        sdat2 = allsdata(qq).cdtntwo;
        
        % do stats       
        Nsubj = numel(subjectnames);
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

        mous_db_putdata('groupresults',['meg_corrmnebf_groupStats_',ROI,'_',seed,'_',cdtn,'_72'],'stat2');
    end 
 
end % end dostats

if dodesc 
    
    ROI = 'LIFG';
    seed = 'ERFseed';  % 'ERFseed'
    cdtn = 'sent'; 
    
    mous_db_getdata('groupresults',['meg_corrmnebf_groupStats_',ROI,'_',seed,'_',cdtn,'_72']);
    
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
    cfg.title = 'hi';
    cfg.atlas='/home/common/matlab/fieldtrip/template/atlas/afni/TTatlas+tlrc.BRIK';
    ft_sourceplot(cfg,i1);
    
    row = max(length(stat2.posclusters),length(stat2.negclusters));
    statval = zeros(row,4);
    for k = 1:numel(stat2.posclusters)
        if k > length(stat2.negclusters)
            statvalpos(k,3) = NaN;        % negative p-value
            statvalpos(k,4) = NaN; % t-value
        elseif k > length(stat2.negclusters) 
            statvalpos(k,1) = NaN;        % positive cluster p-value
            statvalpos(k,2) = Nan; 
        else        
            statvalpos(k,1) = stat2.posclusters(k).prob;        % positive cluster p-value
            statvalpos(k,2) = stat2.posclusters(k).clusterstat; % t-value
            statvalpos(k,3) = stat2.negclusters(k).prob;        % negative p-value
            statvalpos(k,4) = stat2.negclusters(k).clusterstat; % t-value
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
        mous_corrmnebf_selstatclus(nclust,stat2,value,[])
        
        nclust = 1;
        value  = 'pos'; % 'neg'
        %title  = [ROI,' ',seed,' ', cdtn,' ', value,' clust 1'];
        mous_corrmnebf_selstatclus(nclust,stat2,value,[])


    % summary of t- and p-values of all clusters 
    % columns: +t +p  -t  -p
    
end  % dodesc % descriptives
    

    