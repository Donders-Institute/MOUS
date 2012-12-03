function mous_write_provenance(filename)

% MOUS_WRITE_PROVENANCE writes an XML file with provenance information to
% complement a MATLAB or an ascii file. Thit function is called automatically
% immediately following the writing of a MATLAB or ascii file.
%
% Use as
%   mous_write_provenance(filename)
%
% The filename should refer to the *.mat or *.txt file. The provenance
% information will be saved in a file with corresponding name but with the
% extension *.prov.xml
%
% See also MOUS_WRITE_MATLAB

% the expected input filename extension is *.txt or *.mat
[p, f, x] = fileparts(filename);

if ~exist(filename, 'file')
  error('file "%s" does not exist', filename);
end

status = -1;

if status~=0
  [status, str] = system(sprintf('md5sum %s', filename));
  % this looks like
  % ee338cf30b7e10f249b61dade77339d1 filename
  hash = strtok(str);
end

if status~=0
  [status, str] = system(sprintf('md5 %s', filename));
  % this looks like
  % MD5 (filename) = ee338cf30b7e10f249b61dade77339d1
  [tok, rem] = strtok(str, '=');
  hash = strtrim(rem(2:end));
end

if status~=0
  warning('failed to compute MD5 hash for file "%s', filename);
  hash = 'unknown';
end

m = ver('MATLAB');
m = m.Release(2:end-1);

filename = fullfile(p, [f '.prov']);

prov.filename       = [f x];
prov.md5hash        = hash;
prov.username       = getusername;
prov.hostname       = gethostname;
prov.time           = datestr(now);
prov.matlabrelease  = m;
prov.matlabstack    = printstack(dbstack);
prov.Attributes.xmlns_colon_xsi = 'http://www.w3.org/2001XMLSchema-instance';
prov.Attributes.xsi_colon_noNamespaceSchemaLocation = 'mous.xsd';

% huisdier.soort = 'kanarie';
% huisdier.naam  = 'geeltje';
% huisdier.geboortedatum = '2012-10-11';
% xml = struct2xml(struct('huisdier', huisdier));

struct2xml(struct('mous', prov), filename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = printstack(s)
str = sprintf('\n');
for i=1:length(s)
  str = [str sprintf('In %s at %d\n', s(i).name, s(i).line)];
end
