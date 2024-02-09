%Write a MATLAB code to generate the magnitude and spectrogram of 5G uplink Baseband signal with Bandwidth of 30 MHz, carrier frequency of 2.4GHz, to show 2 msec frame duration and enter 80% of the Maximum grid size for numerology 0.

%% 5G NR UPLINK WAVEFORM

waveconfig = nrULCarrierConfig(); % Create an instance of the waveform's parameter object
waveconfig.Label = 'UL carrier 1'; % Label for this uplink waveform configuration
waveconfig.NCellID = 0; % Cell identity
waveconfig.ChannelBandwidth =30 ; % Channel bandwidth (MHz)
waveconfig.FrequencyRange = 'FR1'; % Fill the frequency range here 'FR1' or 'FR2'
waveconfig.NumSubframes = 2; % Number of 1ms subframes in generated waveform (1,2,4,8 slots per 1ms subframe, depending on SCS)
waveconfig.CarrierFrequency = 2.4e9; % Carrier frequency in Hz. 

scscarriers = {nrSCSCarrierConfig()};
scscarriers{1}.SubcarrierSpacing =15 ; % Subcarrier frequency in KHz
scscarriers{1}.NSizeGrid = 128; % Size of the resource grid in terms resource blocks (RBs)
scscarriers{1}.NStartGrid = 0; % Staring RB of the resource grid

%% Waveform Generation
waveconfig.SCSCarriers = scscarriers;

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
