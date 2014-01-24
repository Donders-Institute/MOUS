%% mous_corrmnebf_sentseq_pipeline

% does the same as mous_corrmnebf_pipeline except that now it compares two
% conditions, instead of one condition to 0.

mous_db_makesubjdir(subjectname)

% step 2: 
%     % analyses on specific toi's
        suff        = '16';         % ''
        foi         = 16;           % []
        savebf      = '-01';        % central frequency:  0.1, for 0.08 to 0.12 for TFR toi
        savemne     = '035045';
        toie        = [0.35 0.45];  % toi for ERFs
        toi         = [];           % toi for TFR % not neded because selfq defines  toi
        %sencdtn     = [1 2 5 6];   % sentences only!
        sencdtn     = [1 2 3 4 5 6 7 8];
        cdtn        = 'svs';        % if cdtn = [] then it is sent 
        selfq       = [-0.12 -0.08];
%         doselfreq   = true;
%         doselerf    = true; 
%         domatchef   = true;    % only use trials for which there is an ERF and Osc present
%         domatchtrl  = true;    % have same number of trials in
%         domnesingle = true;
%         dobeam      = true;
%         doregwordorder = true; 
        dogrpavg    = false;
       

%% OSCILLATIONS select frequency and cdtn
    
if ~isempty(foi)
    rootdir = '/home/language/jansch/public/mous/';      % all the low frequencies, where freq.freq = [2.5 5 7.5 10 12]
    mous_db_getdata(subjectname,'meg_bfica_freq_medium',rootdir);
    freq = ft_selectdata(freq,'foilim',foi*[1 1]);
else
    mous_db_getdata(subjectname,'meg_corrmnebf_freq');  % beta (20Hz)
end 

warning off;
freq   = ft_struct2double(freq);
warning on;
sidx   = find(ismember(freq.trialinfo(:,2),sencdtn));
freq   = ft_selectdata(freq,'rpt',sidx);

cfg = [];
cfg.latency = [selfq(1) selfq(2)];  
freq        = ft_selectdata(cfg,freq); 
idxful      = find(~isnan(freq.fourierspctrm(:,1,1,1)));  % remove trials with missing data due to artifact rejection
freq        = ft_selectdata(freq,'rpt',idxful);  


%% ERF select only the sentences and baseline normalise
mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}'); 
sentidx     = find(ismember(data.trialinfo(:,2),sencdtn));
data        = ft_selectdata(data,'rpt',sentidx);

% calc baseline
all = size(data.trial,2);
bslavgMat = ft_selectdata(data, 'rpt', all,'avgoverrpt','yes','toilim',[-0.2 0]);  
bslavgVec = mean(bslavgMat.trial{1},2);  % avg across timepoints(columns)

% apply baseline (normalize); adjust baseline to fit each trial's dimensions)
for k = 1:size(data.trial,2)
    rows = 1; columns = size(data.trial{k},2);  % matrix dim for each trial
    bslrep = repmat(bslavgVec, [rows columns]); % replicate bslvector to fit size of toi trials
    data.trial{k} = data.trial{k}-bslrep;     
end

% select toi 
cfg = [];
cfg.toilim = [toie(1) toie(2)];
data       = ft_selectdata(cfg,data);     

% take only trials with full number of samples (no artifacts removed)
erftime = toie(2) - toie(1);
corrsmp = (erftime*300)+1;
if strcmp(subjectname,'V1011')
    corrsmp = 90;
end

nsmp = cellfun('size',data.trial,2);
fulltrial = find(nsmp == corrsmp);    
data = ft_selectdata(data,'rpt',fulltrial);


%% match trials between ERFs and TFRs
% find matching trials
erf = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
tfr = freq.trialinfo(:,1)*1000+freq.trialinfo(:,5);  
[comm, ierf, itfr] = intersect(erf, tfr);    % comm = same trials in both

% exclude non-matching trials from both datasets
freq = ft_selectdata(freq,'rpt',itfr);
data = ft_selectdata(data,'rpt',ierf);      

