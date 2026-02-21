disp('Bypassing hardware constraints to compile IFF instructions...');

% 1. Create a fresh configuration using a board MATLAB trusts
hPC = dlhdl.ProcessorConfig;
hPC.TargetPlatform = 'Xilinx Zynq ZC706 evaluation kit'; % Unlocks 1GB RAM natively

% 2. Match the EXACT architecture of the IP core we already generated
hPC.ProcessorDataType = 'int8'; 
hPC.UseVendorLibrary = 'off'; 
hPC.setModuleProperty('conv', 'ConvThreadNumber', 4); 
hPC.setModuleProperty('fc', 'FCThreadNumber', 4);
hPC.setModuleProperty('conv', 'InputMemorySize', [128 1 4]);
hPC.setModuleProperty('conv', 'OutputMemorySize', [128 1 32]);
hPC.setModuleProperty('fc', 'InputMemorySize', 1024); 
hPC.setModuleProperty('fc', 'OutputMemorySize', 128);
hPC.setModuleProperty('custom', 'ModuleGeneration', 'off');

% Set execution control
hPC.InputRunTimeControl = 'register'; 
hPC.OutputRunTimeControl = 'register'; 

% 3. Initialize the workflow using this trusted configuration
% Notice we are NOT passing the corrupted .mat file here
hW = dlhdl.Workflow('Network', quantObj, 'ProcessorConfig', hPC);

% 4. Compile the instructions
disp('Compiling network software binaries...');
hW.compile();