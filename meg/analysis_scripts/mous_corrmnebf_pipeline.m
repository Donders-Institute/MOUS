% mous_corrmnebf_pipeline
% trial == a single word (not averaged across word position)
% 
% This function source level analysis for ERFs and TFRs and then correlates
% their activity together.
% 
% (1) ERFs done using Minimum Norm Estimate 
% (2) TFRs done using Beamforming.
% the trials are matched between ERFs sand TFRs
% currently (11-2-2013) the trials used for baselining ERFs are only chosen from trials which 
% contain the time window of interest. Theoretically,however, we could
% profit from using all available trials because much of the baseline is
% removed in artifact detection as many participant blink during fixation
% cross (before first word onset).
% 
% The source level outcomes:
% ERF: vertices by trials (cov;  TFR: voxels by trials (3D grid)
% A covariance matrix is created by correlation 
% It creates a matrix:  N-vertices by M-number of trial for each subject 
% - Although averaged across subjects, the MNE is calculate for each subject
%   in order to account for differences in noise matrix covariance and variance in the head model.
% - Here each trial represents a word, and a particular time interval of
%   interested can be selected for that word e.g., 250 - 500ms
% the next step: to average the vertices*trial matrix across subjects

%   
% list ={'V1004'  'V1005'    'V1007'    'V1010'   'V1011'    'V1012' ...
%        'V1013'  'V1015'    'V1016'    'V1017'   'V1019'    'V1020'    'V1021'    'V1022' ...
%        'V1024'  'V1025'    'V1026'    'V1027'   'V1028'    'V1029'    'V1030'    'V1031'    'V1032' ...
%        'V1033'  'V1034'    'V1035'    'V1036'   'V1037'    'V1038'    'V1039'    'V1040'    'V1042' ...
%        'V1044'  'V1045'    'V1046'    'V1049'   'V1050'    'V1052'    'V1066'    'V1067'    'V1068' ...
%        'V1071'  'V1072'    'V1077'    'V1078'   'V1079'};

% Always exclude V1014 V1018 V1041 V1043 V1047 V1051 V1056 V1060 V1082 V1091

mous_db_makesubjdir(subjectname)

%% select toi [-0.2 0.5] 
%  only baseline [0 0.6] for analysing 

mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}'); % 360 samples for full trials

cfg = [];
cfg.latency = [-0.2 0.6];  % select trials such that those used for baseline == those used for analyses
data = ft_selectdata(cfg,data);       % altho, we could probably use as many as possible trials for baseline.
nsmp  = cellfun('size',data.trial,2); % 0.7*300 = 240; data.trial{k}(end) = 0.5967
smpfull = find(nsmp == 240);          % V1004: data.time{k}(1) == -0.1967 (not -0.2 like others) 
data = ft_selectdata(data,'rpt',smpfull); % only complete trials (i.e. no shortening due to artifact removal)


%% baseline ERFs manually
all = size(data.trial,2);
bslavgMat = ft_selectdata(data, 'rpt', all,'avgoverrpt','yes','toilim',[-0.2 0]);  
bslavgVec = mean(bslavgMat.trial{1},2);  % avg across timepoints(columns)

% redefine toi for erf analyses to exclude baseline section 
cfg = [];
cfg.latency = [0 0.6]; % now 180 samples
data = ft_selectdata(cfg,data); 

% compute baseline normalization for each trial
rows = 1; columns = size(data.trial{1},2);  % matrix dim for each trial
bslrep = repmat(bslavgVec, [rows columns]);               % replicate bslvector to fit size of toi trials

for k = 1:size(data.trial,2)
    data.trial{k} = data.trial{k}-bslrep;     
end

mous_db_putdata(subjectname, 'meg_corrmnebf_erfsingletrialbsld_0-06','data');
%% match trials between ERFs and TFRs

rootdir = '/home/language/jansch/public/mous/';
suff = '';
mous_db_getdata(subjectname, ['meg_bfica_freq',suff], rootdir);

erf = data.trialinfo(:,1)*1000+data.trialinfo(:,5);  
tfr = freq.trialinfo(:,1)*1000+freq.trialinfo(:,5);  
[comm, ierf, itfr] = intersect(erf, tfr);            % common words w/ loi 

% if TFRs trials == ERFs, then the following 2 lines are redundant, but that is okay.
freq = ft_selectdata(freq,'rpt',itfr);
data = ft_selectdata(data,'rpt',ierf);  

mous_db_putdata(subjectname, 'meg_corrmnebf_erfsingletrialbsld_0-06', 'data');
mous_db_putdata(subjectname, 'meg_corrmnebf_tfrsingletrial_0-06', 'freq');

%% Time Locking & Covariance matrix
% compute covariance matrix of the noise
cfg              = [];
cfg.vartrllength = 2;
cfg.feedback     = 'textbar';
cfg.covariance   = 'yes';
cfg.covariancewindow = [-inf 1]; % calculate the covariance matrix for timepoints before the zero-time point (onset of word) 
cfg.preproc.demean = 'yes';
cfg.channel        = {'MEG', '-EEG057', '-EEG058'};
cfg.preproc.baselinewindow = [-inf 0];
tlck = ft_timelockanalysis(cfg, data);  % actual timelocked data is not used, we only need sensor positions and the noise cov. matrix

%% models
sourcemodel = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');  
if ~isfield(sourcemodel, 'pos') && isfield(sourcemodel, 'pnt')
    sourcemodel.pos  = sourcemodel.pnt;
    sourcemodel      = rmfield(sourcemodel, 'pnt');
