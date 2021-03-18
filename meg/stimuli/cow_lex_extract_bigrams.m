tokenfile = '/home/dyncon/jansch/projects/mous/meg/stimuli/NLCOW2012b.10M.tok.lex';
fid = fopen(tokenfile);
C = textscan(fid, '%s%d');
fclose(fid);

C{1} = lower(C{1});

% extract the bigrams
bigrams = zeros(26);
for k = 1:numel(C{1})
  this_ = C{1}{k};
  this_ = double(int8(this_))-96; % convert ascii to 1-26 for the letters
  
  this_(2,1:(size(this_,2)-1)) = this_(1,2:end);
  
  sel  = sum(this_<=26&this_>0)==2;
  indx = double(this_(1,sel)) + double(this_(2,sel)-1)*26;
  bigrams(indx) = bigrams(indx)+double(C{2}(k));
end
bigrams = bigrams./sum(bigrams(:));
bigramsfile = '/home/dyncon/jansch/projects/mous/meg/stimuli/NLCOW2012b_bigrams.mat';
save(bigramsfile, 'bigrams');

load mous_stimuli

for k = 1:numel(stimuli)
  if ~isempty(stimuli(k).id)
    words = lower([stimuli(k).words.word]');
    F{k} = cell(1,numel(words));
    for m = 1:numel(words)
      this_ = words{m};
      this_ = double(int8(this_))-96; % convert ascii to 1-26 for the letters
      this_(2,1:(size(this_,2)-1)) = this_(1,2:end);
      sel  = sum(this_<=26&this_>0)==2;
      indx = double(this_(1,sel)) + double(this_(2,sel)-1)*26;
      F{k}{m} = bigrams(indx);
    end  
  end
  
end

f = nan(908,20);
for k = 1:908
  for m = 1:numel(F{k})
    try
      f(k,m) = mean(F{k}{m});
    end
  end
end

% add the bigram frequencies to the stimuli struct-array
for k = 1:numel(stimuli)
  if ~isempty(stimuli(k).id)
    for m = 1:numel(stimuli(k).words)
      stimuli(k).words(m).bigramfreq = f(k,m);
    end    
  end
end




