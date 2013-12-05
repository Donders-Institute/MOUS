function dspmMean = mous_getmnefromfrmi(subjectname, meantime, mni)

% finds the mne activty for given mni coordinates (mnicoord) and computes mean dspm
% activty of clostest coordinate + six neighbouing vertices, mean amplitude
% over time as defined in the meantime 

% mnicoord  - mni coordinates you would liketo find

 
 %get mne
 rootdir = '/project/3011020.09/annhul';
 file = 'meg_mne_{_mne_allwords_01-10-targets-sent_currentdensity_weighted}';
 sent = mous_db_getdata(subjectname,file, rootdir);
 load cortex_midthickness_8196reg.mat
 sent.pos = sourcemodel.pnt; %change coordinates to mni space
 
 
 % clostest meg

 disVec = sqrt((sent.pos(:,1)-mni(1)).^2 +(sent.pos(:,2)-mni(2)).^2 + (sent.pos(:,3)-mni(3)).^2);
 [a, indx] = min(disVec);
  

 [connmat] = triangle2connectivity(sent.tri);
 a = connmat(:,indx);
 [nb] = find(a); 
  
 %[nb] = mous_find_vertex_neighbours( sent.tri, indx);
 cluster = [indx; nb];
 
 sent.time = sent.time(1,:)-0.036;
 
 [c from] = min(abs(sent.time-meantime(1)));
 [c to] = min(abs(sent.time-meantime(2)));

 dspmMean = nanmean(nanmean(sent.avg.dspm(cluster,from:to),1));
  