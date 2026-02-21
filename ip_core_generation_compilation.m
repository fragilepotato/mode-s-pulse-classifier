%% 1. Configure Resource-Optimized Processor for ZedBoard
disp('Configuring Resource-Optimized Processor for ZedBoard...');

% Initialize the Processor Configuration object
hPC = dlhdl.ProcessorConfig;
hPC.TargetPlatform = 'Generic Deep Learning Processor';

% Force the compiler to use Zynq-7000 constraints
hPC.SynthesisToolChipFamily = 'Zynq';
hPC.SynthesisToolDeviceName = 'xc7z020'; 
hPC.SynthesisToolPackageName = 'clg484';
hPC.SynthesisToolSpeedValue = '-1';

% --- CRITICAL: FORCE INT8 HARDWARE GENERATION ---
hPC.ProcessorDataType = 'int8'; 
hPC.UseVendorLibrary = 'off'; 

% 1. Reduce Parallel Threads
hPC.setModuleProperty('conv', 'ConvThreadNumber', 4); 
hPC.setModuleProperty('fc', 'FCThreadNumber', 4);

% 2. Shrink BRAM Allocations
hPC.setModuleProperty('conv', 'InputMemorySize', [128 1 4]);
hPC.setModuleProperty('conv', 'OutputMemorySize', [128 1 32]);
hPC.setModuleProperty('fc', 'InputMemorySize', 1024); 
hPC.setModuleProperty('fc', 'OutputMemorySize', 128);

% 3. Disable the Custom Math Module
hPC.setModuleProperty('custom', 'ModuleGeneration', 'off');

% Set execution control
hPC.InputRunTimeControl = 'register'; 
hPC.OutputRunTimeControl = 'register'; 

%% 2. Configure the Workflow to Bypass Version Checking
disp('Configuring Workflow constraints...');
hWC = hdlcoder.WorkflowConfig('SynthesisTool', 'Xilinx Vivado', 'TargetWorkflow', 'Deep Learning Processor');
hWC.AllowUnsupportedToolVersion = true; 

%% 3. Generate the Synthesizable IP Core
disp('Generating the Deep Learning AXI-Stream IP Core...');

% Run HDL Coder with the optimized hardware profile
dlhdl.buildProcessor(hPC, 'ProjectFolder', 'dlhdl_prj', ...
                     'ProcessorName', 'mode_s_ip', ...
                     'WorkflowConfig', hWC);
disp('IP Core successfully generated in the ./dlhdl_prj/ipcore directory!');

%% 4. Initialize the Workflow Object for Compilation
disp('Initializing HDL Workflow for Compilation...');

ip_mat_path = fullfile('dlhdl_prj', 'mode_s_ip.mat');
hW = dlhdl.Workflow('Network', quantObj, 'Bitstream', ip_mat_path);

%% 5. Compile the Network Instructions
disp('Compiling INT8 model into hardware instructions...');
hW.compile();

disp('Compilation complete! You are ready for Vivado integration.');