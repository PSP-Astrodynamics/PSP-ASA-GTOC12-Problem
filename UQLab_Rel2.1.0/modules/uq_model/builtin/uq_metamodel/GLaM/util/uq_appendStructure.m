function mergedStruct = uq_appendStructure(mergedStruct,newStruct,type)
if ~isstruct(mergedStruct)
    mergedStruct = newStruct;
else
    fn = fieldnames(newStruct);
    fo = fieldnames(mergedStruct);
    
    % choose the merge type
    switch lower(type)
        
        % the new structure is merged to a structure array
        case 'struct'
            oo = length(mergedStruct);            
            if isempty(fn)
                mergedStruct(oo+1).(fo{1})=[];
            else
                for in = 1:length(fn)
                    fname = fn{in};
                    mergedStruct(oo+1).(fname)=newStruct.(fname);
                end
            end
        
        % the attribute of the new structure is merged into the associated
        % array of the existing structure
        case 'array'            
            No = length(mergedStruct.(fo{1}));
            % retrieve the values for the existing fields
            for in=1:length(fo)
                fname = fo{in};
                if ismember(fname,fn)
                    mergedStruct.(fname)=[mergedStruct.(fname),newStruct.(fname)];
                else
                    mergedStruct.(fname)=[mergedStruct.(fname),NaN];
                end
            end
            
            % new field that has not been defined should be initialized to
            % keep a consistent length
            newf = setdiff(fn,fo);
            for in=1:length(newf)
                fname = newf{in};
                mergedStruct.(fname)=[nan(1,No),newStruct.(fname)];
            end
    end
end

end