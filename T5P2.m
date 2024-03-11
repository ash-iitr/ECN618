%%Assume a cellular setup with M = 256 small cells as shown in the figure below, where each cell is equipped with a single Access Point (AP).  The coverage area for each AP is 4 unit area. A user is positioned randomly in the entire area span of all the small cells, i.e along x-axis user can be anywhere between 0 and 32 length unit, simlarly for y - axis as well. You need to verify the condition for small cell setup, , where  is channel between user and i-th AP and  is the path loss coefficient for that particular coefficient. The user transmits it's messages with a SNR 30 dBm. The path loss model assumed as .
%%Steps to verify:
%%Compute which cell will satisfy  and save their coordinates.
%%Similarly, find the cell which will satisfy  and save their coordinates.
%%If the values are similar and coordinates match, set TestPass variable = 1 else 0

clc;
clear;
close all;

%% BS positions
BS_loc = zeros(16,16);

for k=1:16
    for l = 1:16
        BS_loc(k,l) = k + 1j*(l);
    end
end

for k=1:16
    for l = 1:16
        BS_loc(k,l) = (real(BS_loc(k,l)) + k-1) + 1j*(imag(BS_loc(k,l)) + l-1);
    end
end

%% User Position

x_pos = 32*rand();
y_pos = 32*rand();

UE_loc = x_pos + 1j*y_pos;

scatter(real(BS_loc),imag(BS_loc),'blue','LineWidth',2);hold on;
scatter(real(UE_loc),imag(UE_loc),'red','LineWidth',2)
grid on;

%% pathloss coeff b/w UE and all APs
%% distance between each AP and UE
for k=1:16
    for l = 1:16
        Dist(k,l) = sqrt((real(UE_loc)-real(BS_loc(k,l)))^2 + (imag(UE_loc)-imag(BS_loc(k,l)))^2);
    end
end
%% Pathloss coefficients b/w UE and each AP 
 beta = zeros(16,16);

 for m = 1:16
     for n = 1:16
         beta(m,n) = 10^(((-30.5-36.7*log(Dist(m,n))))/10);
     end
 end

%% To find largest pathloss factor in the matrix
max = 0;
ind_x = 0;
ind_y = 0;
 for m = 1:16
     for n = 1:16
         if(abs(beta(m,n)))>max
             max = abs(beta(m,n));
             ind_x = m;
             ind_y = n;
         end
     end
 end


%% Calculating ergodic effective channel gain

iters = 1000;
h = zeros(16,16);
for ii=1:iters
    h = h + ((1/sqrt(2)) * (randn(16,16) + 1j*randn(16,16)) .* sqrt(beta));
end
h_avg = h/iters;

maxh = 0;
ind_hx = 0;
ind_hy = 0;
 for k = 1:16
     for l = 1:16
         if(abs(h_avg(k,l)))>maxh
             maxh = abs(h_avg(k,l));
             ind_hx = k;
             ind_hy = l;
         end
     end
 end

Y = ["Cell satisfying max ergodic channel gain is ",BS_loc(ind_hx,ind_hy)];
X = ["BS serving the user is at ",BS_loc(ind_x,ind_y)];
disp(Y);
disp(X);

if((ind_x == ind_hx) && (ind_y == ind_hy))
    TestPass = 1;
else 
    TestPass = 0;
end
