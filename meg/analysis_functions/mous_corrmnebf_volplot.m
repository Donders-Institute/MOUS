function mous_corrmnebf_volplot(subjectnames)

% This function visualises the correlation matrix of MNE vertices by Beamforming voxels
% The matrix can be of a single subject or a group ('groupresults')
% cfg defines the filename which requires specification of which
% - 'savebf': toi for beamforming solution
% - 'savemne': toi for MNE solution
% - cdtn (condition): sent/seq/svs (sentence versus sequence)
% - suff: frequency of interest as a string variable


    % number of degrees for a certain node
    % which area has the most correlation, averaged across all seeds

docalc = true;
doplot = false;

if docalc
 
    param.range       = 'medium';
    param.foi         = 16;        
    param.toie        = [0.35 0.45];  % toi for ERFs
    param.selfq       = [-0.12 -0.08];
    param.toi         = [];           % toi for TFR % not neded because selfq defines  toi
    param.suff        = num2str(param.foi);   
    param.savebf      = regexprep(num2str(mean(param.selfq)),'[.]','');
    param.savemne     = regexprep([num2str(param.toie(1)) num2str(param.toie(2))],'[.]',''); 
    param.cdtn        = 'sen'; % 'seq'
    
    cfginterp = [];
    cfginterp.cor = ['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];
    cfginterp.erf = 'meg_anatomy_sourcemodel2D';
    cfginterp.tfr = ['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn];
    
   
    % get sourcemodel 
    fname = '/home/language/nielam/MOUS/meg/templates/sourcemodel/standard_sourcemodel3d8mm';
    load(fname);

    % adjust sourcemodel size from [1 x 5798] to [1 x 5782], & limit the inside sources
    mous_db_getdata('V1036',['meg_corrmnebf_bfsourcesingletrial8mm_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn]);
    sourcemodel.inside    = source.inside;
    sourcemodel.outside   = setdiff(1:size(sourcemodel.pos,1), source.inside);
    if isfield(sourcemodel,'cfg')
        sourcemodel = rmfield(sourcemodel,'cfg');
    end
    rmf = {'xgrid','ygrid','zgrid','unit'}; sourcemodel = rmfield(sourcemodel,rmf);

    nsubj = numel(subjectnames);
    for scnt = 1:nsubj
        
        mous_db_getdata(subjectnames{scnt},['meg_corrmnebf_corVoxvert8mm_sdregwordord_jack_fisher_bf',param.savebf,'mne',param.savemne,'_',param.suff,'Hz_',param.cdtn]);
        [source3dsen] = mous_corrmnebf_interpolate(subjectnames{scnt},cfginterp);  % output is verts X voxels
        if isfield(source3dsen, 'cfg')
            source3dsen = rmfield(source3dsen,'cfg');
        end
      
        for mcnt = 1:8 % mcnt = manipulation counter: there are 8 non-linear steps to apply to data.
                               
            tmp = source3dsen.corrmat;
            dum = zeros(sourcemodel.dim); % volplot requires three dimensions 

            if mcnt == 1
                tmp(tmp>0)=nan;  
                dum(sourcemodel.inside) = nanmean(tmp,1);
            elseif mcnt == 2
                tmp(tmp>0)=nan;  
                dum(sourcemodel.inside) = nanmean(tmp,2);
            elseif mcnt == 3
                tmp(tmp<0)=nan;  
                dum(sourcemodel.inside) = nanmean(tmp,1);
            elseif mcnt == 4
                tmp(tmp<0)=nan;  
                dum(sourcemodel.inside) = nanmean(tmp,2);
            elseif mcnt == 5
                dum(sourcemodel.inside) = nanmean(sign(tmp),1);
            elseif mcnt == 6
                dum(sourcemodel.inside) = nanmean(sign(tmp),2);
            elseif mcnt == 7
                dum(sourcemodel.inside) = nanmean(abs(tmp),1);
            elseif mcnt == 8
                dum(sourcemodel.inside) = nanmean(abs(tmp),2);
            end
            
            if scnt == 1
               sourceconfig(mcnt).corrmat = dum;
            else
               sourceconfig(mcnt).corrmat = sourceconfig(mcnt).corrmat + dum;
            end
            
            if scnt == nsubj
                avg(mcnt).corrmat = sourceconfig(mcnt).corrmat;
                avg(mcnt).corrmat = avg(mcnt).corrmat/nsubj; 
            end 
         end    
    end 
    mous_db_putdata('groupresults',['meg_corrmnebf_volplot_',num2str(mcnt),'manips_',num2str(nsubj),'subjs'],'avg','sourceconfig','subjectnames');
end 
    
if doplot
    plotname = cell(1,8);
    plotname{1} = 'neg val only: avgd ERFseed to TFR whole head';
    plotname{2} = 'neg val only: avgd TFRseed to ERF whole head';
    plotname{3} = 'pos val only: avgd ERFseed to TFR whole head';
    plotname{4} = 'pos val only: avgd TFRseed to ERF whole head';
    plotname{5} = 'sign(val): avgd ERFseed to TFR whole head';
    plotname{6} = 'sign(val): avgd TFRseed to ERF whole head';
    plotname{7} = 'abs(val): avgd ERFseed to TFR whole head';
    plotname{8} = 'abs(val): avgd TFRseed to ERF whole head';
    
    for mcnt = 1:8
        figure; volplot(avg(mcnt).corrmat,'montage'); colorbar; 
        set(gcf,'name',['groupresults',plotname{mcnt}]);
    end 
end 
