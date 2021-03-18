# At this stage there is an issue with the template mask. Due to having used a suboptimal mask for some of the subjects, the overall
# min operation of mrmath leads to an ugly mask. The suboptimal masks are probably caused by dd_basicproc, which has been run 
# automatically (not by me), and its results have probably never been really inspected in detail. In order to be able to proceed
# I decided to manually fix these suboptimal masks (I will make them symmetric by mirroring the mask in the sagittal plane, and then
# taking a boolean OR). This is done in MATLAB. Next I will fix by hand the steps that have lead to the wmfod_norm.mif, under the 
# assumption that the missing data points did not affect the original wmfod estimation, and thus did not influence the population
# template noticeably. I will save the older results, though. The affected subjects are: A2058,A2061,A2113,V1005
