% Complete the below code to evaluate bit error rate performance of the transport channel processing in PDSCH signal flow over a noisy channel. 
% 
% Hint: You may need to code the logic for code block segmentation in order to generate the BER result.  You can find out the details at Section 5.2 of TS 38.212.

%LDPC Processing for DL-SCH and UL-SCH
%% Shared Channel Parameters
rng(210); % Set RNG state for repeatability
A = 10000; % Transport block length, positive integer
rate = 449/1024; % Target code rate, 0<R<1
rv = 0; % Redundancy version, 0-3
modulation = 'QPSK'; % Modulation scheme, QPSK, 16QAM, 

nlayers = 1; % Number of layers, 1-4 for a transport block 
SNRdB= -2:0.1:2;% SNR in dB
%% DL-SCH coding parameters
cbsInfo = nrDLSCHInfo(A,rate);
disp('DL-SCH coding parameters')
disp(cbsInfo)
% %% function 
for iter = 1:length(SNRdB)
 %% Transport Block Processing using LDPC Coding
 % Random transport block data generation
 in = randi([0 1],A,1,'int8');
 % Transport block CRC attachment
 tbIn = nrCRCEncode(in,cbsInfo.CRC);
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 % <<<<<<<<<< IMPLEMENT CODE BLOCK SEGMENTATION without using nrCodeBlockSegmentLDPC function >>>>>>>>>>>>>>>
 
 %                                            <<<<IMPORTANT>>>> 
 %%%%%%%%%%         Refer the document TS 38.212 Section 5.2.2 for the implementation assistance      %%%%%%%%%%%%%
 
 x=tbIn;%data bit vector
 bg=cbsInfo.BGN;%BASE GRAPH NUMBER(1OR2)
 h=length(x) % h is the transport block size
 
 % If B is larger than the maximum code block size Kcb, segmentation of the input bit sequence is performed and an additional CRC sequence of L = 24 bits is attached to each code block.  
 
 % write maximum code block size kcb based on base graph (bg equals either 1 or 2)
 if bg==1
    kcb= 8448 ; % fill the value
 else
    kcb= 3840 ; % fill the value
 end
 
 % compute Total number of code blocks C
 
 if h<=kcb
    L=0;
    C=1 ; % fill the value
    A1=h ; % fill the value, Note:- Total number of bits equals the transport block size in this case 
 else
    L=24;
    C=ceil(h/(kcb-L)) ; % your code here
    A1= h + C*L ; % your code here
 end
     
 k1=A1/C;  % k1 IS NUMBER OF BITS IN EACH CODEBLOCK
 
 %DETERMINE kb
 if bg==1
    kb= 22 ; % fill value
    
 else if h>640    % for bg == 2
    kb= 10; % fill value
    
 else if h>560
    kb= 9; % fill value
    
 else if h>192
    kb= 8; % fill value
    
 else
    kb=6 ; % fill value
    end
   end
  end
 end
 
 Z=[2:16 18:2:32 36:4:64 72:8:128 144:16:256 288:32:384];%from 38.212-table 5.3.2-1
 ZC=min(Z(kb*Z>=k1));
 
 % F1 represents filler bits in each code block
 
 if bg==1;
    k= 22*ZC ; % fill value
    F1= k-k1; % compute the filler bits (subtract k from the total no. bits in each codeblock)
 else
 k= 10*ZC ; % fill value
 F1= k-k1; % compute the filler bits
 end
 
 %PERFORM SEGMENTATION AND ADD CRC BITS
 
 CB= ceil(h/C);  %NUMBER OF BITS PER CODE BLOCK
 
 %PERFORM CODE BLOCK SEGMENTATION AND CRC ENCODING
 if C==1
    crk=x;%x is tbIn
 else
    cbl=reshape([x;zeros(CB*C-h,1)],CB,C);%RESHAPING
    
    crk= nrCRCEncode(cbl,'24B') ; % perform CRC encoding of cb1 with '24B' generator polynomial (you are allowed to use the dedicated built in function from 5G toolbox).
 end
 
 cbsIn= [crk; -ones(F1,C)]   ; % Append filler bits at the end of each codeblock. The value of filler bits should be used as -1 and the dimension of the cbsIN should be number of bits (k) times number of Code Blocks (C)
 

  %%%%%%%  <<<<<<<<<< End of code block segmentation and crc attachment >>>>>>>>>>>>>>>
 
 % LDPC encoding
 enc = nrLDPCEncode(cbsIn,cbsInfo.BGN); 
 % Rate matching and code block concatenation
 outlen = ceil(A/rate);
 chIn = nrRateMatchLDPC(enc,outlen,rv,modulation,nlayers);
 
 %% Noisy Channel
 noise=(10^-SNRdB(iter)/20)*randn(length(chIn),1);
 chOut = double(1-2*(chIn))+ noise; 
 
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
semilogy(SNRdB,BER,'b', LineWidth=2)
