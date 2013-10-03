function mous_erf_regwordord
%  1) load the necessary data
%  2) calculate beta weights for each word position using mous_makecontrast
%  (regression analysis)
%  3) word positions 2:10 are chosen for this calculation
%  4) Then, for each word position a time-lock analysis at sensor-lvl
%  5) sensor time-locked data multiplied with MNE filter to get source estimates. 
%  *MNE filter is used as 'trialinfo' for this transformation
%% permutation test needs much more memory because statistics are
%  are now performed on the entire 5782 * 1 matrix.

suff        = '16';      % ''
foi         = 16;        % []
savebf      = '-01';     % central frequency:  0.1, for 0.08 to 0.12 for TFR toi
savemne     = '035045';
toie        = [0.35 0.45];  % toi for ERFs
toi         = [];         % toi for TFR % not neded because selfq defines  toi
cdtn        = 'sent';
selfq       = [-0.12 -0.08];
ds          = 12;
savdir      = '/project/3011020.09/nielam/';

doreg  = false; % regression - calculate beta weights for each word
doint  = true;  %interpolate 2d to 3d
dostat = true;
dodesc = false;

subjectnames = { 'V1001' 'V1002' 'V1003' 'V1004' 'V1005' 'V1006' 'V1007' 'V1008' 'V1009' ...
                 'V1010' 'V1011' 'V1012' 'V1013' 'V1015' 'V1016' 'V1017' 'V1019'...
                 'V1020' 'V1021' 'V1022' 'V1023' 'V1024' 'V1025' 'V1026' 'V1027' 'V1028' 'V1029'...
                 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' 'V1035' 'V1036' 'V1037' 'V1038' 'V1039'...
                 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' 'V1048' 'V1049'...
                 'V1050' 'V1052' 'V1053' 'V1054' 'V1055' 'V1057' 'V1058' 'V1059'...
                 'V1061' 'V1062' 'V1063' 'V1064' 'V1065' 'V1066' 'V1068' 'V1069'... 
                 'V1070' 'V1071' 'V1072' 'V1073' 'V1074' 'V1075' 'V1076' 'V1077' 'V1078' 'V1079'...
                 'V1080' 'V1081' 'V1083' 'V1084' 'V1085' 'V1086' 'V1087' 'V1088' 'V1089'...
                 'V1090' 'V1092' 'V1093' 'V1094' 'V1095' 'V1097' 'V1098' 'V1099'...
                 'V1100' 'V1101' 'V1102' 'V1103' 'V1104' 'V1105' 'V1106' 'V1107' 'V1108' 'V1109'...
                 'V1110' 'V1111' 'V1113' 'V1114'};   

if doreg     
    % get preprocessed data for ERFs
    mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}','/home/language/annhul/MOUS/meg');
    channel = {'MEG', '-EEG057', '-EEG058'};   % remove unwanted channels
    data = ft_selectdata(data,'channel',channel);
    
    % get surf registered model
    % contrary to name, the filter is calculated from using all words (not just target)
    mous_db_getdata(subjectname,'meg_mne_MNEregnomidlineregC02-1ds_target_Sent','/home/language/jansch/public/mous'); 

    mnefilter = zeros(size(source.pos,1), numel(data.label));  % 8196 x 273
    for k = 1:size(mnefilter,1)
      if ~isempty(source.avg.ori{k}) 
        mnefilter(k,:) = source.avg.ori{k}*source.avg.filter{k};    
      else
        mnefilter(k,:) = nan;  % some sources are on edge of sourcemodel.inside / outside of sourcemodel.inside
      end
    end
    
    % get relevant trialinfo
    data.trialinfo = data.trialinfo(:,[1 5 2 3 4]);
    % 
    [tlck, stat] = mous_makecontrast(data, 'wordseq_parametric', mnefilter);

    mous_db_putdata(subjectname,'meg_mne_02-1ds_Sent_regwordord','stat','tlck',savdir);
    %mous_db_putdata(subjectname,'meg_processed_{MNE02-1ds_Seq_regwordord}','stat','tlck');
end 

if dodatasetup  % put datainto array suitable for analysis
    sdatasen = cell(numel(subjectnames),1);
    sdataseq = cell(numel(subjectnames),1);
    sdata2   = cell(numel(subjectnames),1);
    
    %% get 2D source model
    % defines source positions for MNE (same across all subjects)
    load('/home/language/nielam/MOUS/meg/templates/cortex_midthickness_8196reg');
    sourcemodel2d          = sourcemodel;
    sourcemodel2d.pos      = sourcemodel2d.pnt; sourcemodel2d = rmfield(sourcemodel2d,'pnt');
    sourcemodel2d.dim      = [8196 1 1];
    sourcemodel2d.outside  = [];
    sourcemodel2d.inside   = 1:8196;
    clear source bnd h sourcemodel

    
    %% smooth and downsample data

    for k = 1:numel(subjectnames)
        % SENTENCES
        mous_db_getdata(subjectnames{k},'meg_mne_02-1ds_Sent_regwordord',savdir);  % beta weights
               
        %% why don't we use the source-level data??
        % downsample time
        tmp = tlck.avg;
        tmp = ft_preproc_smooth(tmp,ds);  % 273 chan by 360 time points
        tmp = tmp(:,1:ds:end);            % 273 chan by 30 time points
        
        sendata{k} = sourcemodel2d;
        sendata{k}.avg.pow = tmp;
        sendata{k}.time = source2d.time(1:ds:end);

        dumdata{k} = sendata{k};    
        dumdata{k}.avg.pow(:) = 0;

        % SEQUENCES
        mous_db_getdata(subjectnames{k},'meg_mne_02-1ds_Seq_regwordord',savdir);
        tmp = tlck.avg;
        tmp = ft_preproc_smooth(tmp,ds);
        tmp = tmp(:,1:ds:end);
        
        seqdata{k} = sourcemodel;
        seqdata{k}.avg.pow = tmp;
        seqdata{k}.time = source3d.time(1:ds:end);
    end 
