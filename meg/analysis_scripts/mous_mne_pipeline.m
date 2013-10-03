if ~exist('suffix_rawdata', 'var')
  suffix_rawdata = 'meg_processed_{_preProcERFvisual_word_all_02-1ds}';
end
if ~exist('suffix_erfdata', 'var')
  suffix_erfdata = 'meg_processed_{_erf_visual_word_all_02-1ds-ag}';
end
if ~exist('suffix_mnedata', 'var')
  suffix_mnedata = strrep(suffix_rawdata, 'erf', 'mne');
end
if ~exist('rootdir', 'var')
  rootdir = '/project/3011020.09/MEG';
end

% compute covariance matrix of the noise
% use an equal amount of sentence and sequence 'baselines' for the cov
mous_db_getdata(subjectname, suffix_rawdata, rootdir);

data     = ft_selectdata(data, 'toilim', [-inf 0.6]);
database = ft_selectdata(data, 'toilim', [-inf 0]);
selsent  = find(ismember(database.trialinfo(:,2),[1 2 5 6]) & database.trialinfo(:,end)==1);
selseq   = find(ismember(database.trialinfo(:,2),[3 4 7 8]) & database.trialinfo(:,end)==1);
n        = min(numel(selsent),numel(selseq));
tmp      = randperm(numel(selsent));selsent=sort(selsent(tmp(1:n)));
tmp      = randperm(numel(selseq));selseq=sort(selseq(tmp(1:n)));

cfg                  = [];
cfg.channel          = 'MEG';
cfg.vartrllength     = 2;
cfg.feedback         = 'textbar';
cfg.covariance       = 'yes';
cfg.covariancewindow = [-inf 0]; % timepoints that are before the zero-time point in the trials 
cfg.preproc.demean   = 'yes';
cfg.preproc.baselinewindow = [-inf 0];
cfg.keeptrials       = 'no';
cfg.trials           = sort([selsent(:);selseq(:)]);
tlck = ft_timelockanalysis(cfg, database);

% load the 2D sourcemodel and deal with the midline
mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D_surfreg'); 
if exist('bnd', 'var')
  sourcemodel = bnd; clear bnd;
end

load atlas_conte69_8196reg
sourcemodel.inside  = find(atlas.parcellation3==1);% & atlas.parcellation2~=1);
sourcemodel.outside = find(atlas.parcellation3==2);% | atlas.parcellation2==1);
sourcemodelorig     = sourcemodel;

% load the volume conductor model of the head
mous_db_getdata(subjectname, 'meg_anatomy_headmodel');
if exist('vol', 'var')
  headmodel = vol; clear vol;
end
headmodel = ft_convert_units(headmodel, 'cm');

% Compute the leadfields
cfg          = [];
cfg.grad     = tlck.grad;
cfg.vol      = headmodel;
cfg.grid     = sourcemodel;
cfg.channel  = 'MEG';
cfg.feedback = 'textbar';
%cfg.normalize = 'yes';
sourcemodel  = ft_prepare_leadfield(cfg);


%% Compute MNE for each condition

% this is a bit clunky, but in order to make the pipeline general purpose
% (i.e. using uniform variable names), it has to try out the possible
% naming schemes Annika adopted in the preprocessed data files. The if else
% etc needs to be extended when needed. Now only assume the first case.
% FIXME, also make the filename configurable, because now it will always
% work.
mous_db_getdata(subjectname, suffix_erfdata, rootdir);
if exist('senWord_AG', 'var')
  data1 = senWord_AG;
  data2 = seqWord_AG;
else
  error('don''t know which variable to use');
end
data1.cov = tlck.cov; % add the covariance computed from both conditions
data2.cov = tlck.cov;

data1 = ft_selectdata(data1, 'toilim', [-inf 0.6]);
data2 = ft_selectdata(data2, 'toilim', [-inf 0.6]);

cfg                 = [];
cfg.method          = 'mne';
cfg.vol             = headmodel;
cfg.grid            = sourcemodel;
cfg.mne.prewhiten   = 'yes';
cfg.mne.lambda      = 3; % used to be 2
cfg.mne.scalesourcecov  = 'yes';
cfg.mne.keepfilter  = 'yes';
cfg.mne.noiselambda = 0.2*trace(data1.cov)./size(data1.cov,1);
source_sent         = ft_sourceanalysis(cfg, data1);
source_seq          = ft_sourceanalysis(cfg, data2);

cfg            = [];
cfg.demean     = 'yes';
cfg.projectmom = 'yes';
cfg.zscore     = 'no';

% we probably don't want the projection to be condition specific, rather
% compute the orientation on the conditions combined.

sd_Sent        = ft_sourcedescriptives(cfg, source_sent);
sd_Seq         = ft_sourcedescriptives(cfg, source_seq);

source         = source_sent;
% source.avg.pow = (source_sent.avg.pow+source_seq.avg.pow)./2;
for k = 1:numel(source.inside)
  mom = (source.avg.mom{source.inside(k)} + source_seq.avg.mom{source.inside(k)})./2;
  source.avg.mom{source.inside(k)} = mom;
end
sd             = ft_sourcedescriptives(cfg, source);
sd_Seq.avg.ori = sd.avg.ori;
sd_Sent.avg.ori = sd.avg.ori;
% replace the pow with the orientation from the combined data
for k = 1:numel(sd.inside)
  indx = sd.inside(k);
  sd_Sent.avg.pow(indx,:) = abs(sd.avg.ori{indx}*source_sent.avg.mom{indx});
  sd_Seq.avg.pow(indx,:)  = abs(sd.avg.ori{indx}*source_seq.avg.mom{indx});
end

sd_Sent.tri = sourcemodelorig.tri;
sd_Seq.tri  = sourcemodelorig.tri;

% do the normalisation to get a 'dSPM'
npnt = size(sd_Sent.pos,1);
sd_Sent.avg.dspm = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Sent.avg.pow;
sd_Seq.avg.dspm  = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Seq.avg.pow;

sd_Sent.avg = rmfield(sd_Sent.avg, 'mom');
sd_Seq.avg  = rmfield(sd_Seq.avg,  'mom');

% save the solution
source = sd_Seq;
mous_db_putdata(subjectname, [suffix_mnedata,'-seq'],  'source', rootdir);

source = sd_Sent;
mous_db_putdata(subjectname, [suffix_mnedata,'-sent'], 'source', rootdir);