%% match number of trials between conditions (sent and seq) for each measure (ERF, Osc) separately
T = freq.trialinfo(:,2);
sel1 = find(ismember(T, [1 2 5 6])); n1 = numel(sel1);
sel2 = find(ismember(T, [3 4 7 8])); n2 = numel(sel2);

n = 408;  % hardcoded.  Checked 72 subjects, and minimum number of sequences from participant 21 is 408.
tmp1 = randperm(n1);
tmp2 = randperm(n2);
sel1 = sel1(sort(tmp1(1:n)));
sel2 = sel2(sort(tmp2(1:n)));

%     sel = [sel1(:);sel2(:)];
%     freq = ft_selectdata(freq, 'rpt', sel);
freqSen = ft_selectdata(freq, 'rpt', sel1);
freqSeq = ft_selectdata(freq, 'rpt', sel2); 

%% after randomly determining the trials for freq, select the same ones for ERFs
% SENTENCES
erfSen = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
tfrSen = freqSen.trialinfo(:,1)*1000+freqSen.trialinfo(:,5);  
[comm, ierf, itfr] = intersect(erfSen, tfrSen);    % comm = same trials in both

    % exclude non-matching trials from both datasets
freqSen = ft_selectdata(freq,'rpt',itfr);
dataSen = ft_selectdata(data,'rpt',ierf);

% SEQUENCES
erfSeq = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
tfrSeq = freqSeq.trialinfo(:,1)*1000+freqSeq.trialinfo(:,5);  
[comm, ierf, itfr] = intersect(erfSeq, tfrSeq);    % comm = same trials in both

    % exclude non-matching trials from both datasets
freqSeq = ft_selectdata(freq,'rpt',itfr);
dataSeq = ft_selectdata(data,'rpt',ierf);


%% beamformer  - calculated separately to obtain separate matrices for each condition
% sentences
freqSen.calc = 1;
freqSen = rmfield(freqSen,'time');
freqSen.dimord = 'rpttap_chan_freq'; 
[source, trialinfo] = mous_bfica_source(subjectname, freqSen, toi, 8);
if ~isempty(foi)
    freqSen.cumtapcnt = ones(size(freqSen.fourierspctrm,1),1);
end 
sourcedataSen = mous_bfica_sourcedata(source, freqSen);
if ~isempty(foi)
    mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn,'_sen'],'source','sourcedata','trialinfo','freqSen');
else
    mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_',cdtn,'_sen'],'source','sourcedata','trialinfo','freqSen');
end 


% sequences 
freqSeq.calc = 1;
freqSeq = rmfield(freqSeq,'time');
freqSeq.dimord = 'rpttap_chan_freq'; 
[source, trialinfo] = mous_bfica_source(subjectname, freqSeq, toi, 8);
if ~isempty(foi)
    freqSeq.cumtapcnt = ones(size(freqSeq.fourierspctrm,1),1);
end 
sourcedataSeq = mous_bfica_sourcedata(source, freqSeq);
if ~isempty(foi)
    mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn,'_seq'],'source','sourcedata','trialinfo','freqSeq');
else
    mous_db_putdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_',cdtn,'_seq'],'source','sourcedata','trialinfo','freqSeq');
end 


%% calculate sources for each trial

% Noise covariance matrix is calculate using stim for all conditions,
% so it doesnt matter if I load it from Sent or Seq.
% what does matter is that I get the correct MNE estimate averaged
% across all trials of interest

% SENTENCES
mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Sent_20130502}');
% create the vertex x channel spatial filter matrix
mnefilter = zeros(size(sd_Sent.pos,1), size(grid.leadfield{1},1));  % 8196 x 273
for k = 1:size(mnefilter,1)
    mnefilter(k,:) = sd_Sent.avg.ori{k}*sd_Sent.avg.filter{k}; 
end

channel  = {'MEG', '-EEG057', '-EEG058'};
data     = ft_selectdata(data,'channel',channel);

% tlck avg of all toi sentences
cfg = [];
tlck = ft_timelockanalysis(cfg, data);
mnetlck = mnefilter*tlck.avg;
nword   = numel(data.trial);

