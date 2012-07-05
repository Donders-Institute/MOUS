function [ConditionDurations,ConditionOnsets] = ...
  mous_onsetsANDdurations(ConditionIndex, EventDurations, EventIndex, time);
%--------------------------------------------------------------------------
% onsetsANDdurations.m 
%--------------------------------------------------------------------------
% Author(s): Julia Uddén
% Updated:      
% Date:      07-04-2012  
% © Julia Uddén
%--------------------------------------------------------------------------

ConditionOnsets=time(ConditionIndex);    
% Find those of the EventDurations that belong to this condition

%Old version:
%ConditionDurations=diff(ConditionOnsets);
%ConditionDurationsInIndex=diff(ConditionIndex);

% FIND LAST
% Create 0-vector of length(EventIndex), with 1 for the last ConditionIndex
zeroVector=[ConditionIndex(end)==EventIndex];
% Find which where in this zero-vector, there is a one and add one
nextIndex=find([ConditionIndex(end)==EventIndex])+1;
% EventIndex(nextIndex) is now the Index (referring to the long code-vector)
% of the next event. 

    %Store the last event, if there is another condition coming after ...
    try
    lastConditionDuration=EventOnsets(nextIndex)-ConditionOnsets(end);
    ConditionDurations=[ConditionDurations;lastConditionDuration];
%     nextEventIndex=EventIndex(nextIndex);
%     ConditionDurationsInIndex=[ConditionDurationsInIndex; ...
%         nextEventIndex-ConditionIndex(end)];
    
    % ... or if this is the last condition in the session
    catch
    ConditionDurations=[ConditionDurations;EventDurations(end)];  
%     ConditionDurationsInIndex=[ConditionDurationsInIndex; ...
%         length(time)-ConditionIndex(end)];
    end
    
end