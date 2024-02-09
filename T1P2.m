%Complete the MATLAB code to generate the magnitude and spectrogram of 5G uplink Baseband signal of bandwidth 100 MHz operating at 3.5 GHz carrier frequency and carries data in two bandwidth parts (BWP) having numerologies 0 and 2, respectively. Both the BWPs occupy 50 resource blocks (RBs) worth of data while maintaining a gap of 18 MHz. Show the spectrogram for 2 ms of duration wherein the first BWP occupies all the slots and the second BWP occupies only the odd slots.

%% 5G NR UPLINK WAVEFORM

waveconfig = nrULCarrierConfig(); % Create an instance of the waveform's parameter object
waveconfig.Label = 'UL carrier 1'; % Label for this uplink waveform configuration
waveconfig.NCellID = 0; % Cell identity
waveconfig.ChannelBandwidth = 100; % Channel bandwidth (MHz)
waveconfig.FrequencyRange = 'FR1'; % Fill the frequency range here
waveconfig.NumSubframes = 2; % Number of 1ms subframes in generated waveform (1,2,4,8 slots per 1ms subframe, depending on SCS)
waveconfig.CarrierFrequency = 3.5e9; % Carrier frequency in Hz. 

scscarriers = {nrSCSCarrierConfig(),nrSCSCarrierConfig()};
scscarriers{1}.SubcarrierSpacing = 15;% the subcarrier spacing in KHz
scscarriers{1}.NSizeGrid = 270;  % Maximum number of RBs for numerology 0
scscarriers{1}.NStartGrid = 0; % Staring RBs

scscarriers{2}.SubcarrierSpacing = 60;% the subcarrier spacing in KHz
scscarriers{2}.NSizeGrid = 135;  % Maximum number of RBs for numerology 2
scscarriers{2}.NStartGrid = 0; % Staring RBs

%% Bandwidth Parts

% Bandwidth parts configurations
bwp = {nrWavegenBWPConfig(),nrWavegenBWPConfig()};
bwp{1}.BandwidthPartID = 1; % Bandwidth part ID
bwp{1}.Label = 'BWP for mu0'; % Label for this BWP
bwp{1}.SubcarrierSpacing =   15   ; % BWP subcarrier spacing
bwp{1}.CyclicPrefix = 'Normal'; % BWP cyclic prefix for 15 kHz
bwp{1}.NSizeBWP = 50; % Size of BWP in PRBs
bwp{1}.NStartBWP = 6; % Position of BWP, relative to point A (i.e. CRB)

bwp{2}.BandwidthPartID = 2; % Bandwidth part ID
bwp{2}.Label = 'BWP for mu2'; % Label for this BWP
bwp{2}.SubcarrierSpacing =    60     ; % BWP subcarrier spacing
bwp{2}.CyclicPrefix = 'Normal'; % BWP cyclic prefix for 30 kHz
bwp{2}.NSizeBWP = 50; % Size of BWP in PRBs
bwp{2}.NStartBWP = 39; % Position of BWP, relative to point A (i.e. CRB)


%% No value to be changed from line 44 to line 154 of the code
pusch = {nrWavegenPUSCHConfig()};
pusch{1}.Enable = 1; % Enable PUSCH sequence
pusch{1}.Label = 'PUSCH for mu0'; % Label for this PUSCH sequence
pusch{1}.BandwidthPartID = 1; % Bandwidth part of PUSCH transmission
pusch{1}.SymbolAllocation = [0,14]; % First symbol and length
pusch{1}.SlotAllocation =[0 1] ; % Allocated slots indices for PUSCH sequence
pusch{1}.PRBSet = 0:49; % PRB allocation
% 
% %% Specify the second PUSCH sequence for the second BWP.
% 
pusch{2} = pusch{1};
pusch{2}.Label = 'PUSCH for mu2';
pusch{2}.BandwidthPartID = 2; % PUSCH mapped to 2nd BWP
pusch{2}.SymbolAllocation = [0,14];
pusch{2}.SlotAllocation = [0 2 4 6];
pusch{2}.PRBSet = 0:49; % PRB allocation, relative to BWP

%% Waveform Generation
waveconfig.SCSCarriers = scscarriers;
waveconfig.BandwidthParts = bwp;
waveconfig.PUSCH = pusch;
% waveconfig.SRS = srs;

% Generate complex baseband waveform
[waveform,info] = nrWaveformGenerator(waveconfig);


%%
% Plot the magnitude of the baseband waveform for the set of antenna ports defined.

figure;
plot(abs(waveform));
title('Magnitude of 5G Uplink Baseband Waveform');
xlabel('Sample Index');
ylabel('Magnitude');

%%
% Plot spectogram of waveform for first antenna port.

samplerate = info.ResourceGrids(1).Info.SampleRate;
nfft = info.ResourceGrids(1).Info.Nfft;
figure;
spectrogram(waveform(:,1),ones(nfft,1),0,nfft,'centered',samplerate,'yaxis','MinThreshold',-130);
title('Spectrogram of 5G Uplink Baseband Waveform');
disp('Modulation information associated with BWP 1:')
disp(info.ResourceGrids(1).Info)
