%%visual final data set
%load ~annhul/MOUS/meg/subjects_OK_20130613.mat
%
%for k= 1:numel(subj)

%subjectname = subj{k};

% compute covariance matrix of the noise
mous_db_getdata(subjectname, 'meg_processed_{_preProcERFvisual_word_all_02-1ds}');
data = ft_selectdata(data, 'toilim', [-0.2 0.8], 'channel', 'MEG');

cfg              = [];
cfg.channel      = 'MEG';
cfg.vartrllength = 2;
cfg.feedback     = 'textbar';
cfg.covariance   = 'yes';
cfg.covariancewindow = [-inf 0]; % timepoints that are before the zero-time point in the trials 
cfg.preproc.demean = 'yes';
cfg.preproc.baselinewindow = [-inf 0];
cfg.keeptrials = 'no';
tlck = ft_timelockanalysis(cfg, data);

% load the 2D grid
mous_db_getdata(subjectname,'meg_anatomy_sourcemodel2D_surfreg');  %having grid here and below is confusing

% HACK works for JM probably not for all
% CLEAN THIS UP, i.e. add the stuff to git and load it in a clever way
load('/home/language/jansch/projects/mous/meg/templates/atlas_conte69_8196reg.mat');
bnd.inside  = find(atlas.parcellation3==1);% & atlas.parcellation2~=1);
bnd.outside = find(atlas.parcellation3==2);% | atlas.parcellation2==1);
bndorig     = bnd;


% Use the LR one for the rest
load('/home/language/jansch/projects/mous/meg/templates/atlas_conte69_8196reg_LR.mat');

% load the volume conductor model of the head
mous_db_getdata(subjectname, 'meg_anatomy_headmodel');

% Compute the leadfields
cfg          = [];
cfg.grad     = tlck.grad;
cfg.vol      = vol;
cfg.grid     = bnd;
cfg.channel  = 'MEG';
cfg.feedback = 'textbar';
%cfg.normalize = 'yes';
sourcemodel  = ft_prepare_leadfield(cfg);  %having grid here and above is confusing
clear bnd;

for k = 1:numel(sourcemodel.inside)
  lf      = sourcemodel.leadfield{sourcemodel.inside(k)};
  [u,s,v] = svd(lf,'econ');
  sourcemodel.leadfield{sourcemodel.inside(k)} = lf*v(:,1:2);
  sourcemodel.v{sourcemodel.inside(k)} = v;
end


%% Compute MNE for each condition

% this is a bit clunky, but in order to make the pipeline general purpose
% (i.e. using uniform variable names), it has to try out the possible
% naming schemes Annika adopted in the preprocessed data files. The if else
% etc needs to be extended when needed. Now only assume the first case.
% FIXME, also make the filename configurable, because now it will always
% work.
mous_db_getdata(subjectname,'meg_processed_{_erf_visual_word_all_02-1ds-ag}');
if exist('senWord_AG', 'var')
  data1 = senWord_AG;
  data2 = seqWord_AG;
else
  error('don''t know which variable to use');
end
data1.cov = tlck.cov; % add the covariance computed from both conditions
data2.cov = tlck.cov;

cfg                 = [];
cfg.method          = 'mne';
cfg.vol             = vol;
cfg.grid            = sourcemodel;
cfg.mne.prewhiten   = 'yes';
cfg.mne.lambda      = 3; % used to be 2
cfg.mne.scalesourcecov  = 'yes';
cfg.mne.keepfilter  = 'yes';
cfg.mne.noiselambda = 0.1*trace(data1.cov)./size(data1.cov,1);
source_sent         = ft_sourceanalysis(cfg, data1);
source_seq          = ft_sourceanalysis(cfg, data2);

