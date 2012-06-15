

for n= 1:9
  str = sprintf('cd /home/language/annhul/MOUS/Processed/V100%d/', n);
  eval(str);
  cmd = ['chmod -R g+w *'];
  system(cmd);
end

for n= 10:99
  str = sprintf('cd /home/language/annhul/MOUS/Processed/V10%d/', n);
  eval(str);
  cmd = ['chmod -R g+w *'];
  system(cmd);
end

