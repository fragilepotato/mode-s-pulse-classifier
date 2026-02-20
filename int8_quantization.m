%% 15. Setup Data for Calibration
% The quantizer requires a datastore object to feed data through the network.
% We use our 15% Validation set, slicing it along the 4th dimension (the batch).
calData = arrayDatastore(XValidation, 'IterationDimension', 4);

%% 16. Initialize the Quantizer for FPGA
disp('Initializing FPGA INT8 Quantizer...');

% By explicitly setting 'ExecutionEnvironment' to 'FPGA', MATLAB restricts 
% the quantization strategies to those supported by Xilinx DSP slices.
quantObj = dlquantizer(trainedNet, 'ExecutionEnvironment', 'FPGA');

%% 17. Calibrate the Network
disp('Calibrating model... (This feeds the data through to collect min/max ranges)');
calResults = calibrate(quantObj, calData);

% You can view the collected dynamic ranges for your weights and biases
disp(calResults);



%% 18. Generate and Validate the INT8 Network
disp('Quantizing the network to INT8...');

% Generate a simulatable version of the INT8 network in MATLAB
qNet = quantize(quantObj);

disp('Testing the quantized INT8 model against the unseen Test Set...');
% We must ensure the INT8 truncation didn't destroy our classification accuracy
YPred_INT8 = classify(qNet, XTest);

% Calculate the new accuracy
accuracy_INT8 = sum(YPred_INT8 == YTest) / numel(YTest);

% Compare it to the original accuracy (assuming 'accuracy' is still in your workspace)
if exist('accuracy', 'var')
    disp(['Original Float-32 Accuracy: ', num2str(accuracy * 100), '%']);
end
disp(['INT8 Quantized Accuracy: ', num2str(accuracy_INT8 * 100), '%']);

%% 19. Save the Calibrated Object
% CRITICAL: The Deep Learning HDL Toolbox deployment workflow requires the 
% calibrated 'quantObj' itself, NOT just the 'qNet' network.
save('mode_s_quantized_fpga.mat', 'quantObj', 'qNet');
disp('Calibrated quantizer saved to mode_s_quantized_fpga.mat ready for HDL Generation.');