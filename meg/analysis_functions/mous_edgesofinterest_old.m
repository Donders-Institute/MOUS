function [C, label, P, list, lay] = mous_edgesofinterest

% this function is meant to keep track how the edgesofinterest are defined
% for the MEG based connectivity analysis

load atlas_conte69_8196reg_LR_brodmann_subparc

% map the labels of the montage onto the atlas
label  = atlas.parcellationlabel;
label2 = label;
[a,b]  = match_str(label, montage.labelorg);
label2(a) = montage.labelnew(b);

% switch off the subparcels of 6 and 9 that are 'irrelevant':
sel = find(strncmp(label2,'L_6',3));
sel = sel([1:3 5:10 12]);
for k = 1:numel(sel)
  label2{sel(k)} = strrep(label2{sel(k)},'6_','6x_');
end
sel = find(strncmp(label2,'R_6',3));
sel = sel([1:3 5:10 12]);
for k = 1:numel(sel)
  label2{sel(k)} = strrep(label2{sel(k)},'6_','6x_');
end
sel = find(strncmp(label2,'L_9',3));
sel = sel([1 5:end]);
for k = 1:numel(sel)
  label2{sel(k)} = strrep(label2{sel(k)},'9_','9x_');
end
sel = find(strncmp(label2,'R_9',3));
sel = sel([1 5:end]);
for k = 1:numel(sel)
  label2{sel(k)} = strrep(label2{sel(k)},'9_','9x_');
end

C = false(numel(label));

% The connections are defined based on a few publications/reviews
% The main sources are:
% Catani 2007, PNAS
% Friederici 2009, TICS
% Glasser and Rilling ???

% connect the posterior part of Areas 22 and 37 to 44,45,46 and 6
% define 6 as the part of BA6 directly adjacent to BA44
% in the current atlas these are subparcels 11 and 4
C = C | makeconnections(label2, 'L_44', 'L_temp_sup_post_22');
C = C | makeconnections(label2, 'L_44', 'L_temp_sup_post_37');
C = C | makeconnections(label2, 'L_44', 'L_temp_mid_post_22');
C = C | makeconnections(label2, 'L_44', 'L_temp_mid_post_37');
C = C | makeconnections(label2, 'L_45', 'L_temp_sup_post_22');
C = C | makeconnections(label2, 'L_45', 'L_temp_sup_post_37');
C = C | makeconnections(label2, 'L_45', 'L_temp_mid_post_22');
C = C | makeconnections(label2, 'L_45', 'L_temp_mid_post_37');
C = C | makeconnections(label2, 'L_46', 'L_temp_sup_post_22');
C = C | makeconnections(label2, 'L_46', 'L_temp_sup_post_37');
C = C | makeconnections(label2, 'L_46', 'L_temp_mid_post_22');
C = C | makeconnections(label2, 'L_46', 'L_temp_mid_post_37');
C = C | makeconnections(label2, 'L_6_', 'L_temp_sup_post_22');
C = C | makeconnections(label2, 'L_6_', 'L_temp_sup_post_37');
C = C | makeconnections(label2, 'L_6_', 'L_temp_mid_post_22');
C = C | makeconnections(label2, 'L_6_', 'L_temp_mid_post_37');

C = C | makeconnections(label2, 'R_44', 'R_temp_sup_post_22');
C = C | makeconnections(label2, 'R_44', 'R_temp_sup_post_37');
C = C | makeconnections(label2, 'R_44', 'R_temp_mid_post_22');
C = C | makeconnections(label2, 'R_44', 'R_temp_mid_post_37');
C = C | makeconnections(label2, 'R_45', 'R_temp_sup_post_22');
C = C | makeconnections(label2, 'R_45', 'R_temp_sup_post_37');
C = C | makeconnections(label2, 'R_45', 'R_temp_mid_post_22');
C = C | makeconnections(label2, 'R_45', 'R_temp_mid_post_37');
C = C | makeconnections(label2, 'R_46', 'R_temp_sup_post_22');
C = C | makeconnections(label2, 'R_46', 'R_temp_sup_post_37');
C = C | makeconnections(label2, 'R_46', 'R_temp_mid_post_22');
C = C | makeconnections(label2, 'R_46', 'R_temp_mid_post_37');
C = C | makeconnections(label2, 'R_6_', 'R_temp_sup_post_22');
C = C | makeconnections(label2, 'R_6_', 'R_temp_sup_post_37');
C = C | makeconnections(label2, 'R_6_', 'R_temp_mid_post_22');
C = C | makeconnections(label2, 'R_6_', 'R_temp_mid_post_37');

