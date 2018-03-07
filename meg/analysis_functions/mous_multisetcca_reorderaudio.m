function groupdata = mous_multisetcca_reorderaudio(groupdata, subj, reorder, stimid, parcel_indx, shift, stretch)

selaudio = find(strncmp(subj,'sub-2',5))';
for k = selaudio
  mous_db_getdata(subj{k}, 'meg_multisetcca_data');
  mous_db_getdata(subj{k}, 'meg_multisetcca_lcmv_parc');
  source_parc.filterlabel = filterlabel;
  mous_db_getdata(subj{k}, 'meg_multisetcca_timinginfo');
  mous_db_getdata(subj{k}, 'meg_multisetcca_groupinfo');

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
  timinginfo.smpin = newsmpin;
  timinginfo.smpout = newsmpout;
  clear newtrial newtime newtime2 newsmpin newsmpout;
  
  groupdata{1,k} = mous_multisetcca_getparceldata(subj{k}, data, source_parc, timinginfo, groupinfo, parcel_indx, shift(k), stretch(k));
end
for k = selaudio
  cfg = [];
  cfg.method = 'acrosschannel';
  groupdata{1,k} = ft_channelnormalise(cfg, groupdata{1,k});
end
