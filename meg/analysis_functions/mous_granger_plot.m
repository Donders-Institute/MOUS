function mous_granger_plot(g, source, parcellation, hemi, varargin)

parcelparam = ft_getopt(varargin, 'parcelparam', 'parcellation');

% load the flatmap and the outlines of the layout here
switch hemi
  case 'left'
    flatmap = flatmap_left;
    source.pos          = source.pos(1:4098,:);
    source.parcellation = source.(parcelparam)(1:4098,:);
  case 'right'
    flatmap = flatmap_right;
end

usepoints = double(unique(flatmap.tri(:)));

% create 'sensor positions' and labels for the layout, based on the average of the
% vertices that go into a given parcel
sel = find(~cellfun(@isempty, parcellation.filter));
for k = 1:numel(sel)
  selpos = find(sum(source.parcellation==sel(k),2)>0);
  if ~isempty(selpos)
    %tmppos = trimmean(flatmap.pnt(intersect(usepoints, selpos),:));
    tmp = intersect(usepoints, selpos);
    if ~isempty(tmp)
      pos(k,:) = flatmap.pnt(tmp(1),:);
      label(k,1) = parcellation.label(sel(k));
    else
      pos(k,:) = nan;
    end
  end
end
selpos = isfinite(pos(:,1));
layout.pos   = pos(selpos,1:2);
layout.label = label(selpos);
layout.height = 0.01*ones(size(layout.pos,1),1);
layout.width  = 0.01*ones(size(layout.pos,1),1);
