%% This script checks whether all shuffled versions of mscca have been computed and sends of missing jobs again

%%find which parcels have not been computed yet
xfile = dir('/project/3011020.09/jansch/mscca_group/scenario6/*shuf2.mat');
done = zeros(1,length(xfile));
for i = 1:length(xfile)
    xind = strfind(xfile(i).name,'parcel') + 6;
    done(i) = str2double(xfile(i).name(xind:xind+2));
end

all = 1:382;
missing = setdiff(all,done);

%%send off new jobs
for parcel_indx = missing
qsubfeval('mous_execute_pipeline','mous_multisetcca_pipeline','A2002',{'domscca_searchlight',1},{'scenario',6},{'parcel_indx',parcel_indx},{'shuftype','conservative'},{'nrand',1:100},{'skip_noshuffle',false},'memreq',16*1024^3,'timreq',30*60*60,'batchid',sprintf('sce6_sentshuf_parcel%03d',parcel_indx))
end

%% incomplete jobs
reps100 = [];
reps400 = [];
for i = 1:length(xfile)
    load(fullfile(xfile(i).folder,xfile(i).name),'trcshuf')
    randn = size(trcshuf.rho,3);
    if randn ~= 500
        if randn ==400
            reps400 = [reps400 i];
        elseif randn == 100
            reps100 = [reps100 i];
        end
    end
end