function WriteLog(date, msg)
    % Define file path and string to write
    folder = '\\atlas.shore.mbari.org\ProjectLibrary\901805_Coastal_Biogeochemical_Sensing\WireWalker\MBARI\Logs';  % Folder
    filename = 'log.txt'; % File
    filepath = fullfile(folder, filename);
    
    % Check if file exists
    if exist(filepath, 'file')
        % Append to file
        fid = fopen(filepath, 'a');  % 'a' = append
    else
        % Create and write to new file
        fid = fopen(filepath, 'w');  % 'w' = write (creates file if it doesn't exist)
    end
    
    % Write the string and add a newline
    fprintf(fid, '%s %s\n', date, msg);
    
    % Close the file
    fclose(fid);
end
