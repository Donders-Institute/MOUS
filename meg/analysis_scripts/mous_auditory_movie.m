rootdir = '/home/language/jansch/public/mous';
subj  = mous_db_getfilename('allA', 'subjectname');
[f,s] = mous_db_getfilename(subj, 'meg_erf_auditory_firstword-pg', [], rootdir);

f = f(s);
for k = 1:numel(f)
  load(f{k});
  senWord_PG.avg = (senWord_PG.avg+seqWord_PG.avg)./2;
  tlck{k} = ft_combineplanar([], senWord_PG);
end
