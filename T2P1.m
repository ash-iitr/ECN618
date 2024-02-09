% Complete the below code to evaluate bit error rate performance of PDSCH signal flow over a noisy channel. 
% 
% Hint: You may need to code the logic for CRC-Decoding in order to generate the BER result.  You can find out the details at Section 5.1 of TS 38.212.


%% Shared Channel Parameters
rng(210); % Set RNG state for repeatability
A = 10000; % Transport block length, positive integer
rate = 449/1024; % Target code rate, 0<R<1
rv = 0; % Redundancy version, 0-3
modulation = 'QPSK'; % Modulation scheme, QPSK, 16QAM, 64QAM, 256QAM
nlayers = 1; % Number of layers, 1-4 for a transport block
SNRdB= -1:0.05:0;% SNR in dB
Num_TB_Blocks=20;
%%
nid=1;
rnti=1;
q=1;
%% DL-SCH coding parameters
cbsInfo = nrDLSCHInfo(A,rate);
disp('DL-SCH coding parameters')
disp(cbsInfo)
for iter = 1:length(SNRdB)
    count_block_error=0;
    count_bit_error=0;
    for iter_2=1:Num_TB_Blocks
    %% Transport Block Processing using LDPC Coding
    % Random transport block data generation
    in = randi([0 1],A,1,'int8');
    % Transport block CRC attachment
    tbIn = nrCRCEncode(in,cbsInfo.CRC);
    % Code block segmentation and CRC attachment
    cbsIn = nrCodeBlockSegmentLDPC(tbIn,cbsInfo.BGN); 
    % LDPC encoding
    enc = nrLDPCEncode(cbsIn,cbsInfo.BGN); 
    % Rate matching and code block concatenation
    outlen = ceil(A/rate);
    chIn = nrRateMatchLDPC(enc,outlen,rv,modulation,nlayers);
    % Scrambling, TS 38.211 Section 7.3.1.1 
    c = nrPDSCHPRBS(nid,rnti,q-1,length(chIn));
    scrambled = xor(chIn,c);
    % Modulation, TS 38.211 Section 7.3.1.2
    modulated = nrSymbolModulate(scrambled,modulation);
    % Layer mapping, TS 38.211 Section 7.3.1.3
    sym = nrLayerMap(modulated,nlayers);
    %% Noisy Channel 
    noise=(10^-SNRdB(iter)/20)*randn(size(sym));
    rx_sym = sym + noise; 
    %% 
    % Layer demapping, inverse of TS 38.211 Section 7.3.1.3
    symbols = nrLayerDemap(rx_sym);
    % Demodulation, inverse of TS 38.211 Section 7.3.1.2
    noiseEst=1e-10;
    demodulated = nrSymbolDemodulate(symbols{q},modulation);
    % Descrambling, inverse of TS 38.211 Section 7.3.1.1
    opts.MappingType = 'signed';
    opts.OutputDataType = 'double';
    c = nrPDSCHPRBS(nid,rnti,q-1,length(demodulated),opts);
    chOut = demodulated.*c;
    %% Receive Processing using LDPC Decoding
    % Rate recovery
    raterec = nrRateRecoverLDPC(chOut,A,rate,rv,modulation,nlayers);
    % LDPC decoding
    decBits = nrLDPCDecode(raterec,cbsInfo.BGN,25); 
    % Code block desegmentation and CRC decoding
    [blk,blkErr] = nrCodeBlockDesegmentLDPC(decBits,cbsInfo.BGN,A+cbsInfo.L); 
    % Transport block CRC decoding 
    
    [out, CRC_pass] = crc_decoding(blk, cbsInfo.CRC);  % call the custom function crc_decoding after defining it
    
    count_block_error=count_block_error+CRC_pass;
    count_bit_error=count_bit_error+biterr(in, out);
    end
    disp(['The number of TB Blocks with CRC pass status: ' num2str(count_block_error) ' out of the ' num2str(Num_TB_Blocks) ' TB blocks at SNR ' num2str(SNRdB(iter)) ' dB']);
    BLER(iter)=(Num_TB_Blocks-count_block_error)/Num_TB_Blocks;
    disp(['The number of bits in error: ' num2str(count_bit_error) ' out of the ' num2str(length(in)*Num_TB_Blocks) ' bits at SNR ' num2str(SNRdB(iter)) ' dB']);
    BER(iter)= count_bit_error./(length(in)*Num_TB_Blocks);
end
figure(1)
semilogy(SNRdB,BLER); xlabel('SNR in dB'); ylabel('BLER');
figure(2)
semilogy(SNRdB,BER); xlabel('SNR in dB'); ylabel('BER');



% custom CRC decoding function
function [output, CRC_pass]= crc_decoding(input, generator)
% input - input sequence of bits
% generator - cyclic generator polynomial

% Define the generator polynomials for different lengths
generator_polynomial_24A = [1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1];
generator_polynomial_24B = [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1];
generator_polynomial_24C = [1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1];
generator_polynomial_16 = [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1];
generator_polynomial_11 = [1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1];
generator_polynomial_6 = [1, 1, 0, 0, 0, 1];

% Choose the appropriate generator polynomial based on the length of the CRC polynomial
if generator == '24A'
    generator_polynomial = generator_polynomial_24A;
elseif generator == '24B'
    generator_polynomial = generator_polynomial_24B;
elseif generator == '24C'
    generator_polynomial = generator_polynomial_24C;
elseif generator == '16'
    generator_polynomial = generator_polynomial_16;
elseif generator == '11'
    generator_polynomial = generator_polynomial_11;
elseif generator == '6'
    generator_polynomial = generator_polynomial_6;
end

% Re-encode the output with the respective generator polynomial, Note: you can use inbuilt function nrCRCEncode'

data = length(input)-length(generator_polynomial);
output =input(1:data); % final output
re_encoded_block = nrCRCEncode(output,generator);
% Check whether the parity bits are zero or non-zero
errBits = input(data+1:end) == re_encoded_block(data+1:end);
% if all the bits are zero declare it as CRC pass by setting it to 1
% otherwise 0
CRC_pass= all(errBits);
% slice the data from  the re_encoded_block or the input in a column vector
end