% connect BA39/40 to areas 44,45 and 46
C = C | makeconnections(label, 'L_39', 'L_44');
C = C | makeconnections(label, 'L_39', 'L_45');
C = C | makeconnections(label, 'L_39', 'L_46');
C = C | makeconnections(label, 'L_40', 'L_44');
C = C | makeconnections(label, 'L_40', 'L_45');
C = C | makeconnections(label, 'L_40', 'L_46');

C = C | makeconnections(label, 'R_39', 'R_44');
C = C | makeconnections(label, 'R_39', 'R_45');
C = C | makeconnections(label, 'R_39', 'R_46');
C = C | makeconnections(label, 'R_40', 'R_44');
C = C | makeconnections(label, 'R_40', 'R_45');
C = C | makeconnections(label, 'R_40', 'R_46');

% connect BA39/40 to the posterior part of 22 and 37
C = C | makeconnections(label2, 'L_39', 'L_temp_sup_post_22');
C = C | makeconnections(label2, 'L_39', 'L_temp_sup_post_37');
C = C | makeconnections(label2, 'L_39', 'L_temp_mid_post_22');
C = C | makeconnections(label2, 'L_39', 'L_temp_mid_post_37');
C = C | makeconnections(label2, 'L_39', 'L_temp_inf_post_22');
C = C | makeconnections(label2, 'L_39', 'L_temp_inf_post_37');
C = C | makeconnections(label2, 'L_40', 'L_temp_sup_post_22');
C = C | makeconnections(label2, 'L_40', 'L_temp_sup_post_37');
C = C | makeconnections(label2, 'L_40', 'L_temp_mid_post_22');
C = C | makeconnections(label2, 'L_40', 'L_temp_mid_post_37');
C = C | makeconnections(label2, 'L_40', 'L_temp_inf_post_22');
C = C | makeconnections(label2, 'L_40', 'L_temp_inf_post_37');

C = C | makeconnections(label2, 'R_39', 'R_temp_sup_post_22');
C = C | makeconnections(label2, 'R_39', 'R_temp_sup_post_37');
C = C | makeconnections(label2, 'R_39', 'R_temp_mid_post_22');
C = C | makeconnections(label2, 'R_39', 'R_temp_mid_post_37');
C = C | makeconnections(label2, 'R_39', 'R_temp_inf_post_22');
C = C | makeconnections(label2, 'R_39', 'R_temp_inf_post_37');
C = C | makeconnections(label2, 'R_40', 'R_temp_sup_post_22');
C = C | makeconnections(label2, 'R_40', 'R_temp_sup_post_37');
C = C | makeconnections(label2, 'R_40', 'R_temp_mid_post_22');
C = C | makeconnections(label2, 'R_40', 'R_temp_mid_post_37');
C = C | makeconnections(label2, 'R_40', 'R_temp_inf_post_22');
C = C | makeconnections(label2, 'R_40', 'R_temp_inf_post_37');

% connect areas 45 and 47 to 22/39/17-19 (This is what Catani refers to as
% the extreme capsule)
C = C | makeconnections(label, 'L_45', 'L_22');
C = C | makeconnections(label, 'L_45', 'L_39');
C = C | makeconnections(label, 'L_45', 'L_17');
C = C | makeconnections(label, 'L_45', 'L_18');
C = C | makeconnections(label, 'L_45', 'L_19');
C = C | makeconnections(label, 'L_47', 'L_22');
C = C | makeconnections(label, 'L_47', 'L_39');
C = C | makeconnections(label, 'L_47', 'L_17');
C = C | makeconnections(label, 'L_47', 'L_18');
C = C | makeconnections(label, 'L_47', 'L_19');

