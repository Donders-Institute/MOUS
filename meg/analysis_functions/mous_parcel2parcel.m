function [dataout] = mous_parcel2parcel(datain, parcelin, parcelout, varargin)

parameter      = ft_getopt(varargin, 'parameter', 'grangerspctrm');
parcelparamin  = ft_getopt(varargin, 'parcelin',  'parcellation');
parcelparamout = ft_getopt(varargin, 'parcelout', 'parcellation2');

% create the mapping matrix: mapout*I*mapin (assume Identity in
% between: FIXME) mapin = 8196xNparcelin, mapout = Nparceloutx8196

indx2 = parcelin.(parcelparamin);
indx1 = repmat((1:8196)', [1 size(indx2,2)]);
val   = ones(size(indx2));
mapin = sparse(indx1(:), indx2(:), val(:));
tmp   = sum(mapin,2);
tmp(tmp~=0) = 1./tmp(tmp~=0);
mapin = spdiags(tmp,0,8196,8196)*mapin;

indx2 = parcelout.(parcelparamout);
indx1 = repmat((1:8196)', [1 size(indx2,2)]);
val   = ones(size(indx2));
mapout = sparse(indx2(:), indx1(:), val(:));

mapmat = full(mapout*mapin);
mapmat = mapmat./repmat(sum(mapmat,2),[1 size(mapmat,2)]);

[sel1, sel2] = match_str(datain.label, parcelin.([parcelparamin,'label']));

datain.(parameter)(~isfinite(datain.(parameter))) = 0;
dataout             = rmfield(datain, {parameter 'label'});
dataout.(parameter) = zeros(size(mapmat,1),size(mapmat,1),numel(datain.freq));
for k = 1:numel(dataout.freq)
  dataout.(parameter)(:,:,k) = mapmat(:,sel2)*datain.(parameter)(sel1,sel1,k)*mapmat(:,sel2)';
end
dataout.label = parcelout.([parcelparamout,'label']);