% MNE filter for jack knife
vertM = nan(size(mnefilter,1), numel(data.trial));  
for k = 1:numel(data.trial)   
    tmp = (mnetlck.*nword-mnefilter*data.trial{k})./(nword-1); % (:,toie(1):toie(2));  % [8196*273] * [273 * xx timepoints] 
    %tmp = mnefilter*data.trial{k};
    tmp = nanmean(abs(tmp),2); 
    vertM(:,k) = tmp;  % Vertices(8196) by Trials (words: number varies depending on artifact rejection and MEG condition)
end

% save output for mous_corrmnebf_interpolate
source = source_sent;
sd = sd_Sent;


if ~isempty(foi)
    mous_db_putdata(subjectname,['meg_corrmnebf_mnesingletrial_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn,'_sen'],'vertM','mnefilter','source','sd');
else
    mous_db_putdata(subjectname,['meg_corrmnebf_mnesingletrial_jack_',savemne,'_bf',savebf,'_',cdtn,'_sen'],'vertM','mnefilter','source','sd');
end 

    
% SEQUENCES
mous_db_getdata(subjectname,'meg_processed_{MNE02-1ds_Allwords_Seq_20130502}');
% create the vertex x channel spatial filter matrix
mnefilter = zeros(size(sd_Seq.pos,1), size(grid.leadfield{1},1));  % 8196 x 273
for k = 1:size(mnefilter,1)
    mnefilter(k,:) = sd_Seq.avg.ori{k}*sd_Seq.avg.filter{k}; 
end  


channel  = {'MEG', '-EEG057', '-EEG058'};
data     = ft_selectdata(data,'channel',channel);

% tlck avg of all toi sentences
cfg = [];
tlck = ft_timelockanalysis(cfg, data);
mnetlck = mnefilter*tlck.avg;
nword   = numel(data.trial);

% MNE filter for jack knife
vertM = nan(size(mnefilter,1), numel(data.trial));  
for k = 1:numel(data.trial)   
    tmp = (mnetlck.*nword-mnefilter*data.trial{k})./(nword-1); % (:,toie(1):toie(2));  % [8196*273] * [273 * xx timepoints] 
    %tmp = mnefilter*data.trial{k};
    tmp = nanmean(abs(tmp),2); 
    vertM(:,k) = tmp;  % Vertices(8196) by Trials (words: number varies depending on artifact rejection and MEG condition)
end

% save output for mous_corrmnebf_interpolate
source = source_seq;
sd = sd_Seq;

if ~isempty(foi)
    mous_db_putdata(subjectname,['meg_corrmnebf_mnesingletrial_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn,'_seq'],'vertM','mnefilter','source','sd');
else
    mous_db_putdata(subjectname,['meg_corrmnebf_mnesingletrial_jack_',savemne,'_bf',savebf,'_',cdtn,'_seq'],'vertM','mnefilter','source','sd');
end 


%% regress out word order and calculate correlation matrix
%     mous_db_getdata(subjectname,'meg_corrmnebf_mnesingletrial_jack_0306_bf01');  % get vertM
%     mous_db_getdata(subjectname, 'meg_corrmnebf_bfsourcesingletrial8mm_01') % get voxM

bfdata = cell(2,1);
mous_db_getdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn,'_sen'])
bfdata{1} = sourcedata.trial{1};
clear sourcedata

mous_db_getdata(subjectname, ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn,'_seq'])
bfdata{2} = sourcedata.trial{1};

for k = 1:2
    voxM  = bfdata{k}; 

    % Remove column(s) with NaN in TFR sourcedata (and remove same column in MNE data)    
    idxNan = find(isnan(voxM(1,:))); 
    if ~isempty(idxNan)
        voxM(:,idxNan) = [];
        vertM(:,idxNan) = [];
    end

    % compute the leave-one-out for the oscillations, the mne has been done
    % already
    voxMsum = sum(voxM,2);
    voxM    = (voxMsum*ones(1,size(voxM,2)) - voxM)./(size(voxM,2)-1);

    % regression    
    [cor, corvox, corvert] = mous_corrmnebf_regression(subjectname, voxM, vertM, trialinfo);

    % saving
    if k == 1
        mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_' cdtn, '_sen'],'cor'); 
    else
        mous_db_putdata(subjectname,['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_' cdtn, '_seq'],'cor'); 
    end      
end 

if dogrpavg
%% group average
% interpolate 2dto3d for each participant prior to averaging (same
% coordinate across subject ~= same brain location) 
cfginterp = [];
cfginterp.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
cfginterp.erf = ['meg_corrmnebf_mnesingletrial_jack_',savemne,'_bf',savebf,'_',suff,'Hz_',cdtn];
cfginterp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_','mne',savemne,'_',suff,'Hz_',cdtn];


    for q = 1:numel(subjectnames)
        % interpolate the correlation matrix to 3d space
        % source   grid
        [source3d, sourcemodel] = mous_corrmnebf_interpolate(subjectnames{q},cfginterp);
        
        tmp = isfinite(source3d.corrmat);  % NaNs are due to interpolation where no value of cortical sheet belong to a particular voxel (gridpoint)
        source3d.corrmat(~isfinite(source3d.corrmat))=0;  % keep track of which participants have NaN in correlation matrix
        if q == 1
            dof  = double(tmp);
            data = source3d;
            inside = source3d.inside;
        else
            dof = double(tmp)+dof;
            data.corrmat = data.corrmat + source3d.corrmat;
        end 
    end
    dataAvg = data;
    dataAvg.corrmat = data.corrmat./dof; % divide only by number of ptps w/o NaNs. 
    if ~isempty(foi)
        mous_db_putdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn],'dataAvg','data','dof');
    else
        mous_db_putdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',cdtn],'dataAvg','data','dof');
    end
    
    
