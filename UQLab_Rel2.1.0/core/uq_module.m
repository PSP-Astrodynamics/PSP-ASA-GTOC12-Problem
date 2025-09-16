%% uq_module: superclass for the creation of leaf modules
%  this is the superclass of all of the leaf modules that will be created.
%  Each has to be identified by a Name. Additional comments will be added
%  when further developed


classdef uq_module < dynamicprops % this is once again a child of the dynamicprops superclass
    properties(SetObservable)
        Internal;
    end
    
    properties(SetAccess=protected)
        Name;
        Type;
    end
    
    properties(SetObservable,Hidden=true)
        core_component = [];
        displayFun = [];
        printFun = [];
    end
    
    methods (Static, Hidden=true)
        function uninitialize(src, evt)
            evt.AffectedObject.Internal.Runtime.isInitialized = false;
        end
    end
    
    methods(Hidden=true)
        function setinitialized(this)
            this.Internal.Runtime.isInitialized = true;
        end
        
        function changeName(this,newName)
            this.Name = newName;
        end
        
        function Print(this, varargin)
            if ~isempty(this.printFun)
                if nargin > 1
                    this.printFun(this,varargin{:});
                else
                    this.printFun(this);
                end
            else
                this
            end
        end
        
        function varargout = Display(this, varargin)
            if ~isempty(this.displayFun)
                if nargout == 1
                    if nargin > 1
                        H = this.displayFun(this, varargin{:});
                    else
                        H = this.displayFun(this);
                    end
                    varargout{1} = H;
                else
                    if nargin > 1
                        this.displayFun(this, varargin{:});
                    else
                        this.displayFun(this);
                    end
                end
            else
                this
            end
        end
        
        
        
        function objCopy = Duplicate(this)
            objByteArray = getByteStreamFromArray(this);
            objCopy = getArrayFromByteStream(objByteArray);
        end
    end
end
    

