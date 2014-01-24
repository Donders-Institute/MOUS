
rootdir = '/project/3011020.09/jansch';
suffix ='_allwords_01-10'; 
[subj,s] = setdiff(mous_db_getfilename('allV','subjectname'), mous_db_getfilename('bad','subjectname'));
[f,exist_data]   = mous_db_getfilename(subj,['meg_processed_{_mne' suffix '-sent_currentdensity_weighted}'], 0,rootdir);

subj    = subj(exist_data);
Nsubj   = numel(subj);

meantime = [0.2 0.5];

mnicoord=[-50.3, 3, 9];  %mni coordinates you would liketo find

for n=1:Nsubj
 
%% Get Beta value from fmri
 
 file = ['/home/language/juludd/MOUS/ffxstats/' subj{n} '-ffxStats/beta_0001.img'];
 mri = ft_read_mri(file);


 mni = ft_warp_apply(inv(mri.transform),mnicoord);  %use the tranfomration matrix of this subjetcs to get the index corresponding to the input mni coordinates
 mni =round(mni);
 beta(n) = mri.anatomy(mni(1), mni(2),mni(3)); % beta value
 
 %% Get dspm value from mmne
 

 dspmMean(n) = mous_getmnefromfrmi(subj{n}, meantime,mni);
  
 
end
 
 % Compute correlation between fmri and MEG
 
 
[R,P]=corrcoef(dspmMean, beta);

scatter(dspmMean, beta)
 
  
 

 
 
 
 
 
 