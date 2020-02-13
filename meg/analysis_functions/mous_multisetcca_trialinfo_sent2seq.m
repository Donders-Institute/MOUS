function trialinfo = mous_multisetcca_trialinfo_sent2seq(trialinfoin, stimuli)

% MOUS_MULTISETCCA_TRIALINFO_SENT2SEQ converts a trialinfo matrix that
% contains sentence word based quantities into the corresponding quantities
% for the word lists, adjusting index, perplexity, entropy, and nann-ing out
% branching complexity values, because these are not defined. Note that
% duration and duration2 are not touched

trialinfo = trialinfoin;

for k = 1:size(trialinfoin,1)
  newid = trialinfoin.id(k)+500;
  
  newindx = match_str(lower([stimuli(newid).words.word]'), {lower(trialinfoin.word{k})});
  if numel(newindx)>1
    trialinfo.id(k) = nan;
    continue;
    % there is more than a single occurence of this word in the
    % sentence/list, randomisation of the order is not unique, for now this
    % is assumed not to occur for the content words, to which the
    % subsequent analysis (that is the analysis for which this function has
    % been designed) is constrained (at least for now). The consequence is
    % that we lose a few words, because in the initial realignment scheme it
    % is not clear where each of the duplicated words ended up.
  end
  
  this_ = stimuli(newid).words(newindx);
  
  if ~isfinite(this_.entropy)
    this_.entropy = 0;
  end
  if this_.lexfreq == 0
    this_.lexfreq = 1; % this to mimick the not fully correct conversion of non-finite log10 transformed lexfreq to 0, in mous_multisetcca_extractwords.
    % This is not correct, since it would suggest a very frequent word,
    % rather than a very infrequent one.
  end
  
  trialinfo.loglexfreq(k) = log10(this_.lexfreq);
  trialinfo.id(k)         = newid;
  trialinfo.index(k)      = newindx;
  trialinfo.ordinal(k)    = newindx;
  trialinfo.entropy(k)    = this_.entropy; 
  trialinfo.logperplexity(k) = log10(this_.perplexity);
  trialinfo.leftbranch(k) = nan;
  trialinfo.dleftbranch(k) = nan;
  trialinfo.rightbranch(k) = nan;
  trialinfo.drightbranch(k) = nan;
end
