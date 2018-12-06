function out = mous_multisetcca_adjusttiming_vis(subjectname, data)

% this function accounts for slight timing differences in the onset of the
% visually presented words, due to variability across subjects upon
% stimulus presentation. It outputs the specification of how to align the trials

% shift the trial a bit, if needed, so that potential timing issues are minimized,
% this involves some manipulation of the trials. Also, specify the monitor
% delay

load mous_stimuli;

f   = mous_db_getfilename(subjectname, 'meg_ds_task');
trl = zeros(0,9);
for m = 1:numel(f)
  cfg = [];
  cfg.dataset  = f{m};
  cfg.trialfun = 'trialfun_visual_word_new';
  cfg.trialdef.prestim = 0;
  cfg.trialdef.poststim = 'nextword';
  cfg = ft_definetrial(cfg);
  trl = cat(1,trl,cfg.trl);
end

% inventorize the quality of the timing of the individual words, by
% comparing the trigger-extracted word lengths with the benchmark in
% the stimuli struct-array
delta = cell(numel(data.trial),1);
ok = false(numel(data.trial),1);
for m = 1:numel(data.trial)
  stim_id = data.trialinfo(m,end);
  
  % very occasionally, stim_id = nan (I suspect when a dsq crash occurred
  % in the middle of a sentence, this requires the sentence to be discarded
  
  if isfinite(stim_id)
    wordonset1 = trl(trl(:,9)==stim_id,6)./1200;
    wordonset2 = stimuli(stim_id).timinginfo_visual(:,2);
  else
    wordonset1 = nan;
    wordonset2 = nan;
  end
  
  % discard instances where the number of words does not match
  ok(m) = numel(wordonset1)==numel(wordonset2) && isfinite(stim_id);
  if ok(m)
    delta{m,1} = [wordonset2-wordonset1];
  else
    delta{m,1} = [nan];
  end
  W1{m,1} = wordonset1;
  W2{m,1} = wordonset2;
end
mm = [cellfun(@min, delta) cellfun(@max, delta)];
ok(mm(:,1)<-0.12|mm(:,2)>0.12) = false;

out.trials = find(ok);

data.trial = data.trial(ok);
data.time  = data.time(ok);
data.trialinfo = data.trialinfo(ok,:);
W1 = W1(ok);
W2 = W2(ok);

newtrial = data.trial;
newtime  = data.time - 0.036; % adjust for monitor delay
fprintf('adjusting for the jitter in word onset timing\n');
for m = 1:numel(data.trial)
  [newtrial{m}, newtime{m}, smpin{m,1}, smpout{m,1}] = adjust_timing_visual(data.trial{m}, data.time{m}, W1{m}, W2{m});
end

out.smpin  = smpin;
out.smpout = smpout;
out.time   = newtime;
out.trialinfo = data.trialinfo;

%-------------------------------------------------------
% function to align the timing of the visual word onsets
function [datout, timeout, smpin, smpout] = adjust_timing_visual(datin, timein, timingin, timingout)

for k = 1:numel(timingin)
  smpin(k,1) = nearest(timein, timingin(k));
end
for k = 1:numel(timingout)
  smpout(k,1) = nearest(timein, timingout(k));
end
smpin(1)  = 1;
smpout(1) = 1;

smpin(1:end-1,2) = smpin(2:end)-1;
smpin(end,2)     = size(datin,2);
smpout(1:end-1,2) = smpout(2:end)-1;
smpout(end,2)     = size(datin,2);

datout = nan(size(datin));
for k = 1:size(smpout,1)
  nsmp = smpout(k,2)-smpout(k,1)+1;
  smpout_idx = smpout(k,1):smpout(k,2);
  smpin_idx  = smpin(k,1)+(1:nsmp);
  
  smpout_idx(smpin_idx>size(datin,2)) = [];
  smpin_idx(smpin_idx>size(datin,2))  = [];
  
  datout(:,smpout_idx) = datin(:,smpin_idx);
end
timeout = timein;
