function design = makedesign(trialinfo)

load mous_stimuli

id      = trialinfo(:,end);
uid     = unique(id);
word_id = trialinfo(:,end-1);

%design = [];
design(2,id<501) = word_id(id<501)'-mean(word_id(id<501));
design(3,id>500) = word_id(id>500)'-mean(word_id(id>500));
for k = 1:numel(uid)
  this = stimuli(uid(k));
  indx1 = word_id(id==uid(k)); 
  indx2 = find(id==uid(k));
  
  indx2(indx1>numel(this.words)) = [];
  indx1(indx1>numel(this.words)) = [];
  thesewords = this.words(indx1);
  design(4,indx2) = log10([thesewords.lexfreq]);
  design(5,indx2) = [thesewords.leftbranch];
  design(6,indx2) = [thesewords.rightbranch];
  design(7,indx2) = double(ismember(this.wordtype(indx1),[1 3 4]))-0.5;
end
design(~isfinite(design))=0;
design(4:end,:) = design(4:end,:) - mean(design(4:end,:),2);

design(1,:) = 1./size(trialinfo,1);


