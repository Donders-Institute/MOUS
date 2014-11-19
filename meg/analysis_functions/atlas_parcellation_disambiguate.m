function [atlasout] = atlas_parcellation_disambiguate(atlas, parcelparam)

% ATLAS_PARCELLATION_DISAMBIGUATE removes the scattered ??? vertices from
% the designated parcellation by assigning those vertices the label, by
% majority vote of its connections

% recurse in the case of >1 parcelparam
if iscell(parcelparam)
  atlasout = atlas;
  for k = 1:numel(parcelparam)
    atlasout = atlas_parcellation_disambiguate(atlasout, parcelparam{k});
  end
  return;
end

P     = atlas.(parcelparam);
label = atlas.([parcelparam,'label']);
tri   = atlas.tri;

% identify the parcel indices which have ???
sel = find(~cellfun('isempty',strfind(label,'???')));

% identify which parcel indices don't count for replacement
exclude = cat(1,sel,find(~cellfun('isempty',strfind(label,'MEDIAL'))));

Pnew = P;
for k = 1:numel(sel)
  % identify the vertices which have ???
  indx = find(P==sel(k));
  
  for m = 1:numel(indx)
    % identify the neighbours to this vertex
    seltri  = sum(tri==indx(m),2)>0;
    selnghb = tri(seltri,:);
    selnghb = setdiff(unique(selnghb(:)), indx(m));
    
    % get the parcels' indices for the neighbours
    selval  = P(selnghb);
    
    if sum(ismember(selval,exclude))>=sum(~ismember(selval,exclude))&&0
      % don't do anything if the majority of the neighbours are of the
      % 'exclude-type', unless it's only bordering the medial wall
            
    else
      tmpval = mode(selval(~ismember(selval,exclude)));
      if isfinite(tmpval)
        Pnew(indx(m)) = tmpval;
      else
        Pnew(indx(m)) = mode(selval);
      end
    end
  end
  
end

% create the output
atlasout = atlas;
atlasout.(parcelparam) = Pnew;


