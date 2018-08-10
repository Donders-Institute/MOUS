function [groupdata, stim] = mous_multisetcca_reorderaudio(subj, subjectdata, subjecttiming, groupinfo, reorder, stimid, shift, stretch)

for k = 1:numel(subjectdata)
  data = subjectdata{k};
  
  if 0
    hasstim = strncmp(data.label{end},'stim',4);
    if ~hasstim
      % create a stim channel that can be used for debugging, i.e. to check
      % whether the unfolding worked well
      if strcmp(subj{k}(2),'2')
        stimdat = addstimchan(data,'aud');
      elseif strcmp(subj{k}(2),'1')
        stimdat = addstimchan(data,'vis');
      else
        error('wrong subjectname');
      end
      for kk = 1:numel(stimdat.trial)
        tmp = stimdat.trial{kk};
        tmp(end+1)=1;
        sel = find(tmp);
        for m = 1:numel(sel)-1
          tmp(sel(m):sel(m+1)) = linspace(m,m+1,sel(m+1)-sel(m)+1);
        end
        tmp = tmp(1:end-1);
        stimdat.trial{kk} = tmp;
      end
      stimdat.fsample = data.fsample;
      data = ft_appenddata([], data, stimdat);
    end
  end
    
  timinginfo = subjecttiming{k};
  
  % reorder the trials in the data structure, to achieve an unfolded
  % representation of audio data with identical timing info, but different
  % sentences
  newtrial = data.trial;
  newtime  = data.time;
  newtime2 = timinginfo.time;
  newsmpin = timinginfo.smpin;
  newsmpout = timinginfo.smpout;
  data_id  = data.trialinfo(:,end);
  cnt = 0;
  cnt2 = 0;
  for m  = 1:numel(stimid)
    old_id = stimid(m);
    new_id = stimid(reorder(m));
    
    sel    = find(data_id==old_id);
    selnew = find(data_id==new_id);
    if ~isempty(sel) && ~isempty(selnew)
      cnt = cnt+1;
      newtrial(sel) = data.trial(selnew);
      newtime(sel)  = data.time(selnew);
    end
    
    sel2    = find(timinginfo.trialinfo(:,end)==old_id);
    selnew2 = find(timinginfo.trialinfo(:,end)==new_id);
    if ~isempty(sel2) && ~isempty(selnew2)
      cnt2 = cnt2+1;
      newtime2(sel2) = timinginfo.time(selnew2);
      newsmpin(sel2) = timinginfo.smpin(selnew2);
      
      n_tmp = min(size(newsmpin{sel2},1),size(newsmpout{sel2},1));
      newsmpin{sel2}  = newsmpin{sel2}(1:n_tmp,:);
      newsmpout{sel2} = newsmpout{sel2}(1:n_tmp,:);
      
    end
 
  end
  data.trial = newtrial;
  data.time  = newtime;
  %timinginfo.time = newtime2;
  newtiminginfo = timinginfo;
  newtiminginfo.smpin = newsmpin;
  newtiminginfo.smpout = newsmpout;
  clear newtrial newtime newtime2 newsmpin newsmpout;
  
  if nargout>1
    [groupdata{1,k}, stim{1,k}] = mous_multisetcca_getparceldata(subj{k}, data, newtiminginfo, groupinfo, shift(k), stretch(k));
  else
    groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, data, newtiminginfo, groupinfo, shift(k), stretch(k));
  end
end
for k = 1:numel(groupdata)
  cfg = [];
  cfg.method = 'acrosschannel';
  groupdata{1,k} = ft_channelnormalise(cfg, groupdata{1,k});
end