end    

if dostats
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

    %% determine ROI

    load ~jansch/public/mous/scripts/20130530/sourcedata160Hz_sentseq_allwords_nobaseline stat

%     cfg = [];
%     cfg.method = 'ortho';
%     cfg.funcolorlim = 'maxabs';
%     cfg.funparameter = 'stat';
%     ft_sourceplot(cfg,stat);  % plot to determine which voxel drives ROI

    x = 5;  y = 19; z = 11;  % LIFG
%     x = 15; y = 19; z = 5;   % right frontal
%     x = 7;  y = 20; z = 16;  % left frontal
%     x = 6;  y = 7;  z = 17;  % left parietal
%     x = 15; y = 7;  z = 17 ; % right parietal   
    
    dum=zeros(stat.dim);
    sub2ind(stat.dim,x,y,z);
    dum(x-1:x+1,y-1:y+1,z-1:z+1)=1;
    selroi = find(dum);

    % get voxel indices for ROI
    sel = selroi;
    idxROI = find(ismember(sourcemodel.inside,sel));
    
    %% load data for each individual subject and select ROI from corrmat
    cfginterp = [];
    cfginterp.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
    cfginterp.erf = ['meg_corrmnebf_mnesingletrial_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];
    cfginterp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn];

    %% oscillations as source
    sdata = cell(numel(subjectnames),1);
    for k = 1:numel(subjectnames)
        % interpolate
        [source3d, singlegrid] = mous_corrmnebf_interpolate(subjectnames{k},cfginterp);  % output is verts X voxels
        if isfield(source3d, 'cfg')
            source3d = rmfield(source3d,'cfg');
        end

        % contribution of each subject to each voxel
        tmpy = isfinite(source3d.corrmat);
        if k == 1;
            dof = double(tmpy);
        else
            dof = double(tmpy)+dof;
        end 
       % ROI is osc:  
       % corrmat is vertices by voxels!
       %tmp = source3d.corrmat(idxROI,:);    % specify voxels (rows) of interest
       tmp = source3d.corrmat(:,idxROI);
       tmp = nanmean(tmp,2);                 % average across vertices; sometimes, a certain column = NaNs

       sdata{k} = sourcemodel;
       sdata{k}.avg.pow = zeros(1,11000);
       sdata{k}.avg.pow(sourcemodel.inside) = tmp;
    end 
    sdataori = sdata;
        
    
    % account for dof!
    for k = 1:numel(subjectnames)
        %sdata{k}.inside(find(dof(:,1) ~= 72)) = [];
        sdata{k}.inside(find(dof(:,1) <= 60)) = [];
        sdata{k}.outside = setdiff(1:11000,sdata{k}.inside);
        
        sdata2{k}            = sdata{k};
        sdata2{k}.avg.pow(:) = 0;
    end 
    
    
    %% erfs as source
    sdata = cell(numel(subjectnames),1);
    for k = 1:numel(subjectnames)
        % interpolate
        [source3d, singlegrid] = mous_corrmnebf_interpolate(subjectnames{k},cfginterp);  % output is verts X voxels
        if isfield(source3d, 'cfg')
            source3d = rmfield(source3d,'cfg');
        end

        % ROI is ERFs
       tmp = source3d.corrmat(idxROI,:);       % specify vertices of interest
       tmp = nanmean(tmp,1);                      % average across voxels
        
       sdata{k} = sourcemodel;
       sdata{k}.avg.pow = zeros(1,11000);
       sdata{k}.avg.pow(sourcemodel.inside) = tmp;

       sdata2{k}            = sdata{k};
       sdata2{k}.avg.pow(:) = 0;
    end 

    %% montecarlo permutation statistics
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
    stat2 = ft_sourcestatistics(cfg, sdata{:}, sdata2{:}); 
    
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
    cfg.atlas='/home/common/matlab/fieldtrip/template/atlas/afni/TTatlas+tlrc.BRIK';
    ft_sourceplot(cfg,i1);
    
    cfg = [];
    cfg.method  = 'slice';
    cfg.funparameter = 'pow';
    cfg.maskparameter = iprob3;
    ft_sourceplot(cfg,iprob);
    
    nclust = 1;
    mous_corrmnebf_selstatclus(nclust,stat2)
    
