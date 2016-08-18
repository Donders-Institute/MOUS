function [sR,S,A,W,iq, sel] = mous_granger_ica(subjectname, method, opts)

if nargin<2 || isempty(method)
  method = 'icasso';
end

if nargin<3
  opts = [];
end

if ~isfield(opts, 'usetoti'), opts.usetoti = false; end
if ~isfield(opts, 'useroi'),  opts.useroi  = false; end
if ~isfield(opts, 'dosave'),  opts.dosave  = false; end
if ~isfield(opts, 'overwrite'), opts.overwrite = false; end
if ~isfield(opts, 'condition'), opts.condition = {'sent_early' 'sent_late' 'seq_early' 'seq_late'}; end
if ~isfield(opts, 'combine'), opts.combine = true;  end
if ~isfield(opts, 'ncomp'),   opts.ncomp   = 10; end

if ~iscell(opts.condition)
  opts.condition = {opts.condition};
end

for k = 1:numel(opts.condition)
  mous_db_getdata(subjectname,['meg_granger_granger_',opts.condition{k}],'/project/3011020.09/jansch');
  g = ft_struct2double(g);
  if opts.usetoti,
    g2 = ft_struct2double(g2);
    if k==1,                  G2               = g2; end 
    if k==1 && opts.combine,  G2.totispctrm(:) = 0;  end
    if opts.combine,          G2.totispctrm = G2.totispctrm + g2.totispctrm; end
    if k>1 && ~opts.combine,  G2.totispctrm = cat(2,G2.totispctrm, g2.totispctrm); end
  end
  clear g2;
  
  if k==1, G = g; end
  if k==1 && opts.combine, G.grangerspctrm(:) = 0; end
  if opts.combine, G.grangerspctrm = G.grangerspctrm + g.grangerspctrm; end
  if k>1 && ~opts.combine, G.grangerspctrm = cat(4,G.grangerspctrm,g.grangerspctrm); end
  clear g;
end  

if opts.combine,
  if opts.usetoti
    G2.totispctrm = G2.totispctrm./numel(opts.condition);
  end
  G.grangerspctrm = G.grangerspctrm./numel(opts.condition);
end

triangle_low = tril(ones(378),-1)>0;
n = sum(triangle_low(:));
Gdat = zeros(n*2, 120, size(G.grangerspctrm,4));
% concatenate the lower and upper triangles
for k = 1:120
  for m = 1:size(G.grangerspctrm,4)
    tmp = G.grangerspctrm(:,:,k,m); tmp2 = tmp';
    tmp = [tmp(triangle_low);tmp2(triangle_low)];
    Gdat(:,k,m) = tmp;
  end
end
Gdat = reshape(Gdat, [], size(Gdat,2)*size(Gdat,3));

if opts.usetoti,
  Gdat = [Gdat; G2.totispctrm(:,1:120)-Gdat(1:n,:)-Gdat(n+(1:n),:)];
end

if opts.useroi
  [C, label, P, list, lay] = mous_edgesofinterest;
  [a, b] = match_str(G.label, label(:,1));
  label  = label(b,:);
  P      = P(:,b);
  C      = C(b,b);
  rois   = list(sum(P*C*P')>0);
  sel    = find(ismember(label(:,3),rois));
  indx   = zeros(378);
  indx(tril(ones(378),-1)>0) = 1:n;
  indx   = indx(sel,sel);
  sel    = indx(indx(:)>0);
  if opts.usetoti,
    sel = [sel(:);sel(:)+n;sel(:)+2*n];
  else
    sel = [sel(:);sel(:)+n];
  end
  tmp  = false(size(Gdat,1),1);
  tmp(sel) = true;
  sel  = tmp;clear tmp;
  Gdat = Gdat(sel,:);
end

% load atlas_conte69_8196reg_LR_brodmann_subparc;
% tmp = parcellation2connectivity(atlas);
% [a,b] = match_str(G.label,atlas.parcellationlabel);
% C(a,a) = tmp(b,b);
% C = C*C;
% sel = sel&C(:)==0;

ft_hastoolbox('icasso', 1);
ft_hastoolbox('fastica', 1);
switch method
  case 'icasso'
    [iq, A, W, S, sR]=icasso(Gdat',25,'g','tanh','lastEig',20*numel(subj),'approach','defl','maxNumIterations',200);
    if ~opts.useroi,
      sR = rmfield(sR, 'signal');
    end
  case 'fastica'
    sR = [];
    iq = [];
    [S,A,W] = fastica(Gdat','g','tanh','interactivePCA','on','approach','defl','maxNumIterations',200);
  case 'nmf'
    %addpath ~/matlab/toolboxes/nmfpack;
    %[S, A] = nmfsc(Gdat, 20, 0.5, [], 'tolerance', 5e-4);
    %S = S';
    %%A = A';
    %A = (S'\Gdat)';
    %W = pinv(A);
    
    addpath ~/matlab/toolboxes/nmfv1_4;
    sR.signal = Gdat';
    iq = [];
    option = [];
    option.eta = 0;
    [A,S]=sparsenmfnnls(Gdat',opts.ncomp,option);
    W = pinv(A);
end
if opts.dosave,
  mous_db_putdata(subjectname, ['meg_granger_',method], 'iq', 'A', 'W', 'sR', 'S', 'sel', '/project/3011020.09/jansch',opts.overwrite);
end
