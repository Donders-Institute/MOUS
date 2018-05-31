function out = mous_multisetcca_adjusttiming_aud(subjectname, data)

load mous_stimuli;
ok = false(numel(data.trial),1);
for m = 1:numel(data.trial)
  stim_id = data.trialinfo(m,end);
  
  wordonset1 = stimuli(stim_id).timinginfo(1:end-1,2);
  wordonset2 = stimuli(stim_id).timinginfo_visual(:,2);
  
  % discard instances where the number of words does not match
  ok(m) = numel(wordonset1)==numel(wordonset2);
  
  W1{m,1} = wordonset1;
  W2{m,1} = wordonset2;
end
data.trial = data.trial(ok);
data.time  = data.time(ok);
data.trialinfo = data.trialinfo(ok,:);
W1 = W1(ok);
W2 = W2(ok);

newtrial = data.trial;
newtime  = data.time;
fprintf('align the audio data with the visual word onset timing\n');
for m = 1:numel(data.trial)
  [newtrial{m}, newtime{m}, smpin{m,1}, smpout{m,1}] = unfold_audio(data.trial{m}, data.time{m}, W1{m}, W2{m}, 1./mean(diff(data.time{1})));
end

out.trials = find(ok);
out.smpin  = smpin;
out.smpout = smpout;
out.time   = newtime;
out.trialinfo = data.trialinfo;

%---------------------------------------------------------------------
% function to unfold the timing of the audio to the visual word onsets
function [datout, timeout, smpin, smpout] = unfold_audio(datin, timein, timingin, timingout, fs)

% the time axis is defined relative to the onset of the audio file,
% redefine the 0 to the onset of the first word
timein   = timein   - timingin(1);
timingin = timingin - timingin(1);

timeout = (-round(fs./2.5):round(fs.*12))./fs;
for k = 1:numel(timingin)
  smpin(k,1) = nearest(timein, timingin(k));
end
for k = 1:numel(timingout)
  smpout(k,1) = nearest(timeout, timingout(k));
end
smpout(1) = 1;
smpin(1)  = nearest(timein, timeout(1));

smpin(:,2)        = size(datin,2);
smpout(1:end-1,2) = smpout(2:end,1)-1;
smpout(end,2)     = numel(timeout);

datout = nan(size(datin,1), numel(timeout));
for k = 1:size(smpout,1)
  nsmp = smpout(k,2)-smpout(k,1)+1;

  smpin_idx  = smpin(k,1)-1+(1:nsmp);
  smpout_idx = smpout(k,1):smpout(k,2);
  
  keep_idx   = smpin_idx<=size(datin,2);
  smpin_idx  = smpin_idx(keep_idx);
  smpout_idx = smpout_idx(keep_idx);
  
  datout(:,smpout_idx) = datin(:,smpin_idx);
end
datout  = datout(:,1:smpout_idx(end));
timeout = timeout(1:smpout_idx(end));

