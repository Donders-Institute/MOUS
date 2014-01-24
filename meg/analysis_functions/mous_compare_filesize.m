function [subjectnames2] = mous_compare_filesize(subjectnames)
rootdir = '/home/language/jansch/public/mous/';

checksize = zeros(numel(subjectnames),1);
for k = 1:numel(subjectnames)
    lowfilename = dir([rootdir,subjectnames{k},'/bfica/',subjectnames{k},'_bfica_freq_low.mat']);
    medfilename = dir([rootdir,subjectnames{k},'/bfica/',subjectnames{k},'_bfica_freq_medium.mat']);
    
    if medfilename.bytes - lowfilename.bytes > 100    % choose value as 100, because 10 is too little a difference
        checksize(k) = true;
    end
end

lowidx = find(checksize == 1);
subjectnames2 = subjectnames(lowidx);