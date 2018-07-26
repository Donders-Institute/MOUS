function out = mous_multisetcca_groupdata2singlestruct(groupdata, subj)

T = zeros(numel(groupdata{1}.trial),numel(groupdata{1})+1);
for k = 1:numel(groupdata)
  label = cell(numel(groupdata{k}.label),1);
  for m = 1:numel(label)
    label{m,1} = sprintf('%s_chan%03d',subj{k},m);
  end
  groupdata{k}.label=label;
  groupdata{k}.time = groupdata{1}.time;
  groupdata{k}.fsample = groupdata{1}.fsample;
  T(:,k) = groupdata{k}.trialinfo(:,1); %adding IDs as presented to each subject
end
T = [T groupdata{k}.trialinfo(:,end)]; %adding IDs as aligned

out = groupdata{1};
label = out.label;
for k = 2:numel(groupdata)
  out.trial = cellcat(1,out.trial,groupdata{k}.trial);
  label = cat(1,label,groupdata{k}.label);
end
out.trialinfo = T;
out.label     = label;
