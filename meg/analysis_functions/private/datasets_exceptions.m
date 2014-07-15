function filename = datasets_exceptions(subject,templatepath)
% datasets_exceptions hardcodes filenames for subjects with more than one
% task dataset, in which one dataset is much smaller than the other.

% taking inarg from mous_db_getfilename so that if rootdir changes again
% we don't need to change this function
[p,n,e] = fileparts(templatepath); 
switch subject
  case 'A2052'
      filename(1).name = [n(1:end-1),'3',e];
  case 'A2062'
      filename(1).name = [n(1:end-1),'2',e];
      filename(2).name = [n(1:end-1),'3',e];
  case 'A2063'
      filename(1).name = [n(1:end-1),'2',e];
      filename(2).name = [n(1:end-1),'3',e];     
  case 'A2115'
      filename(1).name = [n(1:end-1),'2',e];
      filename(2).name = [n(1:end-1),'3',e];
end
