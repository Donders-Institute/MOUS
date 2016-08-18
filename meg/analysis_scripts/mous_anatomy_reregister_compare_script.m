%% this script tests the registration of the audio subject in the old 
% (incorrect: manual only) and new (with icp info incorporated) version

figdir = '/project/3011020.09/jansch/results/20140114';

subj = mous_db_getfilename('allA', 'subjectname');
D    = nan+zeros(numel(subj),2);
for k = 1:numel(subj)
  try
  subjectname = subj{k};
  [h1, data1, h2, data2] = mous_anatomy_reregister_compare(subjectname);
  D(k,1) = nanmean(abs(unique(data1.shapemri.distance)));
  D(k,2) = nanmean(abs(unique(data2.shapemri.distance)));
  
  set(h1, 'position', [10 10 1000 800]);
  img = getframe(h1);
  savepng(img.cdata, fullfile(figdir, [subjectname, '_coregistration_old.png']));
  set(h2, 'position', [10 10 1000 800]);
  img = getframe(h2);
  savepng(img.cdata, fullfile(figdir, [subjectname, '_coregistration_new.png']));
  close all;
  end
end
