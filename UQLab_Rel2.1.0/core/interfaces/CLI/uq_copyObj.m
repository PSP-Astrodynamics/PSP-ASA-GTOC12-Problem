function objCopy = uq_copyObj(Original)
% UQ_COPYOBJ  creates a copy of a UQLab object as a local variable.
%
%    UQOBJECTCOPY = UQ_COPYOBJ(UQOBJECT) creates a copy of the UQlab 
%    object UQOBJECT and returns it in UQOBJECTCOPY. UQOBJECTCOPY is
%    independdent on the original UQOBJECT.
%    
%    Note that the new object (UQOBJECTCOPY) is not added to the UQLab
%    session. One can do so by using the uq_importObj function.
%
%    See also: uq_importObj
%

objCopy = Duplicate(Original);