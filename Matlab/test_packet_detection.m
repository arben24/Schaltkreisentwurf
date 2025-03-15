close all;
clear variables;
clc;

%%%%%%%%%%% Signalfile laden %%%%%%%%%%%%%%%%%%%
load('test_signal_4.mat');

%%%%%%%% Preamble Correlation %%%%%%%%%%%%%%%%%%

metrik_reell_vec = [];
Lp                  = length(preamble);

for it = 1:length(symbole_rx) - Lp
   metrik_temp      = sum( symbole_rx(it:it+Lp-1) .* conj(preamble) ) / Lp;
   power_estimate   = mean(abs(symbole_rx(it:it+Lp-1)).^2);
   metrik_reell_vec = [metrik_reell_vec, (abs(metrik_temp).^2) / power_estimate ];
end


plot(metrik_reell_vec);
grid;
xlabel('Symbol Idx');
ylabel('m(k) normiert');
hold on






