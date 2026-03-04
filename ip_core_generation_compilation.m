disp('Generating fresh IP Core and Compiling for ZedBoard...');

% 1. Create a fresh configuration for ZedBoard (xc7z020)
hPC = dlhdl.ProcessorConfig;
hPC.TargetPlatform = 'Generic Deep Learning Processor';
hPC.SynthesisToolChipFamily = 'Zynq';
hPC.SynthesisToolDeviceName = 'xc7z020';
hPC.SynthesisToolPackageName = 'clg484';
hPC.SynthesisToolSpeedValue = '-1';

% Match the exact architecture
hPC.ProcessorDataType = 'int8'; 
hPC.UseVendorLibrary = 'off'; 
hPC.setModuleProperty('conv', 'ConvThreadNumber', 4); 
hPC.setModuleProperty('fc', 'FCThreadNumber', 4);
hPC.setModuleProperty('conv', 'InputMemorySize', [128 1 4]);
hPC.setModuleProperty('conv', 'OutputMemorySize', [128 1 32]);
hPC.setModuleProperty('fc', 'InputMemorySize', 1024); 
hPC.setModuleProperty('fc', 'OutputMemorySize', 128);
hPC.setModuleProperty('custom', 'ModuleGeneration', 'off');

hPC.InputRunTimeControl = 'register'; 
hPC.OutputRunTimeControl = 'register'; 

% 2. Build the Processor to generate a clean hardware constraint file (.mat)
disp('Building processor to generate hardware constraints...');
hWC = hdlcoder.WorkflowConfig('SynthesisTool', 'Xilinx Vivado', 'TargetWorkflow', 'Deep Learning Processor');
hWC.AllowUnsupportedToolVersion = true; 

dlhdl.buildProcessor(hPC, 'ProjectFolder', 'dlhdl_prj', ...
                     'ProcessorName', 'mode_s_ip', ...
                     'WorkflowConfig', hWC);

% 3. Initialize the workflow using the FRESH .mat file with mapped memory
disp('Initializing HDL Workflow with ZedBoard Memory Mapping...');
ip_mat_path = fullfile('dlhdl_prj', 'mode_s_ip.mat');

% Ensure the quantized model is loaded in the workspace
if ~exist('quantObj', 'var')
    load('mode_s_quantized_fpga.mat');
end

% Create a Bitstream object to explicitly declare the ZedBoard's 512MB DDR3 memory
% '20000000' is 512MB in hexadecimal, bypassing the 0x0 bytes limitation
hB = dlhdl.Bitstream(ip_mat_path, ...
    'MemoryBaseAddress', '00000000', ...
    'MemoryAddressRange', '20000000', ... 
    'ProcessorBaseAddress', '40000000');

% Pass the newly mapped Bitstream object (hB) to the workflow
hW = dlhdl.Workflow('Network', quantObj, 'Bitstream', hB);

% 4. Compile the instructions
disp('Compiling network software binaries...');
hW.compile();
disp('Compilation complete!');