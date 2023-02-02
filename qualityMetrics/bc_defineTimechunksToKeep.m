function [theseSpikeTimes, theseAmplis, theseSpikeTemplates, useThisTimeStart, useThisTimeStop, useTauR] = bc_defineTimechunksToKeep(percSpikesMissing, ...
    fractionRPVs, maxPercSpikesMissing, maxfractionRPVs, theseAmplis, theseSpikeTimes, theseSpikeTemplates, timeChunks)
% JF
% define time chunks where the current unit has low refractory period violations and
% estimated percent spikes missing 
% ------
% Inputs
% ------
% percSpikesMissing: estimated percentage of spikes missing for the current
%   unit, for each time chunk
% fractionRPVs: estimated percentage of spikes missing for the current
%   unit, for each time chunk
% maxPercSpikesMissing
% maxfractionRPVs
% theseAmplis: current unit spike-to-template scaling factors 
% theseSpikeTimes: current unit spike times 
% theseSpikeTemplates:  nSpikes × 1 uint32 vector giving the identity of each
%   spike's matched template
% timeChunks: time chunkbins  of the recording in which the percSpikesMissing
%   and fractionRPVs are computed 
% ------
% Outputs
% ------
% theseSpikeTimes: current unit spike times in time bins where estimated 
%   refractory period violations and estimated percent spikes missing are low
% theseAmplis: current unit spike-to-template scaling factors in time bins where estimated 
%   refractory period violations and estimated percent spikes missing are low
% theseSpikeTemplates
% useThisTimeStart: start bin value where current unit has low refractory period violations and
%   estimated percent spikes missing 
% useThisTimeStop: start bin value where current unit has low refractory period violations and
%   estimated percent spikes missing 
% useTauR: estimated refractory period for the current unit 

% use biggest tauR value that gives smallest contamination 
sumRPV = sum(fractionRPVs,1);
useTauR = find(sumRPV == min(sumRPV),1, 'last');

if any(percSpikesMissing < maxPercSpikesMissing) && any(fractionRPVs(:,useTauR) < maxfractionRPVs) % if there are some good time chunks, keep those

    useTheseTimes_temp = find(percSpikesMissing < maxPercSpikesMissing & fractionRPVs(:,useTauR) < maxfractionRPVs);
    if numel(useTheseTimes_temp) > 0
        continousTimes = diff(useTheseTimes_temp);
        if any(continousTimes == 1)
            f = find(diff([false; continousTimes == 1; false]) ~= 0);
            [continousTimesUseLength, ix] = max(f(2:2:end)-f(1:2:end-1));
            continousTimesUseStart = useTheseTimes_temp(continousTimes(f(2*ix-1)));
            useTheseTimes = timeChunks(continousTimesUseStart:continousTimesUseStart+(continousTimesUseLength));
        else
            useTheseTimes = timeChunks(useTheseTimes_temp(1):useTheseTimes_temp(1)+1);
        end
    else
        useTheseTimes = timeChunks;
    end
    theseSpikeTemplates(theseSpikeTimes > useTheseTimes(end) | ...
        theseSpikeTimes < useTheseTimes(1)) = 0;
    theseAmplis = theseAmplis(theseSpikeTimes <= useTheseTimes(end) & ...
        theseSpikeTimes >= useTheseTimes(1));
    theseSpikeTimes = theseSpikeTimes(theseSpikeTimes <= useTheseTimes(end) & ...
        theseSpikeTimes >= useTheseTimes(1));
    
    %QQ change non continous

    useThisTimeStart = useTheseTimes(1);
    useThisTimeStop = useTheseTimes(end);
else %otherwise, keep all chunks to compute quality metrics on, uni will defined as below percSpikesMissing and Fp criteria thresholds later
    useThisTimeStart = 0;
    useThisTimeStop = timeChunks(end);
end

end