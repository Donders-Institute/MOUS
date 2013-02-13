
% V1001 : V1009

for n= 1:9
  str = sprintf('cd /home/language/annhul/MOUS/meg/V100%d/tfr', n);
  eval(str);
  cmd = ['chmod -R g+w *'];
  system(cmd);
end

% V1010 : V1099
for n= 10:99
  str = sprintf('cd /home/language/annhul/MOUS/meg/V10%d/tfr', n);
  eval(str);
  cmd = ['chmod -R g+w *'];
  system(cmd);
end

% V1110 : V1116
for n = 10:16
  str = sprintf('cd /home/language/annhul/MOUS/meg/V11%d/tfr', n);
  eval(str);
  cmd = ['chmod -R g+w *'];
  system(cmd);  
end 