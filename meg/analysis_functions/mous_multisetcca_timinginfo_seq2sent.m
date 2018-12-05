function [subjecttiming_out, groupinfo_out] = mous_multisetcca_timinginfo_seq2sent(subjecttiming, groupinfo, stimuli, sce)

% this function remaps the timing information of the word list trials, such
% that the word order is shuffled to reflect the order (+sample indices) of
% the original sentence, and the timing is according to the respective
% sentence in the other scenario

if iscell(sce)
  for k = 1:numel(sce)
    sce{k} = str2num(sce{k});
  end
  sce = cell2mat(sce);
  scenario = unique(sce);
end
sce = sce(:); % ensure column
if numel(scenario)~=2
  error('wrong number of scenarii');
end

assert(iscell(subjecttiming));
assert(iscell(groupinfo));
assert(numel(groupinfo)==numel(subjecttiming));

% per design, the first chunk of sorted trials in the subject-specific groupinfo
% reflects the sentences, the second chunk reflects the wordlists. Also,
% the per scenario groupinfo arrays are identical across subjects (with
% isequaln). Procedure would be to retain the two different
% groupinfo-specs, and to update the maxnsmp and maxtim
sel1 = find(sce==scenario(1));
sel2 = find(sce==scenario(2));
G1   = groupinfo{sel1(1)};
G2   = groupinfo{sel2(1)};

% update the G1 list trials with the information of the corresponding
% sentences in G2
sel1 = find(ismember(G1.trialid-500,G2.trialid));
for k = sel1(:)'
  ix = find(G2.trialid==G1.trialid(k)-500);
  G1.maxnsmp(k ) = G2.maxnsmp(ix);
  G1.mintim(k )  = G2.mintim(ix);
  G1.maxtim(k )  = G2.maxtim(ix);
%   G1.maxnsmp(k ) = nanmax([G1.nsmp(k,:) G2.nsmp(ix,:)]);
%   G2.maxnsmp(ix) = nanmax([G1.nsmp(k,:) G2.nsmp(ix,:)]);
%   G1.mintim(k )  = nanmin([G1.begtim(k,:) G2.begtim(ix,:)]);
%   G2.mintim(ix)  = nanmin([G1.begtim(k,:) G2.begtim(ix,:)]);
%   G1.maxtim(k )  = nanmin([G1.endtim(k,:) G2.endtim(ix,:)]);
%   G2.maxtim(ix)  = nanmin([G1.endtim(k,:) G2.endtim(ix,:)]);
end
% update the G1 list trials with the information of the corresponding
% sentences in G2
sel2 = find(ismember(G2.trialid-500,G1.trialid));
for k = sel2(:)'
  ix = find(G1.trialid==G2.trialid(k)-500);
  G2.maxnsmp(k ) = G1.maxnsmp(ix);
  G2.mintim(k )  = G1.mintim(ix,:);
  G2.maxtim(k )  = G1.maxtim(ix,:);
end
G1.trialid(G1.trialid>500) = G1.trialid(G1.trialid>500)-500;
G2.trialid(G2.trialid>500) = G2.trialid(G2.trialid>500)-500;
groupinfo_out(sce==scenario(1)) = {G1};
groupinfo_out(sce==scenario(2)) = {G2};

sel1 = find(sce==scenario(1));
sel2 = find(sce==scenario(2));
[~,ix1] = max(cellfun(@numel,...
              cellfun(@getfield,...
                subjecttiming(sel1),repmat({'trials'},[1 numel(sel1)]),'uniformoutput',false)));

[~,ix2] = max(cellfun(@numel,...
              cellfun(@getfield,...
                subjecttiming(sel2),repmat({'trials'},[1 numel(sel2)]),'uniformoutput',false)));

S1 = subjecttiming{sel1(ix1)};
S2 = subjecttiming{sel2(ix2)}; % for reference: the smpout matches across subjects, and reflects the target sampling axis for the other scenario

for m = 1:numel(subjecttiming)
  timinginfo = subjecttiming{m};
  switch sce(m)
    case scenario(1)
      S=S2;
    case scenario(2)
      S=S1;
  end
  
  ok = true(size(timinginfo.trials,1),1);
  for k = find(timinginfo.trialinfo(:,end)'>500)
    words1 = lower([stimuli(timinginfo.trialinfo(k,end)).words.word]');
    words2 = lower([stimuli(timinginfo.trialinfo(k,end)-500).words.word]');
    
    % words may occur more than once per sentence, a simple match_str does
    % not work
    i1 = zeros(numel(words1),1);
    i2 = i1;
    tmp1 = words1;
    for mm = 1:numel(words2)
      i2(mm,1) = mm;
      i1(mm,1) = find(strcmp(tmp1,words2{mm}),1,'first');
      tmp1{i1(mm)} = 'thiswordhasalreadybeenused';
    end
    
    smpin  = timinginfo.smpin{k}(i1,:);
    %smpout = timinginfo.smpout{k}(i1,:);
    k2 = find(S.trialinfo(:,end)==timinginfo.trialinfo(k,end)-500);
    if isempty(k2)
      % skip this one, because it does not have a match, assume that the
      % mismatch in corresponding trials will be dealt with correctly
      ok(k,1) = false;
      continue;
    end
    smpout = S.smpout{k2};
    time    = S.time{k2};
    
    % check whether the time axes of input and output align
    begindx = nearest(time, timinginfo.time{k}(1));
    if begindx~=1
      keyboard
    end
    
    % at this point, smpin and smpout approximately match in terms of 'word
    % length', apart from the respective first words, which includes a
    % baseline, and last words
    smpin(1)       = smpin(      1) + 1 - nearest(S.time{k2},0);
    smpin(i1==1,1) = smpin(i1==1,1) + nearest(timinginfo.time{k},0);
    
    if any(smpin(:,1)<0)
      for mm = find(smpin(:,1)<0)'
        offset = smpin(mm,1);
        smpin(mm,1)  = 1;
        smpout(mm,1) = smpout(mm,1)-offset+1; 
      end
    end
    
    for mm = 1:size(smpout,1)
      smpout(mm,:) = smpout(mm,1) + [0 min(diff(smpout(mm,:)),diff(smpin(mm,:)))];
    end
    timinginfo.smpin{k}  = smpin;
    timinginfo.smpout{k} = smpout;
    timinginfo.trialinfo(k,end) = timinginfo.trialinfo(k,end)-500;
    timinginfo.time{k}   = time;
  end
  timinginfo.trials = timinginfo.trials(ok);
  timinginfo.smpin  = timinginfo.smpin(ok);
  timinginfo.smpout = timinginfo.smpout(ok);
  timinginfo.time   = timinginfo.time(ok);
  timinginfo.trialinfo = timinginfo.trialinfo(ok,:);
  
  subjecttiming_out{m} = timinginfo;
end