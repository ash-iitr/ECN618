%Complete the MATLAB script to simulate OFDM in an AWGN channel. Generate a bitstream of 10^7 bits, set the number of subcarriers equal to 64. Use 4-QAM modulation. Vary the SNR from 0 to 10 dB and then calculate the BER to plot the BER vs SNR curve.

%% Fill the parameters
rng(1);
N = 64; % Number of subcarriers
M = 4; % Constellation size (QAM)
num_bits = 1e7; % Number of bits to transmit
snr_dB = 0:10; % SNR range in dB


% Generate random bits ( should be of dimension: num_bits X 1 , Hint:- use randi function)
bits = randi([0 1],num_bits,1); % your code here (input bits)

% Modulate the bits using QAM (Hint:- use qammod function)
symbols = qammod(bits,M); % your code here

% Perform OFDM modulation (call the helper function)
ofdm_symbols = ofdm_mod(symbols,N); % your code here

% Initialize variables to store results
ber = zeros(size(snr_dB));

% Loop over SNR values
for i = 1:length(snr_dB)
    % Add AWGN noise
    rx_ofdm_symbols = awgn(ofdm_symbols, snr_dB(i), 'measured');

    % Perform OFDM demodulation (call the helper function)
    rx_symbols = ofdm_demod(rx_ofdm_symbols,N); % your code here

    % Demodulate the symbols using QAM (Hint:- use qamdemod function)
    rx_bits = qamdemod(rx_symbols,M); % your code here

    % Calculate BER
    ber(i) = sum(rx_bits~=bits)/num_bits; % your code here
end

% Plot BER vs SNR
semilogy(snr_dB, ber, 'r-^','LineWidth',2);
title("OFDM simulation in an AWGN channel"); grid on;
xlabel('SNR (dB)');
ylabel('BER');


%% helper functions

% OFDM modulation function
function ofdm_symbols = ofdm_mod(symbols, N)
    % Reshape symbols into a matrix of subcarrier symbols
    symbols_mat = reshape(symbols, N, []);

    % Perform IFFT on each row (subcarrier)
    ofdm_symbols_mat = ifft(symbols_mat);

    % Add cyclic prefix
    ofdm_symbols_mat = [ofdm_symbols_mat(end-15:end,:); ofdm_symbols_mat];

    % Reshape back to a column vector
    ofdm_symbols = reshape(ofdm_symbols_mat, [], 1);
end

% OFDM demodulation function
function symbols = ofdm_demod(ofdm_symbols, N)
    % Reshape OFDM symbols into a matrix
    ofdm_symbols_mat = reshape(ofdm_symbols, N+16, []);

    % Remove cyclic prefix
    ofdm_symbols_mat = ofdm_symbols_mat(17:end, :);

    % Perform FFT on each row (subcarrier)
    symbols_mat = fft(ofdm_symbols_mat);

    % Reshape back to a column vector
    symbols = reshape(symbols_mat, [], 1);
end
