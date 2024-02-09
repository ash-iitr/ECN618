%Complete the MATLAB code to generate the magnitude and spectrogram of 5G PDSCH of bandwidth 90 MHz and 
% carries data in single bandwidth parts (BWP) having numerologies 0  by considering  size of 50 RBs and following information:
% a) SLIV = 41
% b) PDSCH Power = 1.585w
% c) MCS Index = 12
% d) PDSCH allocated in 2 slots
% e) DMRS Power = 0.001w
% f) DMRS Configuration = 1
% g) DMRS length = 2
% f) DMRS additional position = 1
% g) CDM group without data = 2
% f) PRB length = 40

%% Waveform and Carrier Configuration
waveconfig = nrDLCarrierConfig;    % Create a downlink carrier configuration object
waveconfig.Label = 'DL carrier 1'; % Label for this downlink waveform configuration
waveconfig.NCellID = 0;            % Cell identity
waveconfig.ChannelBandwidth = 90;  % Channel bandwidth (MHz)
waveconfig.FrequencyRange = 'FR1'; % 'FR1' or 'FR2'
waveconfig.NumSubframes = 1;      % Number of 1 ms subframes in generated waveform (1, 2, 4, 8 slots per 1 ms subframe, depending on SCS)
%% subcarrier Spacing
scscarriers = {nrSCSCarrierConfig};
scscarriers{1}.SubcarrierSpacing = 15;
scscarriers{1}.NSizeGrid = 50;
scscarriers{1}.NStartGrid = 0;
%% BWPs
bwp = {nrWavegenBWPConfig};
bwp{1}.BandwidthPartID = 1;        % BWP ID
bwp{1}.SubcarrierSpacing = 15;     % BWP subcarrier spacing
bwp{1}.NSizeBWP = 50;              % Size of BWP in PRBs
bwp{1}.NStartBWP = 0;             % Position of BWP, relative to point A, in CRBs
%% PDSCH
pdsch = {nrWavegenPDSCHConfig};           % Create a PDSCH configuration object for the first UE
pdsch{1}.Enable = 1;                      % Enable PDSCH sequence
pdsch{1}.BandwidthPartID = 1;             % Bandwidth part of PDSCH transmission
pdsch{1}.Power  = 2;                      % Power scaling in dB
pdsch{1}.Coding = 1;                      % Enable the DL-SCH transport channel coding
pdsch{1}.NumLayers = 2;                   % Number of PDSCH layers
pdsch{1}.TargetCodeRate = 517/1024;       % Code rate used to calculate transport block sizes
pdcch{1}.DataBlockSize = 20;              % DCI payload size
pdcch{1}.DataSource = 'PN9';              % DCI data source
pdsch{1}.Modulation = '64QAM';           % 'QPSK', '16QAM', '64QAM', '256QAM'
pdsch{1}.RVSequence = [0,2,3,1];        % RV sequence to be applied cyclically across the PDSCH allocation sequence
pdsch{1}.VRBToPRBInterleaving = 0;      % Disable interleaved resource mapping
pdsch{1}.VRBBundleSize = 2;             % vrb-ToPRB-Interleaver parameter

%% Allocation
pdsch{1}.SymbolAllocation = [0,12];   % First symbol and length
pdsch{1}.SlotAllocation = [0,1];        % Allocated slot indices for PDSCH sequence
pdsch{1}.Period = 1;                % Allocation period in slots
pdsch{1}.PRBSet = (0:40);                % PRB allocation
pdsch{1}.RNTI = 1;                   % RNTI for the first UE
% *PDSCH DM-RS Configuration*
% Antenna port and DM-RS configuration (TS 38.211 section 7.4.1.1)
pdsch{1}.MappingType = 'A';                % PDSCH mapping type ('A'(slot-wise),'B'(non slot-wise))
pdsch{1}.DMRSPower = -30;                    % Additional power boosting in dB

pdsch{1}.DMRS.DMRSConfigurationType =  1;  % DM-RS configuration type (1,2)
pdsch{1}.DMRS.NumCDMGroupsWithoutData =2;  % Number of DM-RS CDM groups without data. The value can be one of the set {1,2,3}
pdsch{1}.DMRS.DMRSPortSet = [];            % DM-RS antenna ports used ([] gives port numbers 0:NumLayers-1)
pdsch{1}.DMRS.DMRSTypeAPosition = 2;     % Mapping type A only. First DM-RS symbol position (2,3)
pdsch{1}.DMRS.DMRSLength =  2;             % Number of front-loaded DM-RS symbols (1(single symbol),2(double symbol))   
pdsch{1}.DMRS.DMRSAdditionalPosition =1;  % Additional DM-RS symbol positions (max range 0...3)
pdsch{1}.DMRS.NIDNSCID = 1;                % Scrambling identity (0...65535)
pdsch{1}.DMRS.NSCID = 0;                   % Scrambling initialization (0,1)
%% Waveform Generation
waveconfig.SCSCarriers = scscarriers;
waveconfig.BandwidthParts = bwp;
waveconfig.PDSCH = pdsch;
% Generate complex baseband waveform
[waveform,info] = nrWaveformGenerator(waveconfig);
%% 
%Plot the magnitude of the baseband waveform for the set of antenna ports defined.
figure;
plot(abs(waveform));
title('Magnitude of 5G Downlink Baseband Waveform');
xlabel('Sample Index');
ylabel('Magnitude');
%%
% Plot the spectogram of the waveform for the first antenna port.
samplerate = info.ResourceGrids(1).Info.SampleRate;
nfft = info.ResourceGrids(1).Info.Nfft;
figure;
spectrogram(waveform(:,1),ones(nfft,1),0,nfft,'centered',samplerate,'yaxis','MinThreshold',-130);
title('Spectrogram of 5G Downlink Baseband Waveform');
disp('Modulation information associated with BWP 1:')
disp(info.ResourceGrids(1).Info)
