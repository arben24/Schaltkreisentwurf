close all;
clear;
clc;

%%%%%%%%%%% Signalfile laden %%%%%%%%%%%%%%%%%%%
load('test_signal_1.mat');  % Erwartet: Variablen 'symbole_rx' und 'preamble'

%%%%%%%% Parameter %%%%%%%%%%%%%%%
Lp = length(preamble);       % Länge der Präambel (z.B. 23)
T = 0.71;                   % Schwellenwert (Threshold)
T_Lp = T * Lp;             % Konstante für die transformierte Ungleichung
N = length(symbole_rx) - Lp;
last_detect = 1;

%%%%%%%%%%% Berechnung – Methode 1 %%%%%%%%%%%%%%%%%%
metrik_reell_vec1 = zeros(1, N);
detect_vec       = zeros(1, N);

for it = 1:N
    % Berechne die Summe (ohne Division) über das Fenster
    temp_sum = sum( symbole_rx(it:it+Lp-1) .* conj(preamble) );
    if(abs(real(temp_sum)) >7 || abs(imag(temp_sum))>7)
    temp_sum;
    end
    % Leistungsabschätzung als Summe der quadrierten Beträge
    power_estimate = sum( real(symbole_rx(it:it+Lp-1)).^2 + imag(symbole_rx(it:it+Lp-1)).^2 );
    if(power_estimate > 7)
    power_estimate;
    end
    
    % Normierte Metrik gemäß Herleitung:
    metrik_reell_vec1(it) = (real(temp_sum)^2+imag(temp_sum)^2) / (Lp * power_estimate);
    
    % Transformierte Ungleichung
    if (real(temp_sum)^2+imag(temp_sum)^2) > T_Lp * power_estimate
        detect_vec(it) = 1;
        payload_estimate = it - last_detect - Lp;
        last_detect = it;
    else
        detect_vec(it) = 0;
    end
end

%%%%%%%%%%% Berechnung – Methode 2 (Mean-Version) %%%%%%%%%%%%%%%%%%
metrik_reell_vec2 = zeros(1, N);
for it = 1:N
   metrik_temp    = sum( symbole_rx(it:it+Lp-1) .* conj(preamble) ) / Lp;
   power_estimate = mean( abs(symbole_rx(it:it+Lp-1)).^2 );
   metrik_reell_vec2(it) = (abs(metrik_temp)^2) / power_estimate;
end

%%%%%%%%%%% Plot %%%%%%%%%%%%%%%%%%
figure;
subplot(3,1,1);
plot(metrik_reell_vec1, 'b', 'LineWidth', 1.5);
grid on;
xlabel('Symbol Index');
ylabel('m(k) normiert');
title('normierte Metrik mit für HDL optimierte berechnung');

subplot(3,1,2);
plot(detect_vec, 'r', 'LineWidth', 2);
grid on;
xlabel('Symbol Index');
ylabel('Detection (1 = Detected)');
title('Detection mit selber berechnung wie in HDL');

subplot(3,1,3);
plot(metrik_reell_vec2, 'g', 'LineWidth', 1.5);
grid on;
xlabel('Symbol Index');
ylabel('m(k) normiert');
title('normierte Metrik (klasschische Berechnung)');

%%%%%%%%%%% Ausgabe der Detektionsposition %%%%%%%%%%%%%%%%%%
detection_idx = find(detect_vec, 1, 'first');
if ~isempty(detection_idx)
    fprintf('Preamble detected (Methode 1) at symbol index: %d\n', detection_idx);
else
    fprintf('No preamble detected (Methode 1).\n');
end
