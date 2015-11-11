function mous_readin_genetics

% MOUS_READIN_GENETICS reads in the genotype for each subject from an excel
% file. White spaces occur in certain cells (from the excel sheet) and
% these are removed because they disrupt with diving up subjects into
% groups
% NL 15-10-2015

%% exclusions
% V1115 for KIAA0319 is "heterozygote/all 1": results were different for repeated tests

%% read in file
fname         = '/home/language/nielam/MOUS_AnalysisNotes/genetics/MOUS_5_SNPs.xlsx'; 
[~,txt,raw]   = xlsread(fname,3,'A1:H233'); 

%% create struct array
genc779                = struct('name',{},'bID',{},'genotype',{}); % CNTNAP2
genk172                = struct('name',{},'bID',{},'genotype',{}); % KIAA
genf698                = struct('name',{},'bID',{},'genotype',{}); % FOXP2
genf778                = struct('name',{},'bID',{},'genotype',{}); % FOXP2
genr680                = struct('name',{},'bID',{},'genotype',{}); % ROBO1
% gen453               = struct('name',{},'bID',{},'genotype',{}); % ROBO1

for k = 1:size(txt,1)-1
  genc779(k).name      = txt{k+1,1};
  genc779(k).bID       = txt{k+1,2};
  genc779(k).genotype  = txt{k+1,find(strcmp('rs7794745',txt(1,:)))};
  
  genk172(k).name      = txt{k+1,1};
  genk172(k).bID       = txt{k+1,2};
  genk172(k).genotype  = txt{k+1,find(strcmp('rs17243157',txt(1,:)))};
  
  genf698(k).name      = txt{k+1,1};
  genf698(k).bID       = txt{k+1,2};
  genf698(k).genotype  = txt{k+1,find(strcmp('rs6980093',txt(1,:)))};
  
  genf778(k).name      = txt{k+1,1};
  genf778(k).bID       = txt{k+1,2};
  genf778(k).genotype  = txt{k+1,find(strcmp('rs7784315',txt(1,:)))};

  genr680(k).name      = txt{k+1,1};
  genr680(k).bID       = txt{k+1,2};
  genr680(k).genotype  = txt{k+1,find(strcmp('rs6803202',txt(1,:)))}; 
  
%   genr453(k).name      = txt{k+1,1};
%   genr453(k).bID       = txt{k+1,2};
%   genr453(k).genotype  = txt{k+1,???};
end

%% remove trailing white space (damn people)
for k = 1:size(genc779)
  genc779(k).genotype = strtrim(genc779(k).genotype);
  genk172(k).genotype = strtrim(genk172(k).genotype);
  genf698(k).genotype = strtrim(genf698(k).genotype);
  genf778(k).genotype = strtrim(genf778(k).genotype);
  genr680(k).genotype = strtrim(genr680(k).genotype); 
%   gen????(k).genotype = strtrim(gen????(k).genotype;
end

%% save
d = date;
d = tokenize(date,'-');
d = [d{1} d{2} d{3}];
save(['/project/3011020.09/nielam/groupresults/genetics/geneticstable_',d],'genc779','genk172','genf698','genf778','genr680');