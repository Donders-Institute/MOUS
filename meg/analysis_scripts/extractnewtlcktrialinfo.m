% In response to a reviewer comment, we computed bigram letter frequency
% and lemma frequency and aded them to mous_stimuli to use as regressors.
% This code extracts the log transform of these variables (logbigramfreq
% and loglemmafreq), and adds this updated trialinfo to tlck1 and tlck2 of
% the hyperaligned data. 
% Important to Note: It overwrites the loaded file

if ~exist('scenario', 'var');      error('please supply scenario');     end
if ~exist('parcel_indx', 'var');   error('please supply parcel_indx');  end
if ~exist('loaddir', 'var');       error('please supply loaddir');      end


filename = fullfile(loaddir, sprintf('mscca_sce%d-%d_parcel%03d',scenario(1),scenario(2),parcel_indx));
load(filename);

load mous_stimuli.mat

newtlck = mous_multisetcca_extractwords(comp, stimuli);

id1 = find(ismember(newtlck.trialinfo.id, tlck1.trialinfo.id));
id2 = find(ismember(newtlck.trialinfo.id, tlck2.trialinfo.id));

tmptrialinfo1 = newtlck.trialinfo(id1,:);
tmptrialinfo2 = newtlck.trialinfo(id2,:);

if ~isequal(tlck1.trialinfo.logperplexity, tmptrialinfo1.logperplexity); error('logperplexity does not match in tlck1'); end
if ~isequal(tlck1.trialinfo.nchar,         tmptrialinfo1.nchar);         error('nchar does not match'); end
if ~isequal(tlck1.trialinfo.loglexfreq,    tmptrialinfo1.loglexfreq);    error('loglexfreq does not match in tlck1'); end
if ~isequal(tlck1.trialinfo.entropy,       tmptrialinfo1.entropy);       error('entropy does not match in tlck1'); end
if ~isequal(tlck1.trialinfo.index,         tmptrialinfo1.index);         error('index does not match in tlck1'); end

if ~isequal(tlck2.trialinfo.logperplexity, tmptrialinfo2.logperplexity); error('logperplexity does not match in tlck2'); end
if ~isequal(tlck2.trialinfo.nchar,         tmptrialinfo2.nchar);         error('nchar does not match'); end
if ~isequal(tlck2.trialinfo.loglexfreq,    tmptrialinfo2.loglexfreq);    error('loglexfreq does not match in tlck2'); end
if ~isequal(tlck2.trialinfo.entropy,       tmptrialinfo2.entropy);       error('entropy does not match in tlck2'); end
if ~isequal(tlck2.trialinfo.index,         tmptrialinfo2.index);         error('index does not match in tlck2'); end

tlck1.trialinfo = tmptrialinfo1;
tlck2.trialinfo = tmptrialinfo2;

%saves over the old one
save(filename, 'rho', 'W', 'A', 'comp', 'tlck1', 'tlck2', 'trc1', 'trc2');

