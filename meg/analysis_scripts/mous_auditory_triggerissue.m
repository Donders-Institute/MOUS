%% script that addresses the issue of the screwed up trigger channel in a bunch of subjects

%% this part reads in the audio data for the subjects
clear all
subj = mous_db_getfilename('allA', 'subjectname');
for k = 14:numel(subj)
  try
  [f,s] = mous_db_getfilename(subj{k},'meg_ds_task');
  if s
    cfg          = [];
    cfg.dataset  = f{1};
    cfg.trialfun = 'trialfun_auditory_audio_onoff';
    cfg = ft_definetrial(cfg);
    trl = cfg.trl;
    
    cfg.continuous = 'yes';
    cfg.channel    = {'UPPT001';'UADC004'};
    data = ft_preprocessing(cfg);
    
    mous_db_putdata(subj{k}, 'meg_other_audio', 'data', 'trl');
    end
  end
end

%% this part sequentially processes the audio data in the following way:
% - read in the 'canonical' data
% - read in a subject's data
% - correlate for each trial in the subject data with the canonical data
% - if the correlation is sufficiently high, replace the canonical with the
% average of the canonical trial 
% - else add a new trial to the canonical data

clear all;
subj = mous_db_getfilename('allA', 'subjectname');
[f,s] = mous_db_getfilename(subj, 'meg_other_audio');
subj = subj(s);

cfg = [];
cfg.bsfilter = 'yes';
cfg.bsfreq   = [49 51];
data = ft_preprocessing(cfg,data);
cfg.bsfreq   = [99 101];
data = ft_preprocessing(cfg,data);

mous_db_getdata(subj{1}, 'meg_other_audio');
cfg = [];
cfg.bsfilter = 'yes';
cfg.bsfreq   = [49 51];
data = ft_preprocessing(cfg,data);
cfg.bsfreq   = [99 101];
data = ft_preprocessing(cfg,data);
audiodata = data;
nsmp   = cellfun('size',audiodata.trial,2);
maxsmp = max(nsmp);
maxsmp = 2.^nextpow2(maxsmp);
dat = zeros(maxsmp,numel(audiodata.trial));
for k = 1:numel(audiodata.trial)
  dat(1:nsmp(k),k) = audiodata.trial{k}(2,:)./norm(audiodata.trial{k}(2,:));
end
dat = fft(dat);

for k = 2:numel(subj)
  mous_db_getdata(subj{k}, 'meg_other_audio');
  cfg = [];
  cfg.bsfilter = 'yes';
  cfg.bsfreq   = [49 51];
  data = ft_preprocessing(cfg,data);
  cfg.bsfreq   = [99 101];
  data = ft_preprocessing(cfg,data);
  nsmp   = cellfun('size',data.trial,2);
  maxsmp = max(nsmp);
  maxsmp = 2.^nextpow2(maxsmp);
  dat2 = zeros(maxsmp,numel(data.trial));
  for m = 1:numel(data.trial)
    dat2(1:nsmp(m),m) = data.trial{m}(2,:)./norm(data.trial{m}(2,:));
  end
  dat2 = conj(fft(dat2));
  
  stats = zeros(numel(data.trial),3);
  for m = 1:numel(data.trial)
    if mod(m,20)==0, fprintf('computing correlation between reference trials and subject specific trial %d\n', m); end
    tmp  = real(ifft(dat.*(dat2(:,m*ones(1,size(dat,2))))));
    [mtmp, ix] = max(tmp,[],2);
    [mtmp, iy] = max(mtmp);
    stats(m,:) = [mtmp iy ix(iy)];
  end
  sel = find(stats(:,1)>0.8);
  for m = 1:numel(sel)
    trlix1 = stats(sel(m),3);
    trlix2 = m;
    fprintf('merging trial %d from audiodata with subject-specific trial %d\n', trlix1, trlix2);
    %dat(:,trlix1) = (dat(:,trlix1)+conj(dat2(:,trlix2)))./2;
  end
  data      = ft_selectdata(data, 'rpt', setdiff(1:numel(data.trial), sel));
  audiodata = ft_appenddata([], audiodata, data);
  %dat       = cat(2, dat, conj(dat2(:,setdiff(1:numel(data.trial),sel))));
end
%% at least the following are affected big time, bitsi box misbehaviour, UPPT001 not returning back to 0
% 2050,2047,2039,2044,2045

% the strategy here would be to cross-reference the audio trace with the
% single file audio traces that have correct corresponding trigger timings.
% to this end we do the following:
% -preprocess data epoched with trialfun_auditory_audio_onoff
% -read in both the UPPT001 and UADC004
% -do this for a bunch of subjects
% -create a set of unique stimuli as a reference dataset
% -do a cross-correlation (implemented as multiplication in fourier space)
% with the full traces of the audio signal in the faulty datasets
% -when a match is found, the triggers can be aligned and documented for
% the faulty dataset.


%% after some clarifying e-mail from Erik, it seems that the Bitsi 'misbehaved' in a deterministic way,
% i.e. in level-mode:
% -once a bit switches on, it stays high, until the next trigger is written
% -it should thus be possible to decode the trigger channel in principle:
% *determine which bits are in level-mode, and which aren't
% *deal with the level-mode bits

clear all

v


%% the following are affected by overlapping triggers between audio file onset and first word onset; this calls for a different solution than above
% 2040,2046