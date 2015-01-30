function [stimuli, count_updated, stim_updated] = fix_dependency

load('mous_stimuli');

fid = fopen('fix_dependency.txt');
dat = textscan(fid,'%s','delimiter','\n');
fclose(fid);

dat = dat{1};
cnt = 1;
count_updated = 0;
stim_updated  = zeros(0,1);
while cnt<numel(dat)
  switch(numel(str2num(dat{cnt})))
    case 0
      % this is either an empty line, or text
      cnt    = cnt+1;
    case 1
      stimid = str2num(dat{cnt});
      cnt    = cnt+2; % skip the text
    otherwise
      wordid  = str2num(dat{cnt});
      dep_org = str2num(dat{cnt+1});
      dep_new = str2num(dat{cnt+2});
      if isempty(dep_new)
        break;
      end
      
      if ~numel(stimuli(stimid).words)==numel(wordid)
        error('the number of words does not add up')
      end
      
      fprintf('updating %s\n', dat{cnt-1});
      count_updated = count_updated+1;
      stim_updated  = [stim_updated stimid];
      for k = 1:numel(wordid)
        if dep_org(k)~=dep_new(k)
          stimuli(stimid).words(wordid(k)).depind = dep_new(k);
          stimuli(stimid).words(wordid(k)).depjump = abs(dep_new(k)-wordid(k));
        end
      end
      cnt = cnt+3;
  end
end

