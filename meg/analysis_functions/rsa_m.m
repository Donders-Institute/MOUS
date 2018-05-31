function newp = rsa_m(voxelstart,voxelend,latewindow,windowsize)

% Variables
numvox = numel(voxelstart:voxelend);
tstep = windowsize;%+maxlag; % in samples
interval = [1 121 latewindow];% start interval in samples
subjA = mous_db_getfilename('allA','subjectname');
subjV = mous_db_getfilename('allV','subjectname');
if numel(subjA) == numel(subjV)
    Nsubj = numel(subjA);
else
    warning('Number of subjects is not equal');
    Nsubj = numel(subjA);
    
end

newp = zeros(Nsubj*2,Nsubj*2,length(interval),numvox);
for k = voxelstart:voxelend
    %% Load mne_source reconstruction for all subjects for one voxel
    load(strcat('/project/3011020.09/sopara/mne_pervoxel/baseline/v',num2str(k)))
    outbsl = out;
    load(strcat('/project/3011020.09/sopara/mne_pervoxel/postonset_wordlist/v',num2str(k)))
    
    
    %% Compute baseline correlation
    pb = zeros(Nsubj*2,Nsubj*2);
    sel = zeros(Nsubj*2,size(outbsl,2));
    sel = squeeze(outbsl(:,(end-tstep):end));
    [n,p1]= size(sel');
    [xrank, xadj] = tiedrank(sel',0);
    sel = xrank';
    
    sel = bsxfun(@minus,sel,sum(sel,2)/n);  % Remove mean
    coef = sel * sel';
    d = sqrt(diag(coef)); % sqrt first to avoid under/overflow
    coef = bsxfun(@rdivide,coef,d); coef = bsxfun(@rdivide,coef,d'); % coef = coef ./ d*d';
    coef(1:p1+1:end) = sign(diag(coef));
    %coef = corr(sel','type','spearman','rows','complete');
    pb(:,:)=coef;
    clear sel coef d
    
    % average
    % pbx(:,:)=P*abs(pb(:,:))*P';
    % pbx=pbx./(Nsubj^2);
    % val = max(pbx(:));
    
    
    %% Compute correlation across subjects
    
    p = zeros(Nsubj*2,Nsubj*2,length(interval));
    
    for i = 1:length(interval)
        sel = squeeze(out(:,interval(i):interval(i)+tstep));
        [n,p1]= size(sel');
        [xrank, xadj] = tiedrank(sel',0);
        sel = xrank';
        sel = bsxfun(@minus,sel,sum(sel,2)/n);  % Remove mean
        coef = sel * sel';
        d = sqrt(diag(coef)); % sqrt first to avoid under/overflow
        coef = bsxfun(@rdivide,coef,d); coef = bsxfun(@rdivide,coef,d'); % coef = coef ./ d*d';
        coef(1:p1+1:end) = sign(diag(coef));
        %    coef = corr(sel','type','spearman','rows','complete');
        p(:,:,i) = coef;
    end
    clear sel coef
    
    % average
    % px = zeros(2,2,length(interval));
    % for i = 1:length(interval)
    %     px(:,:,i)=P*abs(p(:,:,i))*P';
    % end
    % px=px./(Nsubj^2);
    % val = max(px(:));
    
    %% Subtract baseline correlation
    for l = 1:length(interval)
        newp(:,:,l,(k+1) - voxelstart)=abs(p(:,:,l))-abs(pb(:,:));
    end
    

end
end