end

mous_db_getdata(subjectname,  'meg_anatomy_headmodel'); 

%% Compute the leadfields
% Forward solution  
cfg             = [];
cfg.grad        = tlck.grad;  % sensor positions
cfg.vol         = vol;
cfg.grid        = sourcemodel;
cfg.channel     = {'MEG', '-EEG057', '-EEG058'};
cfg.feedback    = 'textbar';
sourcemodel     = ft_prepare_leadfield(cfg);  
% sourcemodel.leadfield is {1 x 8196 vertices}, each vertex holds [273 channel x 3 orientation]

% calculate sources
cfg                     = [];
cfg.channel             = {'MEG', '-EEG057', '-EEG058'};
cfg.method              = 'mne';
cfg.vol                 = vol;
cfg.grid                = sourcemodel;
cfg.mne.prewhiten       = 'yes';
cfg.mne.lambda          = 3; % used to be 2
cfg.mne.scalesourcecov  = 'yes';
cfg.mne.keepfilter      = 'yes';
source                  = ft_sourceanalysis(cfg, tlck);  % noise covariance matrix used here

cfg            = [];
cfg.demean     = 'yes';
cfg.projectmom = 'yes';
cfg.zscore     = 'no';
sd             = ft_sourcedescriptives(cfg, source);

% sd gives description of sources:
% sd.avg.ori == 3 vectors (x,y,z) describing location of vector (that moves over time)
% sd.avg.filter == how to weigh sensor level data (all channels) to project to source level
% sd.pos == [8196 x 3], what does "3" stand for?

%% create the vertex x channel spatial filter matrix
mnefilter = zeros(size(sd.pos,1), size(sourcemodel.leadfield{1},1));  % 8196 x 273
% calc filter for each vertex 
% one filter for each channel: project sensor lvl data to source lvl (each vertex)
for k = 1:size(mnefilter,1)
    mnefilter(k,:) = sd.avg.ori{k}*sd.avg.filter{k}; 
end

% apply filter to data; output is amplitude of trial
vertM = nan(size(mnefilter,1), numel(data.trial));  
for k = 1:numel(data.trial)   
    tmp = mnefilter*data.trial{k}(1:273,:); 
    tmp = nanmean(abs(tmp),2);  
    vertM(:,k) = tmp; 
end

% vertex*trial data, trialinfo, MNE filter; source (+noise covariance matrix in source.avg); sd;
mous_db_putdata(subjectname,'meg_corrmnebf_mnesingletrial_0-06','vertM','mnefilter','source','sd','tlck');


%% Beamformer calculation 

% source analysis
toi = 0.3;
mous_db_getdata(subjectname, 'meg_corrmnebf_tfrsingletrial_0-06');
[source, trialinfo] = mous_bfica_source(subjectname, freq, toi);
mous_db_putdata(subjectname, 'meg_corrmnebf_sourcesingletrial_0-06');

% sourcedata analysis
sourcedata = mous_bfica_sourcedata(source, freq, toi);
mous_db_putdata(subjectname, 'meg_corrmnebf_sourcedatasingletrial_0-06','sourcedata');

%% Covariance & Correlation Calculation

% mous_db_getdata(subjectname,'meg_corrmnebf_sourcedatasingletrial_0-06');
% mous_db_getdata(subjectname,'meg_corrmnebf_mnesingletrial_0-06');  

voxM  = sourcedata.trial{1}; 

% Remove column(s) with NaN in TFR sourcedata (and remove same column in MNE data)
idxNan = find(isnan(voxM(1,:))); % check first row of each column for NaN (assume that it's entire column with NaN)
if ~isempty(idxNan)
    voxM(:,idxNan) = [];
    vertM(:,idxNan) = [];
end

% mean subtraction (centre data)
voxM  = voxM - repmat(mean(voxM,2),[1 size(voxM,2)]);
vertM = vertM - repmat(mean(vertM,2),[1 size(voxM,2)]);

covVoxvert = voxM*vertM';
varVox = sum(voxM.^2,2);  % Only diagonal elements of covariance matrix (A*A') == variance of A; need not do full A*A' multiplication and subsequently select m*m values
varVert = sum(vertM.^2,2); 

% remove variance from each element
cor = covVoxvert./sqrt(varVox*varVert'); 


% plot
% h = imagesc(cor, [0 1]);
% colormap(jet);
% colorbar; 
mous_db_putdata(subjectname,'meg_corrmnebf_corVoxvert','cor');

%% group average 

% load corrM from all subjects
% for k = 1:numel(subjlist)
%     corPtp(k) = mous_db_getdata(subjlist{k},'meg_processed_{_corVoxvert}');
% end 
% 
% average
% tmp          = cat(3,test{:});  % 3rd Dimension = subjects
% corXptp      = mean(allVTmat,3);


%% Surfaces & saving 

% bndinflated = mous_inflatedmesh(subjectname);
% bnd     = mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D');
% sd.tri = bnd.tri;
% sd.pos = bnd.pos; % surface
% sd.pos_infl = bndinflated.pos; % inflated 
% 
% % do the normalisation to get a 'dSPM'
% npnt = size(sd.pos,1);
% sd.avg.dspm = spdiags(1./sd.avg.noise,0,npnt,npnt)*sd.avg.pow;

%% Movie visualization
% sd.pos = sd.pos_infl;
% 
% figure
% cfg = [];
% cfg.funparameter = 'avg.dspm'; %avg.pow
% ft_sourcemovie(cfg,sd);


  


