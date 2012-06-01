function mous_db_makesubjdir(subject)

% function to create a directory (with subdirectories) for the Processed
% data for a particular named subject. If not already existing, the
% directory will be created in ~annhul/MOUS/Processed/
%
% $Id: mous_db_makesubjdir.m 43 2012-05-16 10:40:37Z jansch $

existdir = ~isempty(dir(['/home/language/annhul/MOUS/Processed/',subject]));
subjdir  = ['/home/language/annhul/MOUS/Processed/',subject];
if ~existdir
  fprintf(['creating subject specific directory: ', subjdir,'\n']);
  mkdir(subjdir);
  system(['chmod g+w ',subjdir]);
end

existdir = ~isempty(dir(['/home/language/annhul/MOUS/Processed/',subject,'/meg_anatomy']));
if ~existdir
  fprintf(['creating subject specific subdirectory: ', subjdir, '/meg_anatomy\n']);
  mkdir([subjdir, '/meg_anatomy']); 
  system(['chmod g+w ',subjdir '/meg_anatomy']);
end

existdir = ~isempty(dir(['/home/language/annhul/MOUS/Processed/',subject,'/other']));
if ~existdir
  fprintf(['creating subject specific subdirectory: ', subjdir, '/other\n']);
  mkdir([subjdir, '/other']);
  system(['chmod g+w ',subjdir, '/other']);
end

existdir = ~isempty(dir(['/home/language/annhul/MOUS/Processed/',subject,'/ERF']));
if ~existdir
  fprintf(['creating subject specific subdirectory: ', subjdir, '/ERF\n']);
  mkdir([subjdir, '/ERF']);
  system(['chmod g+w ',subjdir, '/ERF']);
end

existdir = ~isempty(dir(['/home/language/annhul/MOUS/Processed/',subject,'/TFR']));
if ~existdir
  fprintf(['creating subject specific subdirectory: ', subjdir, '/TFR\n']);
  mkdir([subjdir, '/TFR']);
  system(['chmod g+w ',subjdir, '/TFR']);
end