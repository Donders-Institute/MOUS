% this script updates the mous_stimuli array with a corrected version of
% the entropy/perplexity, as obtained with a model that was trained on
% 71761868 words from NLCOW2012

load mous_stimuli;

fid = fopen('mous_stimuli.wopr.txt');
S   = textscan(fid,'%s %s %s %f %f %f %f','Headerlines',1,'CollectOutput',true);
fclose(fid);

words = S{1}(:,3);
entropy = S{2}(:,3);
perplexity = 2.^(-S{2}(:,1)); % to stay consistent with the rest, the actual perplexity values in the file are rounded off

% verify once, whether the order of all items is matched between the
% stimuli array, and the new data points
indx = 0;
for k = 1:numel(stimuli)
  if ~isempty(stimuli(k).id)
    indx = indx(end)+(1:stimuli(k).nrwords);
    ok(k,1) = isequal(lower(words(indx)),lower([stimuli(k).words.word])');
    istrial(k,1) = true;
  else
    ok(k,1) = false;
    istrial(k,1) = false;
  end
end
assert(isequal(ok,istrial));

indx = 0;
for k = 1:numel(stimuli)
  if ~isempty(stimuli(k).id)
    indx = indx(end)+(1:stimuli(k).nrwords);
    for m = 1:stimuli(k).nrwords
      stimuli(k).words(m).perplexity_old = stimuli(k).words(m).perplexity;
      stimuli(k).words(m).perplexity     = perplexity(indx(m));
      stimuli(k).words(m).entropy_old    = stimuli(k).words(m).entropy;
      stimuli(k).words(m).entropy        = entropy(indx(m));
    end
  else
  end
end

% load the lexicon
fid = fopen('NLCOW2012.10M.tok.lex');
S   = textscan(fid,'%s %f');
fclose(fid);

% for now, don't be too critical on the strange character occurrences, just
% include them.
lexicon = lower(S{1});
lfreq = zeros(numel(words),1);
for k = 1:numel(words)
  sel = strcmp(lexicon,lower(words{k}));
  if any(sel)
    lfreq(k,1) = sum(S{2}(sel));
  else
    lfreq(k,1) = 0;
  end
end
lfreq = lfreq./sum(S{2});


indx = 0;
for k = 1:numel(stimuli)
  if ~isempty(stimuli(k).id)
    indx = indx(end)+(1:stimuli(k).nrwords);
    for m = 1:stimuli(k).nrwords
      stimuli(k).words(m).lexfreq_subtlex = stimuli(k).words(m).lexfreq;
      stimuli(k).words(m).lexfreq         = lfreq(indx(m));
    end
  else
  end
end



