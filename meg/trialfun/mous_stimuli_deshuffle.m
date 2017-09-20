function stimuli = mous_stimuli_deshuffle

load mous_stimuli;
for k = 1:500
  if ~isempty(stimuli(k).id)
    w1 = strtok(lower([stimuli(k).words.word]'),     '.');  
    w2 = strtok(lower([stimuli(k+500).words.word]'), '.');
    
    order1 = 1:numel(w1);
    for m = 1:numel(w2)
      if k==400 && m==5,
        % there is one stimulus with a typo in the sentence relative to the
        % sequence, 'de' versus 'die'.
        w2{m} = 'de';
      end
      tmpsel = find(strcmp(w1,w2{m}));
      if numel(tmpsel)==1
        order2(m) = tmpsel;
      else
        order2(m) = tmpsel(randperm(numel(tmpsel),1));
        w1{order2(m)} = 'abcdefghijklmnopqrstuvwxyz';
      end
    end
    stimuli(k).wordorder     = order1;
    stimuli(k+500).wordorder = order2;
  end
end