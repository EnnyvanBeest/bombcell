%% load data 

ephysPath = AP_cortexlab_filenameJF(animal,day,experiment,'ephys',site);
[spikeTimes, spikeTemplates, ...
    templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, usedChannels] = bc_loadEphysData(ephysPath);
ephysap_path = AP_cortexlab_filenameJF(animal,day,experiment,'ephys_ap',site);
ephysDirPath = AP_cortexlab_filenameJF(animal,day,experiment,'ephys_dir',site);
savePath = fullfile(ephysDirPath, 'qMetrics'); 

%% quality metric parameters and thresholds 
rerun = 0;
param = struct;
param.plotThis = 0;
param.plotGlobal =1;
% refractory period parameters
param.tauR = 0.0020; %refractory period time (s)
param.tauC = 0.0001; %censored period time (s)
param.maxRPVviolations = 20;
% percentage spikes missing parameters 
param.maxPercSpikesMissing = 30;
param.computeTimeChunks = 0;
param.deltaTimeChunk = NaN; 
% number of spikes
param.minNumSpikes = 300;
% waveform parameters
param.maxNPeaks = 2;
param.maxNTroughs = 1;
param.axonal = 0; 
param.minWvDuration = 100; %ms
param.maxWvDuration = 800; %ms
param.minSpatialDecaySlope = -60;
% amplitude parameters
param.rawFolder = [ephysap_path, '/..'];
param.nRawSpikesToExtract = 100; 
param.minAmplitude = 20; 
% recording parametrs
param.ephys_sample_rate = 30000;
param.nChannels = 385;
% distance metric parameters
param.computeDistanceMetrics = 1;
param.nChannelsIsoDist = 4;
param.isoDmin = NaN;
param.lratioMin = NaN;
param.ssMin = NaN; 
% ACG parameters
param.ACGbinSize = 0.001;
param.ACGduration = 1;
% ISI parameters
param.longISI = 2;
% cell classification parameters
param.propISI = 0.1;
param.templateDuration = 400;
param.pss = 40;

%% compute quality metrics 
qMetricsExist = dir(fullfile(savePath, 'qMetric*.mat'));

if isempty(qMetricsExist) || rerun
    [qMetric, unitType] = bc_runAllQualityMetrics(param, spikeTimes, spikeTemplates, ...
        templateWaveforms, templateAmplitudes,pcFeatures,pcFeatureIdx,usedChannels, savePath);
else
    load(fullfile(savePath, 'qMetric.mat'))
    load(fullfile(savePath, 'param.mat'))
    unitType = nan(length(qMetric.percSpikesMissing),1);
    unitType(qMetric.nPeaks > param.maxNPeaks | qMetric.nTroughs > param.maxNTroughs | qMetric.somatic ~= param.somatic ...
        | qMetric.spatialDecaySlope <=  param.minSpatialDecaySlope| qMetric.cellLikeDuration == 0 ) = 0; %NOISE or NON-SOMATIC
    unitType(qMetric.percSpikesMissing <= param.maxPercSpikesMissing & qMetric.nSpikes > param.minNumSpikes & ...
        qMetric.nPeaks <= param.maxNPeaks & qMetric.nTroughs <= param.maxNTroughs & qMetric.Fp <= param.maxRPVviolations & ...
        qMetric.axonal == param.axonal & qMetric.rawAmplitude > param.minAmplitude) = 1;%SINGLE SEXY UNIT
    unitType(isnan(unitType)) = 2;% MULTI UNIT 
end
%% view units + quality metrics in GUI 
%get memmap
bc_getRawMemMap;

% put ephys data into structure 
ephysData = struct;
ephysData.spike_times = spikeTimes;
ephysData.spike_times_timeline = spikeTimes ./ 30000;
ephysData.spike_templates = spikeTemplates;
ephysData.templates = templateWaveforms;
ephysData.template_amplitudes = templateAmplitudes;
ephysData.channel_positions = readNPY([ephysPath filesep 'channel_positions.npy']);
ephysData.ephys_sample_rate = 30000;
ephysData.waveform_t = 1e3*((0:size(templateWaveforms, 2) - 1) / 30000);
ephysParams = struct;
plotRaw = 1;
probeLocation=[];

keep ephysData qMetric param probeLocation unitType plotRaw
bc_unitQualityGUI(memMapData,ephysData,qMetric, param, probeLocation, unitType, plotRaw);

