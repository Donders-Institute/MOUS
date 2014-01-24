function mous_corrmnebf_visualise(subjectnames)

% This function visualises the correlation matrix of MNE vertices by Beamforming voxels
% The matrix can be of a single subject or a group ('groupresults')
% cfg defines the filename which requires specification of which
% - 'savebf': toi for beamforming solution
% - 'savemne': toi for MNE solution
% - cdtn (condition): sent/seq/svs (sentence versus sequence)
% - suff: frequency of interest as a string variable

dovis           = false;
dosinglevis     = false;
doROIvis        = false;
dovolplot       = false;

if dovolplot
    % 1
    tmp=source3dsen.corrmat; 
    tmp(tmp>0)=nan;   % keep -ve values (remove all values greater than 0)
    dum(sourcemodel.inside) = nanmean(tmp,1);
    figure; volplot(dum,'montage'); colobar; 
    set(gcf,'name',[subjectnames{1},'avgd ERF seeds to whole TFR brain']);

    % 2
    tmp=source3dsen.corrmat;
    tmp(tmp>0)=nan;
    dum(sourcemodel.inside) = nanmean(tmp,2);
    figure;volplot(dum,'montage'); colobar; 
    set(gcf,'name',[subjectnames{1},'avgd TFR seeds to whole ERF brain']);

    % 3
    tmp=source3dsen.corrmat;
    dum(sourcemodel.inside) = nanmean(sign(tmp),1);
    figure; volplot(dum,'montage'); colobar; 
    set(gcf,'name',[subjectnames{1},'general pic: avgd ERFseed to TFR']);
    % "general" because values are either +ve or -ve, actually values not use

    % 4
    tmp=source3dsen.corrmat;
    dum(sourcemodel.inside) = nanmean(sign(tmp),2);
    figure; volplot(dum,'montage'); colobar; 
    set(gcf,'name',[subjectnames{1},'general pic: avgd ERFseed to TFR']);


    % 5
    tmp = source3dsen.corrmat;
    dum(sourcemodel.inside) = nanmean(abs(tmp),1);
    figure; volplot(dum,'montage'); colobar; 
    set(gcf,'name',[subjectnames{1}, 'general pic: avgd TFRseed to ERF']);

    % 6 - not plotted in corrmnebf volplot.docx
    tmp = source3dsen.corrmat;
    dum(sourcemodel.inside) = nanmean(abs(tmp),2);
    figure; volplot(dum,'montage'); colobar; 
    set(gcf,'name',[subjectnames{1}, 'avgd absolute values of TFRseed to ERF']);

end


if dovis
    %% visualise
    param.range       = 'medium';
    param.foi         = 16;        
    param.toie        = [0.35 0.45];  % toi for ERFs
    param.selfq       = [-0.12 -0.08];
    param.toi         = [];           % toi for TFR % not neded because selfq defines  toi
    param.suff        = num2str(param.foi);   
    param.savebf      = regexprep(num2str(mean(param.selfq)),'[.]','');
    param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]',''); 
    param.cdtn        = 'sen'; % 'seq'
    
    % correlation matrix
    mous_db_getdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',suff,'Hz_',param.cdtn]);
    
    % create grid 
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    grid = load(fname);
    grid = grid.sourcemodel;
    % change position of sources in the data to match the grid 
    % (NOT the other way around: <grid.inside = grid.inside(:,dataAvg.inside);>
    % sourcemodel.inside and .outside only dicate which sources are where by index number, but not the actual location 
    % positions are stored in "source.pos"  
   
    mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn]);
    
    grid.insideold = grid.inside;
    grid.inside    = source.inside;
    grid.outside   = setdiff(1:size(grid.pos,1), source.inside);
    dataAvg.pos    = grid.pos(source.inside,:);

%     mous_connectivitybrowser(grid,dataAvg,'parameter','corrmat','method',{'slice','slice'});
    val = 0.05
    mous_connectivitybrowser(grid,dataAvg,'parameter','corrmat','method',{'slice','slice'},'anasc',[-val val],'cohsc',[-val val]);
end

