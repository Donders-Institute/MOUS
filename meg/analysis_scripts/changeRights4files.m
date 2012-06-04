
subjlist = {'V1010' 'V1011' 'V1012' 'V1013' 'V1014' ...
'V1015' 'V1016' 'V1017' 'V1019' 'V1020' 'V1021' 'V1022' 'V1024' 'V1025' ...
'V1026' 'V1027' 'V1028' 'V1029' 'V1030' 'V1031' 'V1032' 'V1033' 'V1034' ...
'V1036' 'V1037' 'V1039' 'V1040' 'V1042' 'V1044' 'V1045' 'V1046' };

for n= 1:length(subjlist)
  str = sprintf('cd /home/language/annhul/MOUS/Processed/%s/ERF/', subjlist{n});
  eval(str);
  cmd = ['chmod g+w *'];
  system(cmd);
end