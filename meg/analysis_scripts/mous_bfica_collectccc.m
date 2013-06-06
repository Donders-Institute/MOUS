% concatenate connectivity results

rootdir = '/home/language/jansch/public/mous';
subj    = mous_db_getfilename('all', 'subjectname');
[~,ok]  = mous_db_getfilename(subj, 'meg_bfica_ccc', 0, rootdir);
subj    = subj(ok);

mous_db_getdata(subj{1},'meg_bfica_ccc',rootdir);
mous_db_getdata(subj{1},'meg_bfica_source8mm',rootdir);

dc   = zeros(size(cohsent.coh));
dcsq = zeros(size(dc));

clear cohsent cohseq 
for k = 10:34%numel(subj)
  mous_db_getdata(subj{k},'meg_bfica_ccc',   rootdir);
  mous_db_getdata(subj{k},'meg_bfica_source8mm',rootdir);

  df1   = 2*sum(ismember(trialinfo(:,2),[1 2 5 6])); % assuming 1 taper
  df2   = 2*sum(ismember(trialinfo(:,2),[3 4 7 8]));
  if df1~=df2
    error('different degrees of freedom');
  end
  denom = sqrt(2./(df1-2));
  tmp   = (atanh(abs(cohsent.coh))-atanh(abs(cohseq.coh)))./denom;
  
  dc = dc+tmp;
  dcsq = dcsq+tmp.^2;
  
  clear trialinfo cohseq cohsent  
end

n     = 25;
dcvar = (1./(n-1)).*(dcsq - (dc./n).^2);

dcohz  = (dc./n)./sqrt(dcvar);