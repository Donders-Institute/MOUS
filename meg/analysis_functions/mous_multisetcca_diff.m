function [diff, tim] = mous_multisetcca_diff(rootdir,scenario,varargin)

modality            = ft_getopt(varargin, 'modality', 'supramodal');
trcname             = ft_getopt(varargin, 'trcname', 'trc');       %filename of the trc on original order
shufflefname        = ft_getopt(varargin, 'shufflefname', trcname);%filename of the trc on shuffled order (can be shuf2 before mscca or after mscca)
shuffle             = ft_getopt(varargin, 'shuffle', 'trcshuf');   %variable name of the shuffled trc (post mscca can be trcshuf,trcshuf2,trcshuf3)
load atlas_conte69_8196reg_LR_brodmann_subparc.mat

switch scenario
    case 1
        iv = 1:17;
        ia = 18:33;
    case 2
        iv = 1:17;
        ia = 18:34;
    case 3
        iv = 1:17;
        ia = 18:33;
    case 4
        iv = 1:16;
        ia = 17:33;
    case 5
        iv = 1:17;
        ia = 18:34;
    case 6
end

switch modality
    case 'visual'
        moda = 1;
    case 'auditory'
        moda = 2;
    case 'supramodal'
        moda = 3;
end


conditions = {'_sent','_seq'};
for cond = 1:length(conditions)
    
    trcfiles = strcat(rootdir,sprintf('/mscca_sce%d*',scenario),trcname,conditions{cond},'_longwords.mat');
    trcd = dir(trcfiles);
    shufflefiles = strcat(rootdir,sprintf('/mscca_sce%d*',scenario),shufflefname,conditions{cond},'_longwords.mat');
    shuffled = dir(shufflefiles);
    
    pindx = 1:length(atlas.parcellationlabel);
    pindx([1 2 194 195]) = []; %ignore medial wall parcels
    for k = 1:numel(trcd)
        k
        
        load(strcat(rootdir,'/',trcd(k).name),'trc');
        shuf = load(strcat(rootdir,'/',shuffled(k).name),shuffle);
        shuf = shuf.(shuffle);
        n = 1:size(shuf.rho,3);
        
        indx = pindx(str2double(trcd(k).name(18:20)));
        T{cond}(indx,:) = trc.rho(:,moda);
        Tshuf{cond}(indx,:,n) = squeeze(shuf.rho(:,moda,:));
        
        if k==1,
            T{cond}(386,end)=0;
            Tshuf{cond}(386,end,end)=0;
        end
        tim{cond} = trc.time;
        
        clear trc shuf
    end
end
    
diff = (T{1}-Tshuf{1})-(T{2}-Tshuf{2});
diff = mean(Tdiff,3);

