function stimuli = mous_stimuli_addstack

load mous_stimuli

ok = true(numel(stimuli),1);
for k = 1:numel(stimuli)
  if isempty(stimuli(k).id),
    ok(k) = false;
  end
end

for k = find(ok(:)')
  
  % Vorige maandag kreeg de medicus die de vreemde pokken behandelde zelf de pokken
  
  % tree = [stimuli(6).words.depind];
  % treeplot(tree)
  
  % Assumptions:
  
  % 1. Incremental input 'left to right parsing' with a push down stack store,
  %    but access throughout the stack at all steps (random access memory)-
  %    this can easily be changed to real stack properties if one is curious.
  % 2. No ambiguity, which means that at each step, it is known whether any
  %    earlier word is supposed to be inserted at that step in the final tree.
  % 3. Elements are erased/popped when inserted in the tree.
  
  % Implementational choices:
  % 1. Create depjump vector - a signed dependency jump vector,
  %    negative value means pointing to an earlier word
  % 2. Elements that will be pushed to the stack are not words but the
  %    depinds, which will simplify furhter computation (rationale not clear to JM).
  
  % create a local copy of the dependency index vector, as well as a signed
  % dependency jump
  depind  = [stimuli(k).words.depind];
  root    = depind==0;
  depjump = [stimuli(k).words.depind]-(1:stimuli(k).numwords);
  depjump(root) = 0;
  
  stack       = cell(1,numel(depjump));      % create as cell-array, because it may hold more than 1 element
  stack_depth = nan+zeros(1,numel(depjump)); % will contain the number of elements in the stack for each word
  
  % initialize for the first word
  stack{1} = depind(1);
  
  % loop over the remainder of the words
  for m = 2:stimuli(k).numwords
    % Does any of the dependency indices in the stack of the previous word
    % point to the current word?
    match = stack{m-1} == m;
    
    if any(match)
      % Erase ('pop') the matching element
      stack{m} = stack{m-1}(~match);
      
      % Nested Push if popped. Push unless root or later, i.e. if depjump_valued < 0
      if depjump(m) <= 0
        % nothing needs to be done, the Stack stays
      else
        stack{m} = [stack{m} depind(m)]; %Push
      end
      
    elseif all(~match)
      % Push unless root or later, i.e. if depjump_valued < 0
      if depjump(m) <= 0
        stack{m} = stack{m-1}; %Stack stays
      else
        stack{m} = [stack{m-1} depind(m)]; %Push
      end
    end
  end
  
  % Calculate the depth of the stack at each word
  for m = 1:numel(depjump)
    stack_depth(m) = numel(stack{m});
    
    stimuli(k).words(m).stack          = stack{m};
    stimuli(k).words(m).stack_depth    = stack_depth(m);
    stimuli(k).words(m).depjump_signed = depjump(m);
  end
  stimuli(k).stack_depth = stack_depth;
  
  % Display stack, stack depth and depjump_valued for debugging
  % stimuli(k).words.stack
  % stimuli(k).words.stack_depth
  % stimuli(k).words.depjump_valued
  
end


%%%%%%%%%%%%%%
% Next steps
%%%%%%%%%%%%%%

% Look at maximum stack depth - does it differ between RC+/RC-?
% Answer (JM): yes they are. Do:
for k = 1:numel(stimuli)
  if ~isempty(stimuli(k).id)
    m(k,1) = max(stimuli(k).stack_depth);
  else
    m(k,1) = nan;
  end
end
n = histc([m(1:204) m(205:408)],0.5:1:4.5);
figure;bar(1:4,n(1:4,:));
legend({'RC+';'RC-'});

% Storing non-inserted elements vs storing structure - different or same storing mechanism?

% Above, storing non-elements is formalized, but storing non-final
% structure still needs to be formalized.

% Ideas for such a formalization:

% A) Make a model where they there are separate stores.

% There can be many implementations, e.g.:
% (1) the unified object is one object
% (2) the unified object is one object, but it weighs different:
%       (2a) the number of words in the unified structure
%       (2b) the number of levels in the unified structure

% B) Make a model where they is one store. Again, either the whole
% unified object is one object, or is weight different, according to nr
% words or nr levels. So this is going to be a simple addition of the
% store of the non-inserted elements and the unified object.