end 
    
if dostat
   Nsubj = numel(subjectnames);
   cfg = [];
   cfg.method = 'montecarlo';
   cfg.statistic = 'depsamplesT';
   cfg.design = [ones(1,Nsubj) ones(1,Nsubj)*2;1:Nsubj 1:Nsubj];
   cfg.ivar = 1;
   cfg.uvar = 2;
   cfg.numrandomization = 2000;
   cfg.parameter = 'avg.pow';
   cfg.correctm  = 'cluster';
   %cfg.correctm = 'no';
   cfg.clusteralpha = 0.05;
   %cfg.correcttail = 'alpha';
   cfg.clusterthreshold = 'nonparametric_individual'; 
   
   stat2 = ft_sourcestatistics(cfg, sendata{:}, dumdata{:});  
   statori = stat2;
   mous_db_putdata('groupresults',['meg_corrmnebf_groupStats_ER_wordord_sen_',num2str(Nsubj)],'stat2');
   
   stat3 = ft_sourcestatistics(cfg,sendata{:},seqdata{:});
   mous_db_putdata('groupresults',['meg_corrmnebf_groupStats_ER_wordord_svs_',num2str(Nsubj)],'stat3');
   
   stat4 = ft_sourcestatistics(cfg,sendata{:},seqdata{:});
   mous_db_putdata('groupresults',['meg_corrmnebf_groupStats_ER_wordord_seq_',num2str(Nsubj)],'stat4');

end


if dodesc
    
     %% plotting for TFR seed (i.e. looking at ERFs, using 2D sourcemodel)
    % get 2D sourcemodel: defines source positions (same across all subjects)
    sourcemodel2d = load('/home/language/nielam/MOUS/meg/templates/cortex_midthickness_8196reg');
    sourcemodel2d = sourcemodel2d.sourcemodel;

    %dat.avg.pow = stat2.prob;
    %idx = find(tmp > 0.005);
    %tmp(idx) = NaN;

    dat = sourcemodel2d;
    dat.avg.pow = zeros(1,8196);
%     tmp = stat2.prob;
%     tmp(tmp(:) > -log10(0.05));
    tmp = -log10(stat2.prob);
    dat.avg.pow = tmp;
    figure; ft_plot_mesh(dat, 'edgecolor','none','vertexcolor',dat.avg.pow);
    colorbar; caxis([0 1.3]);
    
    % light
    % delete(findall(gcf,'Type','light'))
    
    %% 3D plotting stuff
    if ndims(stat2.stat)>2 %i.e. being a 3d matrix, rather than space x something else
      stat2.stat=stat2.stat(:);
      stat2.prob=stat2.prob(:);
      stat2.mask=stat2.mask(:);
    end

    i1    = mous_bfica_sourceinterpolate(stat2, 'stat', stat2.inside);  % interpolate ds times
    iprob = mous_bfica_sourceinterpolate(stat2, 'prob', stat2.inside);
    %imask = mous_bfica_sourceinterpolate(stat3, 'mask', stat2.inside);

    cfg = [];
    cfg.method      = 'slice';  %ortho
    cfg.funparameter = 'pow';
    cfg.funcolorlim = [-5 5];
    % superimpose ROIs onto afni brain atlas
    % cfg.title = 'hi';
    %cfg.atlas='/home/common/matlab/fieldtrip/template/atlas/afni/TTatlas+tlrc.BRIK';
    ft_sourceplot(cfg,i1(1));
    ft_sourceplot(cfg,iprob(1));

    row = max(length(stat2.posclusters),length(stat2.negclusters));
    statvalpos = zeros(row,4);
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
    
    nclust = 1;
    value  = 'neg'; % 'neg'
    %title  = [ROI,' ',seed,' ', cdtn,' ', value,' clust 1'];
    mous_corrmnebf_selstatclus(nclust,stat2,value,[])

    nclust = 1;
    value  = 'pos'; % 'neg'
    %title  = [ROI,' ',seed,' ', cdtn,' ', value,' clust 1'];
    mous_corrmnebf_selstatclus(nclust,stat2,value,[])
    
end  % end dodesc


% figure;plot(stat.time,stat.stat)
% 
% bnd=mous_inflatedmesh(subjectname)
% stat.pos=bnd.pos;
% stat.tri=bnd.tri;
% 
% stat=rmfield(stat,'label');
% stat.dimord='pos_time';
% stat.inside=1:8196;
% 
% cfgp.parameter='stat';
% figure;ft_sourcemovie(cfgp,stat)


