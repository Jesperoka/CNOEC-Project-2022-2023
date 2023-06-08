% Level 2 S-function to track signal histories
function history(block)
    CAPACITY = 1440; % yep, I'm just doing this cause' documentation is bad and time is limited 

    setup(block); % Don't call any other functions
    % Setup the basic characteristics of the S-function block. Is required.
    function setup(block)
        block.AllowSignalsWithMoreThan2D = 1; % skkrrrrt

        % Register number of ports
        block.NumInputPorts  = 1;
        block.NumOutputPorts = 1;

        % Setup port properties to be inherited or dynamic
        block.SetPreCompInpPortInfoToDynamic;
        block.SetPreCompOutPortInfoToDynamic;

        % Override input port properties
        block.InputPort(1).Dimensions = 1;
        block.InputPort(1).DatatypeID = 0;  % double
        block.InputPort(1).Complexity = 'Real';
        block.InputPort(1).DirectFeedthrough = true;
      
        % Override output port properties
        block.OutputPort(1).DatatypeID  = 0; % double
        block.OutputPort(1).Complexity  = 'Real';
        block.OutputPort(1).Dimensions  = [CAPACITY, 1];

        % Register parameters
        block.NumDialogPrms     = 0;

        % Register sample times
        %  [0 offset]            : Continuous sample time
        %  [positive_num offset] : Discrete sample time
        %
        %  [-1, 0]               : Inherited sample time
        %  [-2, 0]               : Variable sample time
        block.SampleTimes = [-1 0];

        % Specify the block simStateCompliance. The allowed values are:
        %    'UnknownSimState', < The default setting; warn and assume DefaultSimState
        %    'DefaultSimState', < Same sim state as a built-in block
        %    'HasNoSimState',   < No sim state
        %    'CustomSimState',  < Has GetSimState and SetSimState methods
        %    'DisallowSimState' < Error out when saving or restoring the model sim state
        block.SimStateCompliance = 'DefaultSimState';

        %% -----------------------------------------------------------------
        %% The MATLAB S-function uses an internal registry for all
        %% block methods. You should register all relevant methods
        %% (optional and required) as illustrated below. You may choose
        %% any suitable name for the methods and implement these methods
        %% as local functions within the same file. See comments
        %% provided for each function for more information.
        %% -----------------------------------------------------------------
        block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
        block.RegBlockMethod('Start', @Start);
        block.RegBlockMethod('Outputs', @Outputs);     % Required
        block.RegBlockMethod('Update', @Update);
        block.RegBlockMethod('Terminate', @Terminate); % Required

    end

    % Setup work areas and state variables. Can also register run-time methods here.
    function DoPostPropSetup(block)
        block.NumDworks = 2;
  
        block.Dwork(1).Name            = 'history';
        block.Dwork(1).Dimensions      = CAPACITY;
        block.Dwork(1).DatatypeID      = 0;      % double
        block.Dwork(1).Complexity      = 'Real'; % real
        block.Dwork(1).UsedAsDiscState = true;

        block.Dwork(2).Name            = 'counter';
        block.Dwork(2).Dimensions      = 1;
        block.Dwork(2).DatatypeID      = 0;      % double
        block.Dwork(2).Complexity      = 'Real'; % real
        block.Dwork(1).UsedAsDiscState = true;
    end
    
    % Called once at the start of simulation
    function Start(block)
        block.Dwork(1).Data = NaN(CAPACITY, 1, "double"); % history vector
        block.Dwork(2).Data = 1; % counter
        block.OutputPort(1).Data = block.Dwork(1).Data; 
    end

    % Called to generate outputs each simulation step
    function Outputs(block)
        % We're just preallocating a large vector and having it slowly fill up with numbers in place of NaNs
        block.OutputPort(1).Data = block.Dwork(1).Data;
    end

    % Called to update discrete states each simulation step
    function Update(block)
        block.Dwork(1).Data(block.Dwork(2).Data) = block.InputPort(1).Data;
        block.Dwork(2).Data = block.Dwork(2).Data + 1; % if we overflow I give up
    end

    % Called at the end of simulation for cleanup. Is required.
    function Terminate(block)
        % Do nothing
    end

end
