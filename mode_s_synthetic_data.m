% Mode S Preamble Synthetic Data Generator for Zynq/AD9361 CNN
clear; clc;

%% 1. Configuration Parameters
fs = 16e6;                   % Sampling rate: 16 MSPS
window_time = 8e-6;          % Preamble window: 8 microseconds
num_samples = fs * window_time; % 128 samples per window
num_records_per_class = 2000;   % Generate 2000 examples per class

% Pulse positions in microseconds
pulse_starts_us = [0, 1.0, 3.5, 4.5];
pulse_width_us = 0.5;

% Convert time to sample indices
pulse_start_idx = round(pulse_starts_us * fs / 1e6) + 1;
pulse_len_samples = round(pulse_width_us * fs / 1e6);

%% 2. Generate Base Preamble Template
base_preamble = zeros(num_samples, 1);
for i = 1:length(pulse_start_idx)
    start_idx = pulse_start_idx(i);
    end_idx = start_idx + pulse_len_samples - 1;
    base_preamble(start_idx:end_idx) = 1;
end

%% 3. Initialize Arrays for Deep Learning
% Shape: [Height(128) x Width(1) x Channels(2) x Batch(N)]
total_records = num_records_per_class * 3;
XData = zeros(num_samples, 1, 2, total_records, 'single');
YData = strings(total_records, 1);

current_idx = 1;

%% 4. Generate Class 1: Clean Preambles
for i = 1:num_records_per_class
    % Randomize amplitude and carrier phase
    amplitude = 0.5 + rand() * 0.5; 
    phase = rand() * 2 * pi;
    
    % Create Complex I/Q Signal
    clean_iq = amplitude * base_preamble .* exp(1j * phase);
    
    % Add AWGN (Random SNR between 10dB and 30dB)
    snr = 10 + rand() * 20;
    noisy_iq = awgn(clean_iq, snr, 'measured');
    
    % Split into I and Q channels for the CNN
    XData(:, 1, 1, current_idx) = real(noisy_iq);
    XData(:, 1, 2, current_idx) = imag(noisy_iq);
    YData(current_idx) = "Clean";
    
    current_idx = current_idx + 1;
end

%% 5. Generate Class 2: Garbled (Overlapping) Preambles
for i = 1:num_records_per_class
    % Generate Primary Signal
    amp1 = 0.6 + rand() * 0.4;
    phase1 = rand() * 2 * pi;
    sig1 = amp1 * base_preamble .* exp(1j * phase1);
    
    % Generate Secondary Interfering Signal (FRUIT / Garbling)
    amp2 = 0.3 + rand() * 0.6; % Interferer can be stronger or weaker
    phase2 = rand() * 2 * pi;
    shift_samples = randi([4, 60]); % Random delay for overlapping signal
    
    sig2 = zeros(num_samples, 1);
    interferer = amp2 * base_preamble .* exp(1j * phase2);
    sig2(shift_samples:end) = interferer(1:end-shift_samples+1);
    
    % Combine and add noise
    garbled_iq = sig1 + sig2;
    snr = 15 + rand() * 15;
    garbled_noisy_iq = awgn(garbled_iq, snr, 'measured');
    
    XData(:, 1, 1, current_idx) = real(garbled_noisy_iq);
    XData(:, 1, 2, current_idx) = imag(garbled_noisy_iq);
    YData(current_idx) = "Garbled";
    
    current_idx = current_idx + 1;
end

%% 6. Generate Class 3: Pure Noise / No Preamble
for i = 1:num_records_per_class
    % Generate pure AWGN without any underlying pulse structure
    noise_power = 0.01 + rand() * 0.05;
    noise_iq = sqrt(noise_power/2) * (randn(num_samples, 1) + 1j*randn(num_samples, 1));
    
    XData(:, 1, 1, current_idx) = real(noise_iq);
    XData(:, 1, 2, current_idx) = imag(noise_iq);
    YData(current_idx) = "Noise";
    
    current_idx = current_idx + 1;
end

%% 7. Format for Training
% Convert string labels to categorical arrays
YData = categorical(YData);

% Shuffle the dataset
shuffle_idx = randperm(total_records);
XTrain = XData(:, :, :, shuffle_idx);
YTrain = YData(shuffle_idx);

disp('Synthetic IFF dataset successfully generated!');
disp(['Total samples: ', num2str(size(XTrain, 4))]);

% Optional: Plot a random garbled sample to visualize the I/Q channels
figure;
sample_to_plot = find(YTrain == "Garbled", 1);
plot(squeeze(XTrain(:, 1, 1, sample_to_plot)), 'b', 'LineWidth', 1.5); hold on;
plot(squeeze(XTrain(:, 1, 2, sample_to_plot)), 'r', 'LineWidth', 1.5);
title('Garbled IFF Preamble (I and Q Channels)');
legend('In-Phase (I)', 'Quadrature (Q)');
grid on;

%% 8. Split the Data (70% Train, 15% Validation, 15% Test)
% The dataset is already randomized from the previous step, 
% so we can safely slice it sequentially based on indices.

total_samples = size(XTrain, 4);

train_ratio = 0.70;
val_ratio = 0.15;
% test_ratio is inherently the remaining 0.15

num_train = floor(train_ratio * total_samples);
num_val = floor(val_ratio * total_samples);

% Define index boundaries
idx_train = 1:num_train;
idx_val = (num_train + 1):(num_train + num_val);
idx_test = (num_train + num_val + 1):total_samples;

% Create the unseen Test Set (15%)
XTest = XTrain(:,:,:,idx_test);
YTest = YTrain(idx_test);

% Create the Validation Set (15%) for monitoring during training
XValidation = XTrain(:,:,:,idx_val);
YValidation = YTrain(idx_val);

% Overwrite the original XTrain/YTrain to only contain the Training subset (70%)
XTrain_Final = XTrain(:,:,:,idx_train);
YTrain_Final = YTrain(idx_train);

disp(['Training samples: ', num2str(length(YTrain_Final))]);
disp(['Validation samples: ', num2str(length(YValidation))]);
disp(['Testing samples: ', num2str(length(YTest))]);

%% 9. Save to a .mat file
% Save the partitioned matrices to your current directory
save('mode_s_synthetic_data.mat', 'XTrain_Final', 'YTrain_Final', ...
     'XValidation', 'YValidation', 'XTest', 'YTest');

disp('Datasets successfully split and saved to mode_s_synthetic_data.mat');