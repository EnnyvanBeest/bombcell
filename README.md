# <img style="float: left;" src="https://github.com/Julie-Fabre/bombcell/blob/master/images/bombcell_nobg_blue.png" width=20% height=20%> evaluate unit quality and ephys properties

Bombcell work with units recorded with Neuropixel probes (3A, 1.0 and 2.0, recorded with SpikeGLX or OpenEphys) and spike-sorted with kilosort. It classifies the unit into three categories: single units, multi-units and noise units, with an option to keep or remove non-somatic spikes. `param` is the structure that defines how to compute the quality metrics and which thresholds to use to classify units.

Used in [Peters et al., Nature, 2021](https://www.nature.com/articles/s41586-020-03166-8) to classify striatal units. See the script `bc_selectAndClassifyStriatum`(work in progress) to classify striatal cells in the same way. 


1. [Getting started](#Getting-started)
2. [Quality metrics guide ](#Quality-metrics-guide)
3. [Quality metrics GUI guide ](#Quality-metrics-GUI-guide)
4. [Ephys properties guide](#Ephys-properties-guide)
5. [Recommended pre-processing](#Recommended-pre-processing)
6. [Dependancies](#Dependancies)

### Getting started 

To install: in MATLAB, clone this repository and the [dependancies](#Dependancies), change your working directory to bombcell\ephysProperties\helpers in matlab and run `mex -O CCGHeart.c`. 

To start out, we suggest you compute quality metrics with default `param` values, and then adjust the thresholds for your particular neuronal region and needs by looking at (1) individual units, in the interactive [GUI](#Quality-metrics-GUI-guide ) (2) distribution histograms of the units' quality metrics (see General plots), (3) numbers of units removed by each quality metric. It may also be useful to plot the quantity you which to measure as a function of each quality metric (see [Fig. 2 Harris et al., Nat. Neuro, 2016](https://www.nature.com/articles/nn.4365/figures/2)).

See the script `bc_qualityMetrics_pipeline` for an example workflow. 

### Quality metrics guide

Run all quality metrics with the function `bc_runAllQualityMetrics`. Eg:

    [qMetric, unitTypes] = bc_runAllQualityMetrics(param, spikeTimes, spikeTemplates, ...
      templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, savePath);

Set `param.plotThis = 1;` to plot figures for each quality metric (plot examples displayed below), and set `param.plotGlobal = 1;` to plot summary of the noise units' waveforms compared to single multi-units, distribution histograms of the units' quality metrics and numbers of units removed by each quality metric. 

#### somatic

Somatic waveforms are defined as waveforms where the largest trough precedes the largest peak (Deligkaris, Bullmann & Frey, 2016).

#### number of peaks and troughs

Count the number of peaks and troughs to eliminate non-cell-like waveforms due to noise. Right, examples of a unit with a a cell-like waveform (left) and a unit with a noise-like waveform (right). 

<img style="float: right;" src="https://github.com/Julie-Fabre/bombcell/blob/master/images/numberTroughsPeaks.png" width=30% height=30%>

#### spatial decay 

Fit a line to the absolute maximum amplitudes of the unit's max channel and 5 closest channels, to assess spatial decay. Highly negeative values indicate there is no/little spatial decay. 

#### 'cell-like' shape 

Assess whether the waveform baseline is flat or not.  
    											
####  % spikes missing 

estimate the percent of spikes missing (false nagatives) by fitting a gaussian the distribution of amplitudes, with a cutoff parameter. This assumes the spike amplitudes follow a gaussian distribution, which is not strictly true for bursty cells, like MSNs. This can then define which epochs of the recording to keep for a unit, if it has for example drifted relative to the recording sites and in only some recording epochs a substantial amount of spikes are missing.

Below: example of unit with many spikes below the detection threshold in the first two time chunks of the recording. 

<img style="float: right;" src="https://github.com/Julie-Fabre/bombcell/blob/master/images/percSpikesMissingDrift.png" width=60% height=60%>

#### number of spikes 

Number of spikes over the recording. Below a certain amount of spikes, ephys properties like ACGs will not be reliable. A good minimum to use is 300 empirically, because Kilosort2 does not attempt to split any clusters that have less than 300 spikes in the post-processing phase.


#### refractory period violations

Estimate fraction of refractory period violations (false positives) using  r = 2*(tauR - tauC) * N^2 * (1-Fp) * Fp / T , solving for Fp, with tauR the refractory period, tauC the censored period, T the total experiment duration, r the number of refractory period violations, Fp the fraction of contamination. method from [Hill et al., J. Neuro, 2011](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3123734/). 

Below: examples of a unit with a small fraction of refractory period violations (left) and one with a large fraction (right).

<img style="float: right;" src="https://github.com/Julie-Fabre/bombcell/blob/master/images/rpv.png" width=60% height=60%>


#### amplitude 

Amplitude of the mean raw waveformelfor a unit, to eliminate noisy, further away units, that are more likely to be MUA. 

Below: examples of a unit with high amplitude (blue) and one with low amplitude (red).

<img style="float: right;" src="https://github.com/Julie-Fabre/bombcell/blob/master/images/amplitude.png" width=30% height=30%>


#### distance metrics  

Compute measure of unit isolation quality: the isolation distance (see [Harris et al., Neuron, 2001](https://www.sciencedirect.com/science/article/pii/S0896627301004470?via%3Dihub)), l-ratio (see [Schmitzer-Torbert and Redish, 2004](https://journals.physiology.org/doi/full/10.1152/jn.00687.2003)) and silhouette-score (see [Rousseeuw, 1987](https://www.sciencedirect.com/science/article/pii/0377042787901257)). 

Below: examples of a unit with high isolation distance (left) and one with low isolation distance (right).

<img style="float: right;" src="https://github.com/Julie-Fabre/bombcell/blob/master/images/isolationDistance.png" width=60% height=60%>


#### Global output plots 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/unitRemovedEulerVenn.png" width=80% height=80%>

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/generalPlotHist.png">

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/waveformsSingleNoise.png" width=60% height=60%>

### Quality metrics GUI guide 

Plot a GUI to flip through the quality metrics for each cell with the function `bc_unitQualityGUI` Eg:

    bc_unitQualityGUI(memMapData, ephysData, qMetrics, param, probeLocation, unitType, plotRaw)
    
<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/gui.gif">
    
#### Unit location view

This view plots the depth of each unit on the probe in y, and it's log-normalized firing rate in x. Single units are plotted in green, multi-units in indigo and noise in red. The current unit is plotted larger and circled in black. 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_location.png" width=30% height=30%>

#### Template waveform view

This view plot the template waveforms for the current unit. The maximum waveform is in blue, and detected peaks are overlaid. 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_tempwv.png" width=30% height=30%>

#### Raw waveform view

This view plot the mean raw waveforms for the current unit. The maximum waveform is in blue, and detected peaks are overlaid. 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_rawWv.png" width=30% height=30%>


#### ACG view

This view plot the auto-correlogram (ACG) for the current unit. The horizontal red line indicates the ACG asymptote, which corresponds to the unit's firing rate. The vertical red line plot the refractory period location. 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_acg.png" width=30% height=30%>


#### ISI view

This view plot the inter-spike-intervals (ISI) for the current unit. The vertical red line plot the refractory period location. 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_isi.png" width=30% height=30%>

#### Isolation distance view

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_isoD.png" width=30% height=30%>

### Raw waveform view 

Plots the raw data in black, with detected spikes for this unit in blue. 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_raw.png" width=40% height=40%>

#### Amplitude view

This view plots the scaling factor applied to each spike by kilosort in black. Spikes currently displayed in the raw data view are shown in blue, and spikes that have an ISI < refractory period threshold are shown in purple. 

<img src="https://github.com/Julie-Fabre/bombcell/blob/master/images/GUI_ampli.png" width=60% height=60%>

### Ephys properties guide

work in progress


### Recommended recording and pre-processing 

To reduce the noise units you obtain, we recommend recording with either both a ground wire and reference wire going from the probe to the mouse, or with a ground wire and the internal reference (if using probes other than the 3A - the internal reference on these doesn't work well). To remove artefacts from your recorded data, temporally align your channels with each other and common-average reference your data with Bill Karsh's function [`CatGT`](https://billkarsh.github.io/SpikeGLX/), before feeding this data into kilosort. 

To maximize your number of single good units, we recommend looking at your raw data and spikes detected by kilosort, to assess whether most spikes are being detected. If not, consider lowering kilosort's detection thresholds. 

### Dependancies

- https://github.com/kwikteam/npy-matlab (to load data in)

