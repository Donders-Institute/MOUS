function mous_samplecount_descriptives(subjectnames,datasegmenter,artifactsel)
% datasegmenter = 'artifact_rawprocsamplediff_trialfunword' or '...trialfunsent'


% rootdir
if strcmp(subjectnames{1}(1),'V')  
  rootdir = '/project/3011020.09/MEG/';
else
  rootdir = '/project/3011020.09/nielam/';
end 

% savename 
artnames = {'b','s','j','m'};
tmp = artnames(logical(artifactsel));
for k = 1:numel(tmp)
  if k == 1
    saveartifact = tmp{1};
  else
    saveartifact = strcat(saveartifact,tmp{k});
  end
end
    
% [f,s] = mous_db_getfilename(subjectnames,datasegmenter,0,rootdir);
% ns = find(s==0);
% if numel(f(ns)) ~= 0
%   subsubj = subjectnames(ns);
  for q = 1:numel(subjectnames)
    mous_samplecount(subjectnames{q},datasegmenter,artifactsel,saveartifact);
  end
% end

% savedir 
savedir = '/project/3011020.09/nielam/groupresults/sample_difference/';

% determine modality
if strcmp(subjectnames{1}(1),'V')  
  mod = 'visual';
else
  mod = 'auditory';
end 

% assign memory
numdiff = zeros(numel(subjectnames),6); % [pretrial,presmp,posttrial,postsmp, %remtrial, %remsmp]

% calculate descriptives and put into an array
for k = 1:numel(subjectnames)
  mous_db_getdata(subjectnames{k},[datasegmenter,'_',saveartifact],rootdir);
  numdiff(k,1) = size(pre,1);   % #words pre/post 
  numdiff(k,2) = size(post,1);  

  numdiff(k,3) = sum(pre(:,2)-pre(:,1)); % #samples pre/post
  numdiff(k,4) = sum(post(:,2)-post(:,1));
  
  numdiff(k,5) = (size(post,1)/size(pre,1))*100;  % percentage remaining words/smp
  numdiff(k,6) = (numdiff(k,4)/numdiff(k,3))*100; 
end

% add first column of subjectnames
for k = 1:numel(subjectnames)
  sj(k,1) = str2double(subjectnames{k}(3:end));
end
numdiff = [sj numdiff]; 

% save descriptives from all subjects 
t = date;
save([savedir,mod,'_',datasegmenter(end-11:end),'_',saveartifact,'_',t,'.mat'],'numdiff');

%% write to txtfile

% mean for each column
m = round(mean(numdiff(1:end,2:7),1));
m = [0 m];
numdiff = [m; numdiff];

% lowest percentage of retained samples
minsmp = round(min(numdiff(:,7)));
maxsmp = round(max(numdiff(:,7)));

% for k =1:numel(subjectnames)
%   if numdiff(k,6) >= minsmp && numdiff(k,6) < 40
%     numdiff(k,7) = 1;
%   end 
%   
%   if numdiff(k,6) < 60
%     numdiff(k,8) = 1;
%   end
%   
%   if numdiff(k,6) > 80
%     numdiff(k,9) = 1;
%   end
% end 

% cutoffs 
tmp = find(numdiff(2:end,7) >=minsmp & numdiff(2:end,7) < 51); il = subjectnames(tmp);
tmp = find(numdiff(2:end,7) >50 & numdiff(2:end,7)< 80); im = subjectnames(tmp);
tmp = find(numdiff(2:end,7) >= 80); ih = subjectnames(tmp);
time = now;
tt = datestr(time);

% write to textfile
fid = fopen([savedir,'smpdiff_',mod,'_',datasegmenter(end-22:end),'_',saveartifact,'.txt'],'w');
fprintf(fid,'MOUS visual modality - 102 subjects on %s\n\n',tt(1:11));
fprintf(fid,'across subjs the number of samples is\nminimum: %d%% and maximum: %d%%\n\n',minsmp,maxsmp);
fprintf(fid,'divide subjects into 3 categories of samples retained: low, medium and high\n\n');
fprintf(fid,'subjects between minimum-50%% samples retained: N = %d\n',numel(il))
for k = 1:numel(il)
  if k < numel(il)
    fprintf(fid,'%s\t',il{k});
  else 
    fprintf(fid,'%s\n\n',il{k});
  end    
end 
fprintf(fid,'subjects between 51 - 79%% samples retained: N = %d\n',numel(im));
for k = 1:numel(im)
  if k < numel(im)
    fprintf(fid,'%s\t',im{k});
  else
    fprintf(fid,'%s\n\n',im{k});
  end                                         
end 
fprintf(fid,'subjects with >= 80%% trials retained: N = %d\n',numel(ih));
for k = 1:numel(ih)
  if k < numel(ih)
    fprintf(fid,'%s\t',ih{k});
  else 
    fprintf(fid,'%s\n\n',ih{k});
  end    
end 

fprintf(fid,'Table of descriptive statistics\n*first row shows group averages per column\n\n');
fprintf(fid,'%6s\t %6s %6s\t %6s\t\t\t %6s\t %6s\t %6s\n','subj','pretrial', 'posttrial', 'presmp', 'postsmp', 'trialrem%', 'smprem%');
fprintf(fid,'%4d\t\t %4d\t\t %4d\t\t\t %4d\t\t\t %4d\t\t\t %6.2f\t\t\t %6.2f\n',numdiff');
fclose(fid);

% visualise
% figure; hist(numdiff(:,6),40:100)
% figure; bar(numdiff(:,6),0.4);

