function mous_bfica_singlevoxeltest_SvsWlate

% Get location of voxels used to plot the time courses for Se-l vs. WLe-l
% For each subject, extract voxel values for Senlate and WLlate
% perform statistics at group-level 

% Voxel locations within 11000 voxel box
x    = 3; y = 16;   z = 6;        % Left temporal  (theta)
item = sub2ind([20 25 22],x,y,z);
% x    = 4; y = 16;   z = 7;        % Left temporal  (alpha)
% item2  = sub2ind([20 25 22],x,y,z);

x    = 15; y = 22; z = 12;        % Right frontal  (theta, alpha, and beta)
ifrt = sub2ind([20 25 22],x,y,z);

x    = 7; y = 4;   z = 13;        % Left occipital (alpha, beta)
iocc = sub2ind([20 25 22],x,y,z);

x    = 16; y = 9;   z = 15;       % Right parietal (theta, alpha, and beta)
ipar = sub2ind([20 25 22],x,y,z);

iall = [item ifrt iocc ipar];


%% loop throught subjects to collect values at predefined voxels
[subj,~] = mous_db_getfilename('allV','subjectname');
% subj     = subj(1:5);
nsubj    = numel(subj);
sen      = zeros(nsubj,numel(iall)); % 102 x Ð4
wl       = zeros(nsubj,numel(iall)); % 102 x Ð4

for k = 1:nsubj
  mous_db_getdata(subj{k},'meg_bfica_sourcedata_earlylateSEN_matched_strat_low');
  senlate = tlcklate;
   
  mous_db_getdata(subj{k},'meg_bfica_sourcedata_earlylateWL_matched_strat_low');
  wllate = tlcklate;
  
  cfg = [];
  cfg.frequency = 5;
  senlate       = ft_selectdata(cfg,senlate); 
  wllate        = ft_selectdata(cfg,wllate);   
  
  % Convert voxels into within 5782 index
  % newinsides holds the indices of the insides from 11000 voxels
  % iall       holds the indices of the voxesl from 11000 voxels
  % insidx     has the index of iall within newinsides     
  mous_db_getdata(subj{k},'meg_bfica_leadfield8mm');
  insidx = ismember(newinside,iall);
  insidx = find(insidx);
  
  % select baseline
  bsltoi      = [-inf -0.09];
  bslsenlate  = ft_selectdata(senlate,'toilim',bsltoi);
  bslwllate   = ft_selectdata(wllate,'toilim', bsltoi);
  
  % baseline correction  
  bslcom      = (bslsenlate.avg + bslwllate.avg)/2;
  senlate.avg = senlate.avg - repmat(bslcom,[1,1,size(senlate.avg,3)]);
  wllate.avg  = wllate.avg  - repmat(bslcom,[1,1,size(wllate.avg,3)]);
    
  % loop through voxel locations to get values
  tidx = find(senlate.time == 0.25);
  
  for kk = 1:numel(iall)
    sen(k,kk) = mean(senlate.avg(insidx(kk),:,[tidx, tidx+2, tidx+4])); % e.g., senlate(5935,1,[8,10,12])
    wl(k,kk)  = mean(wllate.avg(insidx(kk),:,[tidx, tidx+2, tidx+4]));
  end 
end

% calculate average

avgsen = mean(sen,1);  % temp, frontal, occ, par
avgwl  = mean(wl,1);

ssqsen = zeros(1,4);  ssqwl  = zeros(1,4);
sumsen = zeros(1,4);  sumwl  = zeros(1,4);
semsen = zeros(1,4);  semwl  = zeros(1,4);


for kk = 1:numel(iall)
  % calculate standard error of the mean
  ssqsen(kk) = sum(sen(:,kk).^2);  % ssqsen = sum(ssqsen(:,kk));
  ssqwl(kk)  = sum(wl(:,kk).^2);   % ssqwl  = sum(ssqwl(:,kk));

  sumsen(kk) = sum(sen(:,kk));
  sumwl(kk)  = sum(wl(:,kk));

  semsen(kk) = (ssqsen(kk) - sumsen(kk).^2./nsubj)./(nsubj-1);
  semwl(kk)  = (ssqwl(kk)  - sumwl(kk).^2./nsubj)./(nsubj-1);
end


% plot bar graphs
bar(avgsen(1), avgwl(1)); hold on;
errorbar([avgsen(1),avgwl(1)],[semsen(1),semwl(1)]);  % dtem 

bar(avgsen(2), avgwl(2)); hold on;
errorbar([avgsen(2),avgwl(2)],[semsen(2),semwl(2)],'g');  % dfrt  

bar(avgsen(3), avgwl(3)); hold on; 
errorbar([avgsen(3),avgwl(3)],[semsen(3),semwl(3)],'r');  % docc  

bar(avgsen(4), avgwl(4));hold on;
errorbar([avgsen(4),avgwl(4)],[semsen(4),semwl(4)],'k');  % dpar 