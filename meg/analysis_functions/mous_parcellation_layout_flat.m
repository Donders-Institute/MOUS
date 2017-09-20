function layout = mous_parcellation_layout_flat(source, varargin)

parcelparam = ft_getopt(varargin, 'parcelparam', 'parcellation');
hemi        = ft_getopt(varargin, 'hemi', 'both');

% load the flatmap and the outlines of the layout here
switch hemi
  case 'left'
    load('layout_flatmap_colin_left');
    load('cortex_flatmap_8196reg_colin_left');
    source.pos           = source.pos(1:4098,:);
    source.(parcelparam) = source.(parcelparam)(1:4098);
    usepoints            = find(flatmap.pnt(:,1)~=300 & flatmap.pnt(:,2)~=0);
  case 'right'
    load('layout_flatmap_colin_right');
    load('cortex_flatmap_8196reg_colin_right');
    source.pos           = source.pos(4098+(1:4098),:);
    source.(parcelparam) = source.(parcelparam)(4098+(1:4098));
    usepoints            = find(flatmap.pnt(:,1)~=0 & flatmap.pnt(:,2)~=0);
  case 'both'
    sel = match_str(varargin, 'hemi');
    varargin(sel+1) = {'left'};
    layoutleft  = mous_parcellation_layout_flat(source, varargin{:});
    varargin(sel+1) = {'right'};
    layoutright = mous_parcellation_layout_flat(source, varargin{:});

    layoutleft.pos(:,1)  = layoutleft.pos(:,1)-240;
    for k = 1:numel(layoutleft.mask)
      layoutleft.mask{k}(:,1) =  layoutleft.mask{k}(:,1)-240;
    end
    for k = 1:numel(layoutleft.outline)
      layoutleft.outline{k}(:,1) =  layoutleft.outline{k}(:,1)-240;
    end
    layoutright.pos(:,1) = layoutright.pos(:,1)+240;
    for k = 1:numel(layoutright.mask)
      layoutright.mask{k}(:,1) =  layoutright.mask{k}(:,1)+240;
    end
    for k = 1:numel(layoutright.outline)
      layoutright.outline{k}(:,1) =  layoutright.outline{k}(:,1)+240;
    end
       
    % concatenate and rotate
    layout.pos     = [layoutleft.pos;layoutright.pos];
    layout.label   = [layoutleft.label;layoutright.label];
    layout.width   = [layoutleft.width;layoutright.width];
    layout.height  = [layoutleft.height;layoutright.height];
    layout.mask    = [layoutleft.mask layoutright.mask];
    layout.outline = [layoutleft.outline layoutright.outline];
    
    
    
    return;

end


source.(parcelparam) = source.(parcelparam)(usepoints);
flatmap.pnt          = flatmap.pnt(usepoints,:);

% create 'sensor positions' and labels for the layout, based on the average of the
% vertices that go into a given parcel
%sel = find(~cellfun(@isempty, parcellation.filter));
sel = 1:numel(source.([parcelparam,'label']));
for k = 1:numel(sel)
  selpos = find(source.(parcelparam)==sel(k));
  if ~isempty(selpos)
    pos(k,1:3) = mean(flatmap.pnt(selpos,:));
    label(k,1) = source.([parcelparam,'label'])(sel(k));
  else
    pos(k,:) = nan;
    label(k,1) = {''};
  end
end
selpos       = isfinite(pos(:,1));
layout.pos   = pos(selpos,1:2);
layout.label = label(selpos);
layout.height = 0.01*ones(size(layout.pos,1),1);
layout.width  = 0.01*ones(size(layout.pos,1),1);
