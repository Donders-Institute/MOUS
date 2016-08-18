[f,  s]  = mous_db_getfilename('all','subjectname');
[f2, s2] = mous_db_getfilename(f,'meg_bfica_{_bfica_sourcedatadss}',[],'/home/language/jansch/public/mous');
f2 = f2(s2);

for k = 1:numel(f2)
  k
  load(f2{k});
  sel1 = comp.trialinfo(:,2)==2 | comp.trialinfo(:,2)==6;
  sel2 = comp.trialinfo(:,2)==4 | comp.trialinfo(:,2)==8;
  p    = comp.cfg.dss.denf.params;
  p1   = p;
  p1.tr = p1.tr(sel1);
  p2   = p;
  p2.tr = p2.tr(sel2);
  [~,~,avgcomp]  = denoise_avg2(p,  comp.trial);
  [~,~,avgcomp1] = denoise_avg2(p1, comp.trial(sel1));
  [~,~,avgcomp2] = denoise_avg2(p2, comp.trial(sel2));
  
  % mix back to source level
  avgdat(:,:,k)  = comp.topo(:,1:3)*avgcomp(1:3,:);
  avgdat1(:,:,k) = comp.topo(:,1:3)*avgcomp1(1:3,:);
  avgdat2(:,:,k) = comp.topo(:,1:3)*avgcomp2(1:3,:);
end