%% compute per parcel a DSS decomposition that highlights the event-related stuff
selsent = find(ismember(data.trialinfo(:,2), [1 2 5 6]));
selseq  = find(ismember(data.trialinfo(:,2), [3 4 7 8]));
for k = 1:numel(data.trial)
  if data.time{k}(1)<0 && data.time{k}(end)>0
    params.tr{k} = nearest(data.time{k},0);
    params.pre{k} = params.tr{k} - 1;
    params.pst{k} = numel(data.time{k}) - params.tr{k};
  elseif data.time{1}(1)>0
    params.tr{k} = [];%-round(data.time{k}(1)./data.fsample);
    params.pre{k} = [];%0;
    params.pst{k} = [];%numel(data.time{k});
  elseif data.time{1}(end)<0
    params.tr{k}  = [];%round(data.time{k}(end)./data.fsample) + numel(data.time{k});
    params.pre{k} = [];%params.tr{k};
    params.pst{k} = [];%0;
  end
end
params.demean = 'prezero';

paramssent     = params;
paramssent.tr  = paramssent.tr(selsent);
paramssent.pre = paramssent.pre(selsent);
paramssent.pst = paramssent.pst(selsent);
paramssent.computenew = 0;

paramsseq     = params;
paramsseq.tr  = paramsseq.tr(selseq);
paramsseq.pre = paramsseq.pre(selseq);
paramsseq.pst = paramsseq.pst(selseq);
paramsseq.computenew = 0;

addpath /home/language/jansch/matlab/toolboxes/dss2_1-0
cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avg2';
cfg.dss.denf.params   = params;
cfg.dss.wdim          = 20;
cfg.numcomponent      = 10;
cfg.cellmode          ='yes';

doparcel = setdiff(1:86, [1 2 44 45]); % remove the ??? and medial wall
for k = doparcel
  tic;
  selvert = find(atlas.parcellation2==k);
  tmpfilt = cat(1,source_sent.avg.filter{selvert});
  tmpdata = data;
  tmpdata.trial = tmpfilt*tmpdata.trial;
  tmpdata.label = cell(size(tmpfilt,1),1);
  for j = 1:numel(tmpdata.label)
    tmpdata.label{j} = ['chan',num2str(j,'%03d')];
  end
  tmpcomp           = ft_componentanalysis(cfg, tmpdata);
  [~,~,avgcompsent{k}] = denoise_avg2(paramssent, tmpcomp.trial(selsent), s);
  [~,~,avgcompseq{k}]  = denoise_avg2(paramsseq,  tmpcomp.trial(selseq),  s);
  timeelapsed(k,1)=toc;
end

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

sd_Sent.tri = bndorig.tri;
sd_Seq.tri  = bndorig.tri;

% do the normalisation to get a 'dSPM'
npnt = size(sd_Sent.pos,1);
sd_Sent.avg.dspm = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Sent.avg.pow;
sd_Seq.avg.dspm  = spdiags(1./sqrt(sd.avg.noise),0,npnt,npnt)*sd_Seq.avg.pow;

sd_Sent.avg = rmfield(sd_Sent.avg, 'mom');
sd_Seq.avg  = rmfield(sd_Seq.avg,  'mom');

% save the solution
source = sd_Seq;
%mous_db_putdata(subjectname, 'meg_mne_MNEreg02-1ds_target_Seq',  'source','/home/language/jansch/public/mous');
%mous_db_putdata(subjectname, 'meg_mne_MNEregnomidline02-1ds_target_Seq',  'source','/home/language/jansch/public/mous');
%mous_db_putdata(subjectname, 'meg_mne_MNEregnomidlinenormlf02-1ds_target_Seq',  'source','/home/language/jansch/public/mous');
mous_db_putdata(subjectname, 'meg_mne_MNEregnomidlineregC02-1ds_target_Seq',  'source','/home/language/jansch/public/mous');

source = sd_Sent;
%mous_db_putdata(subjectname, 'meg_mne_MNEreg02-1ds_target_Sent', 'source','/home/language/jansch/public/mous');
%mous_db_putdata(subjectname, 'meg_mne_MNEregnomidline02-1ds_target_Sent',  'source','/home/language/jansch/public/mous');
%mous_db_putdata(subjectname, 'meg_mne_MNEregnomidlinenormlf02-1ds_target_Sent',  'source','/home/language/jansch/public/mous');
mous_db_putdata(subjectname, 'meg_mne_MNEregnomidlineregC02-1ds_target_Sent',  'source','/home/language/jansch/public/mous');

%end
  