C = C | makeconnections(label, 'R_45', 'R_22');
C = C | makeconnections(label, 'R_45', 'R_39');
C = C | makeconnections(label, 'R_45', 'R_17');
C = C | makeconnections(label, 'R_45', 'R_18');
C = C | makeconnections(label, 'R_45', 'R_19');
C = C | makeconnections(label, 'R_47', 'R_22');
C = C | makeconnections(label, 'R_47', 'R_39');
C = C | makeconnections(label, 'R_47', 'R_17');
C = C | makeconnections(label, 'R_47', 'R_18');
C = C | makeconnections(label, 'R_47', 'R_19');

% superior longitudinal fasciculus: 44 to 40 and dorsal 21/22
C = C | makeconnections(label,  'L_44', 'L_40');
C = C | makeconnections(label2, 'L_44', 'L_temp_sup_post_22');
C = C | makeconnections(label2, 'L_44', 'L_temp_sup_mid_22');
C = C | makeconnections(label2, 'L_44', 'L_temp_mid_mid_22');
C = C | makeconnections(label2, 'L_44', 'L_temp_mid_mid_21');

C = C | makeconnections(label,  'R_44', 'R_40');
C = C | makeconnections(label2, 'R_44', 'R_temp_sup_post_22');
C = C | makeconnections(label2, 'R_44', 'R_temp_sup_mid_22');
C = C | makeconnections(label2, 'R_44', 'R_temp_mid_mid_22');
C = C | makeconnections(label2, 'R_44', 'R_temp_mid_mid_21');

% uncuate fasciculus: 45 to anterior STG and MTG
C = C | makeconnections(label2, 'L_45', 'L_temp_sup_ant');
C = C | makeconnections(label2, 'L_45', 'L_temp_mid_ant');

C = C | makeconnections(label2, 'R_45', 'R_temp_sup_ant');
C = C | makeconnections(label2, 'R_45', 'R_temp_mid_ant');

% Glasser and Rilling: dorsal STG to 44/45
C = C | makeconnections(label2, 'L_44', 'L_temp_sup_post');
C = C | makeconnections(label2, 'L_45', 'L_temp_sup_post');

C = C | makeconnections(label2, 'R_44', 'R_temp_sup_post');
C = C | makeconnections(label2, 'R_45', 'R_temp_sup_post');

% Glasser and Rilling: MTG (21/37) to 44/45/6/9
% subparcels of 9 adjacent to 46 is 2,3,4
C = C | makeconnections(label2, 'L_44', 'L_temp_mid_post');
C = C | makeconnections(label2, 'L_44', 'L_temp_mid_mid');
C = C | makeconnections(label2, 'L_45', 'L_temp_mid_post');
C = C | makeconnections(label2, 'L_45', 'L_temp_mid_mid');
C = C | makeconnections(label2, 'L_6_', 'L_temp_mid_post');
C = C | makeconnections(label2, 'L_6_', 'L_temp_mid_mid');
C = C | makeconnections(label2, 'L_9_', 'L_temp_mid_post');
C = C | makeconnections(label2, 'L_9_', 'L_temp_mid_mid');

C = C | makeconnections(label2, 'R_44', 'R_temp_mid_post');
C = C | makeconnections(label2, 'R_44', 'R_temp_mid_mid');
C = C | makeconnections(label2, 'R_45', 'R_temp_mid_post');
C = C | makeconnections(label2, 'R_45', 'R_temp_mid_mid');
C = C | makeconnections(label2, 'R_6_', 'R_temp_mid_post');
C = C | makeconnections(label2, 'R_6_', 'R_temp_mid_mid');
C = C | makeconnections(label2, 'R_9_', 'R_temp_mid_post');
C = C | makeconnections(label2, 'R_9_', 'R_temp_mid_mid');


% also link 44/45/47 between one another
C = C | makeconnections(label2, 'L_44', 'L_45');
C = C | makeconnections(label2, 'L_44', 'L_46');
C = C | makeconnections(label2, 'L_44', 'L_47');
C = C | makeconnections(label2, 'L_45', 'L_44');
C = C | makeconnections(label2, 'L_45', 'L_46');
C = C | makeconnections(label2, 'L_45', 'L_47');
C = C | makeconnections(label2, 'L_46', 'L_44');
C = C | makeconnections(label2, 'L_46', 'L_45');
C = C | makeconnections(label2, 'L_46', 'L_47');
C = C | makeconnections(label2, 'L_47', 'L_44');
C = C | makeconnections(label2, 'L_47', 'L_45');
C = C | makeconnections(label2, 'L_47', 'L_46');