if dosinglevis
    % set parameters
    param.range       = 'medium';
    param.foi         = 16;        
    param.toie        = [0.35 0.45];  % toi for ERFs
    param.selfq       = [-0.12 -0.08];
    param.toi         = [];           % toi for TFR % not neded because selfq defines  toi
    param.suff        = num2str(param.foi);   
    param.savebf      = regexprep(num2str(mean(param.selfq)),'[.]','');
    param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]',''); 
    param.cdtn        = 'sen'; % 'seq'
    
    cfginterp = [];
    cfginterp.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];
    cfginterp.erf = 'meg_anatomy_sourcemodel2D';
    cfginterp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];
    
    % define ROI
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
    
    roi(6).x = 5; 
    roi(6).y = 17;
    roi(6).z = 17;
    roi(6).seed = 'ERFseed';
    roi(6).cdtn = param.cdtn;
    roi(6).area = 'Rfrontal2';
    
    % get sourcemodel 
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    load(fname);

    % adjust sourcemodel size from [1 x 5798] to [1 x 5782], & limit the inside sources
    mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn]);
    sourcemodel.inside    = source.inside;
    sourcemodel.outside   = setdiff(1:size(sourcemodel.pos,1), source.inside);
    if isfield(sourcemodel,'cfg')
        sourcemodel = rmfield(sourcemodel,'cfg');
    end
    rmf = {'xgrid','ygrid','zgrid','unit'}; sourcemodel = rmfield(sourcemodel,rmf);
            
    for scnt = 1:numel(subjectnames)
        % get correlation matrix & interpolate it
        % mous_db_getdata(subjectnames{scnt},['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn]);
        [source3dsen] = mous_corrmnebf_interpolate(subjectnames{scnt},cfginterp);  % output is verts X voxels
        if isfield(source3dsen, 'cfg')
            source3dsen = rmfield(source3dsen,'cfg');
        end

        % create ROI and select it from data
        load /home/language/nielam/MOUS_AnalysisNotes/corrmnebf/corrmnebf_wholeheadcoord.mat
        dum=zeros(stat.dim);
        sub2ind(stat.dim,roi(rcnt).x,roi(rcnt).y,roi(rcnt).z);
        dum(roi(rcnt).x-1:roi(rcnt).x+1,roi(rcnt).y-1:roi(rcnt).y+1,roi(rcnt).z-1:roi(rcnt).z+1)=1;
        sel = find(dum);
        idxROI = find(ismember(sourcemodel.inside,sel));   

        tmp  = source3dsen.corrmat(:,idxROI); % select TFR seed and average across ERF voxel (rows))
        dat = sourcemodel;
        dat.avg.pow = zeros(1,11000);
        dat.avg.pow(sourcemodel.inside) = nanmean(tmp,2);          
        
        cfg = [];
        cfg.method = 'slice';
        cfg.funparameter = 'avg.pow';
        cfg.funcolorlim = 'maxabs';
        cfg.title       = [subjectnames{scnt},' ',roi(rcnt).area];
        % cfg.atlas = '/home/common/matlab/fieldtrip/template/atlas/afni/TTatlas+tlrc.BRIK'; % superimpose ROIs onto afni brain atlas
        ft_sourceplot(cfg,dat);
    end 
end 


if doROIvis
    % define ROI
    cfg = [];
    cfg.method = 'ortho';
    cfg.funcolorlim = 'maxabs';
    cfg.funparameter = 'stat';
    ft_sourceplot(cfg,stat);

    dum=zeros(stat.dim);
    sub2ind(stat.dim,x,y,z);
    dum(x-1:x+1,y-1:y+1,z-1:z+1)=1;
    selroi = find(dum);
      
    % get correlation data "dataAvg" 
    mous_db_getdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',cfg.savebf,'mne',cfg.savemne,'_',cfg.suff,'Hz_',cfg.cdtn]);
   
    % get sourcemodel
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    grid = load(fname);
    grid = grid.sourcemodel;
    
    % adjust sourcemodel size from [1 x 5798] to [1 x 5782]
    mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_',cfg.savebf,'_',cfg.suff,'Hz_',cfg.cdtn]);
    
    grid.insideold = grid.inside;
    grid.inside    = source.inside;   % average template adapted to MOUS data
    grid.outside   = setdiff(1:size(grid.pos,1), source.inside);
    dataAvg.pos    = grid.pos;
        
    % find voxels in sourcemodel that correspond to sel 
    idxROI = find(ismember(grid.inside, selroi));
    
    % create ROIs
    ROI = grid;                          % establish new sourcedata structure 
    tmp = dataAvg.corrmat(idxROI,:)';    % specify voxels (rows) of interest
    tmp = mean(tmp,2);      % average across voxels  
    tmp(dof(:,1)<20) = 0;   % remove values that are <10 in dof otherwise they 'outshine' the other voxels
    
    % plot ROI's correlation with other regions
    ROI.avg.pow = zeros(11000,1);               % make whole brain 0-power
    ROI.avg.pow(grid.inside) = tmp;    % only insert power values for ROI
    
    %% plot with atlas
    ROI.pow = ROI.avg.pow;  % doesn't work when calling sub-sub field
    interpROI = mous_bfica_sourceinterpolate(ROI,'pow');
    interpROI.coordsys = 'spm';

    cfg = [];
    cfg.method      = 'slice';
    cfg.funparameter = 'pow';
    cfg.funcolorlim = 'maxabs';
    % superimpose ROIs onto afni brain atlas
    cfg.atlas='/home/common/matlab/fieldtrip/template/atlas/afni/TTatlas+tlrc.BRIK';
    ft_sourceplot(cfg,interpROI);

    
    %% plot without atlas
%     cfg = [];
%     cfg.method = 'ortho'; %
%     % cfg.method = 'slice'; 
%     cfg.funparameter = 'avg.pow';
%     cfg.funcolorlim  = 'maxabs';
%     ft_sourceplot(cfg,ROI);                  
end 
