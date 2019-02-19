%% This script checks whether all shuffled versions of mscca have been computed and sends of missing jobs again

%%find which parcels have not been computed yet
xfile = dir(sprintf('/project/3011020.09/sopara/rcmix3_BeforeAfter/mscca_sce%d_*',scenario));
done = zeros(1,length(xfile));
for i = 1:length(xfile)
    xind = strfind(xfile(i).name,'parcel') + 6;
    done(i) = str2double(xfile(i).name(xind:xind+2));
end

all = 1:382;
missing = setdiff(all,done);

%%send off new jobs
for parcel_indx = missing
%qsubfeval('mous_execute_pipeline','mous_multisetcca_pipeline','A2002',{'domscca_searchlight',1},{'scenario',6},{'parcel_indx',parcel_indx},{'shuftype','conservative'},{'nrand',1:100},{'skip_noshuffle',false},'memreq',16*1024^3,'timreq',30*60*60,'batchid',sprintf('sce6_sentshuf_parcel%03d',parcel_indx))
qsubfeval('mous_execute_pipeline','mous_multisetcca_pipeline','A1001',{'scenario',scenario},{'parcel_indx',parcel_indx},{'dotrc_rcmix3',1},'memreq',(1024^3)*3,'timreq',60*100,'batchid',sprintf('rcmix3_sce%d_%03d',scenario,parcel_indx))
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