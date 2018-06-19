function [compout, rhoout] = mous_multisetcca_postprocess(comp, rho, label, comp_id)

% reorganize the comp cell-array from a nfold x nsubj array into a single
% structure, where the individual channels reflect the per subject
% occurrence of same stimuli, for the first component only

% reorganize the rho matrix such that it contains correlation values, and
% only keep the on-diagonal blocks

if nargin<4 
  comp_id = 1;
end

if iscell(comp) && size(comp,2)>1
  [nfold, nset] = size(comp);
  ncomp = numel(comp{1}.label);
  
  % deal with comp
  for k = 1:numel(comp)
    comp{k} = rmfield(comp{k}, {'unmixing' 'topo'});
  end
  
  compout = cell(1,nset);
  if nfold>1
  for k = 1:nset
    compout{k} = ft_appenddata([],comp{:,k});
  end
  else
    compout = comp;
  end
  cfg = [];
  for k = 1:nset
    sel = strncmp(compout{k}.label,sprintf('mscca%03d',comp_id),8);
    cfg.channel = compout{k}.label(sel);
    compout{k}  = ft_selectdata(cfg, compout{k});
    compout{k}.label = strrep(compout{k}.label,'mscca001',label);
    compout{k}.time  = compout{1}.time;
    T(:,k) = compout{k}.trialinfo(:,end);
  end
  compout = ft_appenddata([], compout{:});
  compout.trialinfo = nanmedian(T,2);
elseif iscell(comp)
  lab = comp{1}.label;
  for k = 1:numel(lab)
    tok = tokenize(lab{k},'_');
    lab{k} = tok{1};
  end
  ncomp = numel(unique(lab));
  nset  = numel(lab)./ncomp;
  
  % deal with comp
  for k = 1:numel(comp)
    comp{k} = rmfield(comp{k}, {'unmixing' 'topo'});
  end
  compout = ft_appenddata([], comp{:});
  
  cfg = [];
  cfg.channel = compout.label(comp_id:ncomp:end);
  compout = ft_selectdata(cfg, compout);
  
else
  nset    = comp(1);
  ncomp   = comp(2);
  compout = [];
end

% deal with rho
rhoout = zeros(nset,nset,ncomp);
rho    = mean(rho,3);
rho    = rho./sqrt(diag(rho)*diag(rho)');
for k = 1:ncomp
  indx = (k-1)*nset + (1:nset);
  rhoout(:,:,k) = rho(indx,indx);
end