C = C | makeconnections(label2, 'R_44', 'R_45');
C = C | makeconnections(label2, 'R_44', 'R_46');
C = C | makeconnections(label2, 'R_44', 'R_47');
C = C | makeconnections(label2, 'R_45', 'R_44');
C = C | makeconnections(label2, 'R_45', 'R_46');
C = C | makeconnections(label2, 'R_45', 'R_47');
C = C | makeconnections(label2, 'R_46', 'R_44');
C = C | makeconnections(label2, 'R_46', 'R_45');
C = C | makeconnections(label2, 'R_46', 'R_47');
C = C | makeconnections(label2, 'R_47', 'R_44');
C = C | makeconnections(label2, 'R_47', 'R_45');
C = C | makeconnections(label2, 'R_47', 'R_46');

% % also link 21/22/37 between one another
% C = C | makeconnections(label, 'L_21', 'L_22');
% C = C | makeconnections(label, 'L_21', 'L_37');
% C = C | makeconnections(label, 'L_22', 'L_21');
% C = C | makeconnections(label, 'L_22', 'L_37');
% C = C | makeconnections(label, 'L_37', 'L_21');
% C = C | makeconnections(label, 'L_37', 'L_22');
% 
% C = C | makeconnections(label, 'R_21', 'R_22');
% C = C | makeconnections(label, 'R_21', 'R_37');
% C = C | makeconnections(label, 'R_22', 'R_21');
% C = C | makeconnections(label, 'R_22', 'R_37');
% C = C | makeconnections(label, 'R_37', 'R_21');
% C = C | makeconnections(label, 'R_37', 'R_22');

% also connect the temporal parcels
C = C | makeconnections(label2, 'L_temp_sup_ant', 'L_temp_sup_mid');
C = C | makeconnections(label2, 'L_temp_sup_mid', 'L_temp_sup_post');
C = C | makeconnections(label2, 'L_temp_mid_ant', 'L_temp_mid_mid');
C = C | makeconnections(label2, 'L_temp_mid_mid', 'L_temp_mid_post');
C = C | makeconnections(label2, 'L_temp_sup_ant', 'L_temp_mid_ant');
C = C | makeconnections(label2, 'L_temp_sup_mid', 'L_temp_mid_mid');
C = C | makeconnections(label2, 'L_temp_sup_post', 'L_temp_mid_post');
C = C | makeconnections(label2, 'L_temp_mid_post', 'L_temp_inf_post');

C = C | makeconnections(label2, 'R_temp_sup_ant', 'R_temp_sup_mid');
C = C | makeconnections(label2, 'R_temp_sup_mid', 'R_temp_sup_post');
C = C | makeconnections(label2, 'R_temp_mid_ant', 'R_temp_mid_mid');
C = C | makeconnections(label2, 'R_temp_mid_mid', 'R_temp_mid_post');
C = C | makeconnections(label2, 'R_temp_sup_ant', 'R_temp_mid_ant');
C = C | makeconnections(label2, 'R_temp_sup_mid', 'R_temp_mid_mid');
C = C | makeconnections(label2, 'R_temp_sup_post', 'R_temp_mid_post');
C = C | makeconnections(label2, 'R_temp_mid_post', 'R_temp_inf_post');

% also connect 39 and 40
C = C | makeconnections(label, 'L_39', 'L_40');
C = C | makeconnections(label, 'R_39', 'R_40');

% also connect the visual regions
C = C | makeconnections(label, 'L_17', 'L_18');
C = C | makeconnections(label, 'L_18', 'L_19');
C = C | makeconnections(label, 'L_17', 'L_19');

C = C | makeconnections(label, 'R_17', 'R_18');
C = C | makeconnections(label, 'R_18', 'R_19');
C = C | makeconnections(label, 'R_17', 'R_19');