end 

%% others

if dovis
    %% visualise
    if ~isempty(foi)
        mous_db_getdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn]);
    else
        mous_db_getdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',cdtn]);
    end
     
     
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    grid = load(fname);
    grid = grid.sourcemodel;
    % change position of sources in the data to match the grid 
    % (NOT the other way around: <grid.inside = grid.inside(:,dataAvg.inside);>
    % sourcemodel.inside and .outside only dicate which sources are where by index number, but not the actual location 
    % positions are stored in "source.pos"  
   
   if ~isempty(foi)  
       mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_',suff,'Hz_',cdtn]);
   else
       mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_',cdtn]);
   end 
    
    grid.insideold = grid.inside;
    grid.inside    = source.inside;
    grid.outside   = setdiff(1:size(grid.pos,1), source.inside);
    dataAvg.pos    = grid.pos(source.inside,:);

    mous_connectivitybrowser(grid,dataAvg,'parameter','corrmat','method',{'slice','slice'});
    mous_connectivitybrowser(grid,dataAvg,'parameter','corrmat','method',{'slice','slice'},'anasc',[-0.0095 0.0095],'cohsc',[-0.0095 0.0095]);
end

if doROIvis
    % load voxels of interest (to form ROI) "sel" 
    load corrmnebf_selvox.mat;
    
    % get correlation data "dataAvg" 
    if ~isempty(foi)
        mous_db_getdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',suff,'Hz_',cdtn]);
    else
        mous_db_getdata('groupresults',['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_bf',savebf,'mne',savemne,'_',cdtn]);
    end
    
    % get sourcemodel
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    grid = load(fname);
    grid = grid.sourcemodel;
    
    % adjust sourcemodel size from [1 x 5798] to [1 x 5782]
    if ~isempty(foi)  
       mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_',suff,'Hz_',cdtn]);
    else
       mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_',savebf,'_',cdtn]);
    end 
    grid.insideold = grid.inside;
    grid.inside    = source.inside;   % average template adapted to MOUS data
    grid.outside   = setdiff(1:size(grid.pos,1), source.inside);
    dataAvg.pos    = grid.pos;
        
    % find voxels in sourcemodel that correspond to sel 
    idxROI = find(ismember(grid.inside, sel));
    
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
    cfg = [];
    cfg.method = 'ortho'; %
    % cfg.method = 'slice'; 
    cfg.funparameter = 'avg.pow';
    cfg.funcolorlim  = 'maxabs';
    ft_sourceplot(cfg,ROI);                  
end 

    