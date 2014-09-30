function [duration, stimid] = mous_estimate_audioduration(thr)

if nargin==0
  thr = -0.5;
end

dodynamic = false;
if ischar(thr)
  % use a dynamic threshold
  dodynamic = true;
  fac = str2num(thr);
end

% get the downsampled audio data
audiodir  = '/home/language/jansch/projects/mous/meg/stimuli/AudioStimuli20120905';

present_dir = pwd;
cd(audiodir);

d = dir('audiodata*');

stimid = cell(numel(d),1);
duration = zeros(numel(d),1);
for k = 1:numel(d)
  fprintf('loading %s\n',d(k).name);
  load(d(k).name);
  tmp = ft_preproc_standardize(ft_preproc_medianfilter(abs(sum(ft_preproc_highpassfilter(data.trial{1},1200,10))),121));
  if ~dodynamic
    duration(k,1) = find(tmp>thr,1,'last')-find(tmp>thr,1,'first')-1;
  else
    thr = min(tmp).*fac;
    duration(k,1) = find(tmp>thr,1,'last')-find(tmp>thr,1,'first')-1;
  end
  stimid{k,1}   = d(k).name;
end
duration = duration./1200;

cd(present_dir);