# Mode-S Pulse Classifier

A MATLAB-based neural network classifier for Mode-S pulse detection and classification, optimized for FPGA deployment.

## Project Overview

This project implements a deep learning-based pulse classifier for Mode-S transponder signals. It includes training, quantization, and deployment pipelines for FPGA implementation.

## Files

- **pulse_classifier_model.m** - Main neural network model definition and training script
- **pulse_classifier_layers.m** - Neural network architecture layer definitions
- **mode_s_synthetic_data.m** - Synthetic data generation for training and testing
- **int8_quantization.m** - INT8 quantization for FPGA deployment
- **mode_s_trained_float.mat** - Trained floating-point model weights
- **mode_s_quantized_fpga.mat** - Quantized model for FPGA deployment
- **mode_s_synthetic_data.mat** - Pre-generated synthetic training/test data

## Requirements

- MATLAB R2020b or later
- Deep Learning Toolbox
- Signal Processing Toolbox

## Usage

1. **Generate Synthetic Data**
   ```matlab
   run('mode_s_synthetic_data.m')
   ```

2. **Train the Model**
   ```matlab
   run('pulse_classifier_model.m')
   ```

3. **Quantize for FPGA**
   ```matlab
   run('int8_quantization.m')
   ```

## Model Architecture

The classifier uses a convolutional neural network optimized for real-time pulse detection on FPGA hardware with INT8 quantization for efficient inference.

## License

MIT License
