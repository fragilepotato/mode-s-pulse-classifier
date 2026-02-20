% Define the input dimensions: [Height Width Channels]
% 128 time samples, 1 spatial dimension, 2 channels (I and Q baseband)
inputSize = [128 1 2];
numClasses = 3; % Clean, Garbled, Noise

% Construct a lightweight CNN optimized for the Zynq-7020 DSP limits
layers = [
    imageInputLayer(inputSize, 'Name', 'iq_input', 'Normalization', 'none')
    
    % First Convolutional Block - Feature Extraction
    % 7x1 filter captures the shape of individual Mode S pulses
    convolution2dLayer([7 1], 8, 'Padding', 'same', 'Name', 'conv_1')
    batchNormalizationLayer('Name', 'bn_1')
    reluLayer('Name', 'relu_1')
    maxPooling2dLayer([2 1], 'Stride', [2 1], 'Name', 'pool_1') % Downsample to 64
    
    % Second Convolutional Block - Pattern Recognition
    % 5x1 filter looks for the spacing between the 4 preamble pulses
    convolution2dLayer([5 1], 16, 'Padding', 'same', 'Name', 'conv_2')
    batchNormalizationLayer('Name', 'bn_2')
    reluLayer('Name', 'relu_2')
    maxPooling2dLayer([2 1], 'Stride', [2 1], 'Name', 'pool_2') % Downsample to 32
    
    % Fully Connected layers for Classification
    fullyConnectedLayer(32, 'Name', 'fc_1')
    reluLayer('Name', 'relu_fc1')
    fullyConnectedLayer(numClasses, 'Name', 'fc_final')
    
    % Output
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];

% Analyze the network to ensure it's valid
lgraph = layerGraph(layers);
analyzeNetwork(lgraph);