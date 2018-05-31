
%load variables
nVtx = 8196;
tstep = 120;%+maxlag; % in samples
n = 1;
interval = [n n+tstep n+tstep+360];% start interval in samples
nperm = 1000; %number of parcellations
 %% get filenames 
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);

end

%load data
load xcorr_lagmaxvalstim
load xcorr_lagmaxvalbsl

%% Subtract bsl 
newp = zeros(Nsubj*2,Nsubj*2,nVtx,length(interval));
for l = 1:length(interval)
    for k = 1:size(p,3)
        newp(:,:,k,l)=abs(p(:,:,k,l))-abs(pb(:,:,k));
    end
end

newpx = zeros(2,2,nVtx,length(interval));
P=[ones(1,Nsubj) zeros(1,Nsubj);zeros(1,Nsubj) ones(1,Nsubj)];
for l = 1:length(interval)
    for k = 1:size(newp,3)
        newpx(:,:,k,l)=P*newp(:,:,k,l)*P';
    end
end
newpx=newpx./(Nsubj^2);



%% Permutation test
% this script is going to creatively use the data matrix in combination
% with ft_statistics_montecarlo to get a randomization distribution for
% some test-statistic that we consider to be a good one

% ft_statistics_montecarlo takes a Nvox x Nrepl matrix in the input
% we are going to first reshape the data matrix accordingly

% starting from a Nsubj x Nsubj x Nvert x Ninterval matrix
Ninterval = 3; % specify interval of interest
Nquad = 2; % specify quadrant of interest (1 = visuals, 2/3 = supramodal, 4 = auditory)
nperm = 1000;

quad=reshape(permute(reshape(newp,[Nsubj 2 Nsubj 2 8196 3]),[1 3 2 4 5 6]),Nsubj^2,4,8196,3);


dat = squeeze(quad(:,Nquad,:,Ninterval))';

if ismember(Nquad,[1 4])% feed in only lower triangle for within-modality quadrants
indx=reshape(1:Nsubj^2,Nsubj,Nsubj);
selindx=indx(tril(indx,-1)>0);
dat = dat(:,selindx);
end

dat0 = dat;
dat0(:) = 0;

% design is adapted to numer of observations according to size of lower
% triangle
design = [ones(1,size(dat,2)) ones(1,size(dat,2))*2; 1:size(dat,2) 1:size(dat,2)];


cfg = [];
cfg.statistic = 'statfun_sophiessuperstatistic';
cfg.numrandomization = nperm;
cfg.correctm = 'max';
cfg.ivar = 1;
cfg.uvar = 2;
cfg.tail = 1;
stat = ft_statistics_montecarlo(cfg, [dat dat0], design);


% stats
% for k = 1:nVtx
%         if mean(dat(k,:)) >= stat.posdistribution(end-((nperm/100)*5)-1) %|| mean(dat(k,:)) <= stat.negdistribution(end-((nperm/100)*5)-1) 
%             sig(k) = 1;
%         else
%             sig(k) = 0;
%         end
% end