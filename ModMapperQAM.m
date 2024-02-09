%% Shared Channel Parameters
rng(210); % Set RNG state for repeatability
A = 10000 % Transport block length, positive integer
rate = 449/1024; % Target code rate, 0<R<1
modulation = '64QAM';
rv = 0; % Redundancy version, 0-3
nlayers = 1; % Number of layers, 1-4 for a transport block
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
    modulated = MODULATION_MAPPER(scrambled, modulation);   
    % Layer mapping, TS 38.211 Section 7.3.1.3
    sym = nrLayerMap(modulated,nlayers);
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

%% Equivalent Function for Modulation

function symbOut = MODULATION_MAPPER(data, mod_type)


  switch (mod_type)
    
     case '16QAM'
        
        % write logic for QPSK symbol mapping , store the final symbols in 'symbOut'
        for l=0:((length(data)/4) -1)
        % write logic for 16 QAM symbol mapping , store the final symbols in 'symbOut'
        symbOut(l+1,1) = (1/sqrt(10)) *  ( (1 - 2*data((4*l) +1))*(2 -(1-2*data((4*l) +3))) + 1j*( 1 - 2*data((4*l)+2)) *(2 -(1-2*data((4*l) +4))));
        end
         
     case '64QAM'
        
       %write logic for 16 QAM symbol mapping , store the final symbols in 'symbOut'
        for l=0:(floor(length(data)/6) -1)
        %write logic for 16 QAM symbol mapping , store the final symbols in 'symbOut'
        symbOut(l+1,1) = (1/sqrt(42)) * (((1 - 2*data((6*l) +1)) *( 4 - (1 - 2*data((6*l) +3))*(2-(1 - 2*data((6*l) +5))))) + 1j* ((1 - 2*data((6*l) +2)) *( 4 - (1 - 2*data((6*l) +4))*(2-(1 - 2*data((6*l) +6))))));
        end

     % (1/sqrt(10)) * (((1 - 2*data((6*l) +1)) *( 4 - (1 - 2*data((6*l) +1))*(2-(1 - 2*data((6*l) +1))))) + 1j* ((1 - 2*data((6*l) +1)) *( 4 - (1 - 2*data((6*l) +1))*(2-(1 - 2*data((6*l) +1))))));
   end
end
