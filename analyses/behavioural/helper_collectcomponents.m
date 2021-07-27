% @Description: Collect a group of components (that you want to remove from
% something, by prompt of the user).

function components = helper_collectcomponents()
    components = [];
    
    while 1
        c = input('Which component should be flagged bad? (<= 0 to exit)');
        
        if c < 1
            break
        end
        
        components(end+1) = c;
    end
end

