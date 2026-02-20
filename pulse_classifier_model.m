%% 10. Load Data and Define Training Options
% Ensure the data is loaded if you restarted MATLAB
% load('mode_s_synthetic_data.mat');

% Define the training options
options = trainingOptions('adam', ...
    'InitialLearnRate', 0.001, ...
    'MaxEpochs', 15, ...                         % 15 epochs is plenty for this synthetic data
    'MiniBatchSize', 128, ...                    % Process 128 preambles at a time
    'Shuffle', 'every-epoch', ...                % Prevent the model from memorizing order
    'ValidationData', {XValidation, YValidation}, ...
    'ValidationFrequency', 30, ...               % Check validation accuracy every 30 iterations
    'Verbose', false, ...
    'Plots', 'training-progress', ...            % Open the UI to watch the training curve
    'ExecutionEnvironment', 'auto');             % Will use GPU if available, else CPU

%% 11. Train the Network
disp('Starting network training...');
% Note: 'layers' must be in your workspace from the Phase 1 script
trainedNet = trainNetwork(XTrain_Final, YTrain_Final, layers, options);
disp('Training complete!');



%% 12. Evaluate Baseline Accuracy on the Test Set
disp('Evaluating model on the unseen Test Set...');

% Run predictions on the 15% hold-out test set
YPred = classify(trainedNet, XTest);

% Calculate overall accuracy
accuracy = sum(YPred == YTest) / numel(YTest);
disp(['Baseline Floating-Point Accuracy: ', num2str(accuracy * 100), '%']);

%% 13. Visualize Performance
% A single accuracy number isn't enough for IFF degarbling. 
% We need to see if the model confuses "Garbled" with "Clean".
figure;
confusionchart(YTest, YPred, ...
    'Title', 'Confusion Matrix: IFF Mode S Preamble Classifier', ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');



%% 14. Save the Trained Model
% Save the floating-point model for the FPGA quantization step
save('mode_s_trained_float.mat', 'trainedNet');
disp('Trained floating-point model saved to mode_s_trained_float.mat');