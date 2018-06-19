function stats = mous_multisetcca_regress(tlck, design, stimuli, folds, varargin)
%This function models timelocked data with a GLM given some predictors in variable
%design, and does a model comparison against a reduced model where the
%reduced model can be defined with the key 'modelcomparison' (default is to
%compare only first predictor against rest). If specified, constant will be
%added post orthogonalisation.
lambda              = 1;
ortho               = ft_getopt(varargin, 'ortho', {});
contentwords_only   = ft_getopt(varargin, 'contentwords_only', false);
reduceto            = ft_getopt(varargin, 'modelcomparison', []);
constant            = ft_getopt(varargin, 'constant', false);

if nargin<4
    folds = [];
end

if iscellstr(ortho)
    indx = find(ismember(design.Properties.VariableNames,ortho));
    if length(indx) == length(ortho)
        ortho = indx;
    else
        ft_warning('variables for orthogonalising not present in design matrix')
        return
    end
else
    if max(ortho) >= size(design,2)
        ft_warning('mismatch between design matrix and ortho parameters')
        return
    end
end

if iscellstr(reduceto)
    indx = find(ismember(design.Properties.VariableNames,reduceto));
    if length(indx) == length(reduceto)
        reduceto = indx;
    else
        warning('variables for model comparison not present in design matrix')
    end
else
    if max(reduceto) >= size(design,2)
        warning('mismatch between design matrix and model comparison parameters')
    end
end

if contentwords_only
    % identify the nouns, adjectives and verbs
    sel =       double(strncmp(tlck.trialinfo.POS, 'N',   1))*1;
    sel = sel + double(strncmp(tlck.trialinfo.POS, 'WW',  2))*2;
    sel = sel + double(strncmp(tlck.trialinfo.POS, 'ADJ', 3))*3;
    
    cfg        = [];
    cfg.trials = find(sel);
    tlck       = ft_selectdata(cfg, tlck);
    
    design     = design(sel>0,:);
end

if ~iscell(folds) && ~isempty(folds)
    folds = mous_makefolds(size(tlck.trial,1), folds); 
  %FIXME: folds can be either integer or cell array, but now folds will not
  %be interpreted as pre-supplied weights
end
    
    if ~isempty(ortho)
        [~, n] = size(ortho);
        y   = table2array(design(:,setdiff(1:size(design,2),ortho)));
        x   = table2array(design(:,ortho));
        y   = y-x*((x'*x)\(x'*y));
        design = [x y];
        %permute design to ensure original order of predictors
        order           = 1:size(design,2);
        neworder(ortho) = order(1:n);
        neworder(setdiff(order,ortho)) = order(n+1:end);
        design = design(:,neworder);
        clear y x
    else
        design = cell2mat(table2cell(design));
    end
    
    if constant
        design = [ones(size(design,1),1) design];
        fprintf('adding constant to design matrix')
    end
    
    %% do the regressions
    [F, R0, R, n, p1, p2, B] = dat2F(tlck.trial, design, reduceto, lambda, folds);
    stats.F  = F;
    stats.R  = R;
    stats.R0 = R0;
    stats.p1 = p1;
    stats.p2 = p2;
    stats.n  = n;
    stats.B  = B;
    stats.ivar = tlck.trialinfo.Properties.VariableNames;
    
    %FIXME: maybe we want an option for iteratively doing the model comparison?
    %adding one predictor at a time as seems to have been done before?
    %   for k = 1:size(Xnew,2)-4
    %     %tmpX = orthogonalise(X(:,[1 2 3 4 5 5+k]));
    %     tmpX = Xnew(:,[1 2 3 4 4+k]);
    %     [F(:,:,k), R0(:,:,k), R(:,:,k), n(k), p1(k), p2(k), B(:,:,:,k)] = dat2F(tlck.trial,tmpX,[1 2 3 4]);
    %   end
    
    %FIXME:when is the normalisation needed??
    %   V = normc(tlck.trialinfo.w2v);
    %   X = normc(table2array(tlck.trialinfo(:,1:11)));

function [F, R0, R, n, p1, p2, B] = dat2F(alldat, design, col0, lambda, B)

if nargin<3 || isempty(col0)
    col0 = 1;
end

if nargin<4 || isempty(lambda)
    lambda = 0;
end

if nargin<5
    B = [];
end

n  = size(design,1);
p2 = size(design,2);
p1 = numel(col0);

siz = size(alldat);
%dat = reshape(permute(alldat,[1 3 2]),[siz(1) siz(2)*siz(3)]);
dat = reshape(alldat,[siz(1) siz(2)*siz(3)]);
%dat = dat - nanmean(dat,1);
%dat = normc(dat);
if isempty(B)
    if ~lambda
        B   = design\dat;
    else
        B   = ((design'*design+lambda.*eye(size(design,2)))\design')*dat;
    end
elseif iscell(B)
    % assume that B is a cell-array containing the indices of the test-folds.
    for k = 1:numel(B)
        ix = B{k};
        iy = setdiff(1:size(alldat,1),ix);
        [~,  ~, ~, ~, ~, ~, Btmp] = dat2F(alldat(iy,:,:), design(iy,:), col0, lambda);
        [~, tmpR0, tmpR]          = dat2F(alldat(ix,:,:), design(ix,:), col0, lambda, Btmp);
        if k==1
            R0 = tmpR0.*numel(ix);
            R  =  tmpR.*numel(ix);
            n  =        numel(ix);
        else
            R0 = tmpR0.*numel(ix) + R0;
            R  = tmpR .*numel(ix) + R;
            n  =        numel(ix) + n;
        end
    end
    F = (R0-R)./R;
    return;
else
    % use the pre-supplied weights
    %B = reshape(permute(B, [1 3 2]), [size(B,1) size(B,2)*size(B,3)]);
    B = reshape(B, [size(B,1) size(B,2)*size(B,3)]);
    
end

R0 = reshape(sum((dat-design(:,col0)*B(col0,:)).^2),[siz(2) siz(3)]);
R  = reshape(sum((dat-design*B).^2),[siz(2) siz(3)]);

F  = ((R0-R)./(p2-p1))./(R./(n-p2));
%B  = permute(reshape(B,[size(B,1) siz(3) siz(2)]),[1 3 2]);
B  = reshape(B,[size(B,1) siz(2) siz(3)]);
