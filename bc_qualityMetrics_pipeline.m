%% load data 
ephysPath = pathToFolderYourEphysDataIsIn; % eg /home/netshare/zinu/JF067/2022-02-17/ephys/kilosort2/site1, whre this path contains 
                                           % kilosort output

% ephysPath = AP_cortexlab_filenameJF(animal,day,experiment,'ephys',site);
[spikeTimes, spikeTemplates, ...
    templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, channelPositions] = bc_loadEphysData(ephysPath);
ephysap_path = pathToEphysRawFile; %eg /home/netshare/zinu/JF067/2022-02-17/ephys/site1/2022_02_17-JF067_g0_t0.imec0.ap.bin 
ephysDirPath = pathToEphysRawFileFolder ;% eg /home/netshare/zinu/JF067/2022-02-17/ephys/site1
% ephysap_path = AP_cortexlab_filenameJF(animal,day,experiment,'ephys_ap',site);
% ephysDirPath = AP_cortexlab_filenameJF(animal,day,experiment,'ephys_dir',site);
savePath = fullfile(ephysDirPath, 'qMetrics'); 

%% quality metric parameters and thresholds 
bc_qualityParamValues; 

%% compute quality metrics 
rerun = 0;
qMetricsExist = dir(fullfile(savePath, 'qMetric*.mat'));

if isempty(qMetricsExist) || rerun
    [qMetric, unitType] = bc_runAllQualityMetrics(param, spikeTimes, spikeTemplates, ...
        templateWaveforms, templateAmplitudes,pcFeatures,pcFeatureIdx,channelPositions, savePath);
else
    load(fullfile(savePath, 'qMetric.mat'))
    load(fullfile(savePath, 'param.mat'))
    bc_getQualityUnitType;
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
ephysData.channel_positions = channelPositions;
ephysData.ephys_sample_rate = 30000;
ephysData.waveform_t = 1e3*((0:size(templateWaveforms, 2) - 1) / 30000);
ephysParams = struct;
plotRaw = 1;
probeLocation=[];

keep ephysData qMetric param probeLocation unitType plotRaw
bc_unitQualityGUI(memMapData,ephysData,qMetric, param, probeLocation, unitType, plotRaw);


