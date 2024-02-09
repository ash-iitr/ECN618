%% Shared Channel Parameters
rng(210); % Set RNG state for repeatability
A = 10000; % Transport block length, positive integer
rate = 449/1024; % Target code rate, 0<R<1
rv = 0; % Redundancy version, 0-3
modulation = 'QPSK'; % Modulation scheme, QPSK, 16QAM, 64QAM, 256QAM
nlayers = 3 ; % Number of layers, 1-4 for a transport block
SNRdB= -2:0.1:2;% SNR in dB
%%
nid=1;
rnti=1;
q=1;
%% DL-SCH coding parameters
cbsInfo = nrDLSCHInfo(A,rate);
disp('DL-SCH coding parameters')
disp(cbsInfo)
for iter = 1:length(SNRdB)
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
    sym = layer_mapping(modulated,nlayers);
    %% AWGN Channel
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
    disp(['CRC error per code-block: [' num2str(blkErr) ']'])
    % Transport block CRC decoding
    [out,tbErr] = nrCRCDecode(blk,cbsInfo.CRC);
    BER(iter)= biterr(in, out)./length(in);
end
disp(['Transport lock CRC error: ' num2str(tbErr)])
disp(['Recovered transport block with no error: ' num2str(isequal(out,in))])
semilogy(SNRdB,BER)

%% custom function to implement layer mapping
%% custom function to implement layer mapping
function x = layer_mapping(d, N_layers)
  % d is the modulated symbols
  
    switch(N_layers)
        case 1
            x = d;
        case 3
            l = length(d)/3;
            x = zeros(l,3);
            for i = 1:l
                v = i-1;
                x(i,1) = d(3*v+1);
                x(i,2) = d(3*v+2);
                x(i,3) = d(3*v+3);
            end
        case 5 
            d0 = d{1};
            d1 = d{2};
            l0 = length(d0)/2;
            l1 = length(d1)/3;
            x = zeros(l0,5);
            for i = 1:l0
                v = i-1;
                x(i,1) = d0(2*v+1);
                x(i,2) = d0(2*v+2);
                x(i,3) = d1(3*v+1);
                x(i,4) = d1(3*v+2);
                x(i,5) = d1(3*v+3);
            end
        case 7
            d0 = d{1};
            d1 = d{2};
            l0 = length(d0)/3;
            l1 = length(d1)/4;
            x = zeros(l0,7);
            for i = 1:l0
                v = i-1;
                x(i,1) = d0(3*v+1);
                x(i,2) = d0(3*v+2);
                x(i,3) = d1(3*v+3);
                x(i,4) = d1(4*v+1);
                x(i,5) = d1(4*v+2);
                x(i,6) = d1(4*v+3);
                x(i,7) = d1(4*v+4);
            end
         
    end

    % write logic below to implement layer mapping covering nLayers upto 8
    
end