% also connect the homologous connections
C = C | makeconnections(label, 'R_44', 'L_44');
C = C | makeconnections(label, 'R_45', 'L_45');
C = C | makeconnections(label, 'R_46', 'L_46');
C = C | makeconnections(label, 'R_47', 'L_47');
C = C | makeconnections(label2, 'R_temp_sup_ant', 'L_temp_sup_ant');
C = C | makeconnections(label2, 'R_temp_sup_mid', 'L_temp_sup_mid');
C = C | makeconnections(label2, 'R_temp_sup_post', 'L_temp_sup_post');
C = C | makeconnections(label2, 'R_temp_mid_ant', 'L_temp_mid_ant');
C = C | makeconnections(label2, 'R_temp_mid_mid', 'L_temp_mid_mid');
C = C | makeconnections(label2, 'R_temp_mid_post', 'L_temp_mid_post');
C = C | makeconnections(label2, 'R_temp_inf_post', 'L_temp_inf_post');
C = C | makeconnections(label, 'R_17', 'L_17');
C = C | makeconnections(label, 'R_18', 'L_18');
C = C | makeconnections(label, 'R_19', 'L_19');
C = C | makeconnections(label, 'R_39', 'L_39');
C = C | makeconnections(label, 'R_40', 'L_40');
C = C | makeconnections(label2, 'R_6_', 'L_6_');
C = C | makeconnections(label2, 'R_9_', 'L_9_');

% exclude the neighbouring parcels
c = full(parcellation2connectivity(atlas));
C(c>0) = false;

label = [label, label2];

% build a projection matrix (averaging) that is combining the subparcels,
% based on label2
match  = nan+zeros(size(label,1),1);
label3 = cell(size(label,1),1);
list   = cell(0,1);
cnt = 0;
while any(~isfinite(match))
  ix  = find(~isfinite(match),1,'first');
  tmp = label2{ix};
  if ~isempty(strfind(tmp, 'B05'))
    tmp = tmp(1:4);
    if strcmp(tmp(4),'_')
      %tmp = tmp(1:3);
    end
  elseif ~isempty(strfind(tmp, 'temp'))
    tmp = tmp(1:end-6);
  else
    %tmp = tmp;
  end
  cnt = cnt+1;
  match(strncmp(label2, tmp, numel(tmp)))  = cnt;
  label3(strncmp(label2, tmp, numel(tmp))) = {tmp};
  list{cnt,1} = tmp;
end

% ensure that the label entries with BA < 10 are of format '0x'
for k = 1:numel(label3)
  tok = tokenize(label3{k},'_');
  if numel(tok{2})==1,
    label3{k} = [label3{k}(1:2),'0',tok{2}];
  end
end

P = zeros(max(match),size(label,1));
for k = 1:size(P,1)
  P(k,match==k) = 1./sum(match==k);
end
label = [label label3];

for k = 1:numel(list)
  if strcmp(list{k}(4),'_')
    list{k} = [list{k}(1:2),'0',list{k}(3)];
  elseif strcmp(list{k}(4),'x')
    list{k} = [list{k}(1:2),'0',list{k}(3:end)];
  end
end
[srt,ix] = sort(list);
list = list(ix);
P    = P(ix,:);

% the following list is the ordered list that is to be completed with the
% temporal and occipital parcels, for the circular layout

cfg = [];
cfg.channel = {
    'R_09'
    'R_46'
    'R_44'
    'R_45'
    'R_47'
    'R_06'
    'R_39'
    'R_40'
    'R_temp_sup_ant'
    'R_temp_sup_mid'
    'R_temp_sup_post'
    'R_temp_mid_ant'
    'R_temp_mid_mid'
    'R_temp_mid_post'
    'R_temp_inf_post'
    'R_19'
    'R_18'
    'R_17'
    'L_17'
    'L_18'
    'L_19'
    'L_temp_inf_post'
    'L_temp_mid_post'
    'L_temp_mid_mid'
    'L_temp_mid_ant'
    'L_temp_sup_post'
    'L_temp_sup_mid'
    'L_temp_sup_ant'
    'L_40'
    'L_39'
    'L_06'
    'L_47'
    'L_45'
    'L_44'
    'L_46'
    'L_09'
    };

cfg.rho = [10:8:50 65 73 88:8:136 151:8:167 193:8:209 224:8:272 287 295 310:8:350];
cfg.layout = 'circular';
lay = ft_prepare_layout(cfg);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction
function C = makeconnections(label, node1, node2)

C = false(numel(label));

sel1 = ~cellfun('isempty',strfind(label, node1));
sel2 = ~cellfun('isempty',strfind(label, node2));

C(sel1, sel2) = true;
C(sel2, sel1) = true;

