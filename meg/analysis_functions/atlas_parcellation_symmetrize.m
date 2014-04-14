function [atlasout, diagn] = atlas_parcellation_symmetrize(atlas, parcelparam)

% ATLAS_PARCELLATION_SYMMETRIZE makes a parcellation left-right symmetric,
% assuming the cortical sheet is left-right registered.

% recurse in the case of >1 parcelparam
if iscell(parcelparam)
  atlasout = atlas;
  for k = 1:numel(parcelparam)
    [atlasout, diagn{k}] = atlas_parcellation_symmetrize(atlasout, parcelparam{k});
  end
  return;
end

P     = atlas.(parcelparam);
label = atlas.([parcelparam,'label']);

nparc = numel(setdiff(unique(P(:)),0));
npos  = numel(P(:,1));

% identify the parcel indices which have ???
sel = find(~cellfun('isempty',strfind(label,'???')));
unindx1 = sel(1); % 'un-index value', this value will replace the parcel index for the asymmetrically assigned vertices
unindx2 = sel(2);

% assume the list of labels to be well-behaved, i.e. first a set of left
% parcels, then a set of right parcels, in the same order
Pnew = P;
for k = 1:nparc/2
  indx1 = find(P==k);
  indx2 = find(P==k+nparc/2);
  
  % find the matching vertices, these are no problem
  indxok     = intersect(indx1, indx2-npos/2);
  
  % these are not homologous vertices
  indx1notok = setdiff(indx1,        indxok);
  indx2notok = setdiff(indx2-npos/2, indxok)+npos/2;

  Pnew([indx1notok; indx2notok-npos/2]) = unindx1;
  Pnew([indx2notok; indx1notok+npos/2]) = unindx2;
  
  diagn(k).indx1notok = indx1notok;
  diagn(k).indx2notok = indx2notok;
  diagn(k).label      = label{k};
end

% create the output
atlasout = atlas;
atlasout.(parcelparam) = Pnew;


