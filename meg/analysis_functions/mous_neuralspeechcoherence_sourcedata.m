function mous_neuralspeechcoherence_sourcedata

%%%%%%%%%%%%%%%%%%%%%%
%%% SOURCE LEVEL  %%%%
%%%%%%%%%%%%%%%%%%%%%%
%% calculate cross-spectral density matrix
cfg = [];
cfg.method     = 'mtmfft';  % assumes stable power, but we know this isn't true
cfg.output     = 'fourier'; % not 'powandcsd; compute csd online'
cfg.foi        = 2;         % calculate fourier for each frequency showing a peak in coherence spectrum
cfg.tapsmofrq  = 1;         % 2 Hz smoothing
cfg.taper      = 'dpss';
cfg.keeptrials = 'yes';
cfg.channel    = {'MEG' 'UADC003'};
fourier        = ft_freqanalysis(cfg, data);

% load forward model (headmodel)
headmodel   = mous_db_getdata(subj, 'meg_anatomy_headmodel');

% load sourcemodel   (grid); stick with 5798
mous_db_getdata(subj, 'meg_bfica_leadfield8mm', '/project/3011020.09/nielam/');

cfg = [];
cfg.method    = 'dics';
cfg.frequency = 2;
cfg.grad      = fourier.grad;
cfg.refchan    = 'UADC003';
cfg.vol       = headmodel;
cfg.grid      = sourcemodel;
cfg.dics.fixedori   = 'yes';
cfg.dics.realfilter = 'yes';  % consider real+complex filter; complex may try to rotate back to 'original phase'
cfg.dics.keepfilter = 'yes'; 
cfg.dics.lambda     = '5%';
% cfg.dics.projectnoise = 'yes';
source   = ft_sourceanalysis(cfg, fourier);

mous_db_putdata(subj,'meg_other_neuralspeechcoh4_source','source','/project/3011020.09/MEG/');

%% source level plotting
% interpolate using MRI
% mri = ft_read_mri(which('templateMRI.nii'));
% cfg            = [];
% cfg.parameter  = 'avg.pow';
% cfg.downsample = 2;
% interp         = ft_sourceinterpolate(cfg, source, mri);
% % OR
% i1  = mous_bfica_sourceinterpolate(source2, 'avg.pow', source2.inside); % average across all time points
%    
% 
% % plot
% cfg = [];
% cfg.refchannel = 'UADC003';
% cfg.method        = 'ortho';
% cfg.funparameter  = 'avg.pow';
% % ft_sourceplot(cfg,interp);
% ft_sourceplot(cfg,i1);
