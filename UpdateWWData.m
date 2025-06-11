clear all; close all;
opengl('save', 'software')  % Run Matlab with software openGL. This will prevent matlab crashing due to graphics error with the VM
% Add paths
addpath(genpath('C:\Users\spraydata\Documents\MATLAB\')); % RBR functions
addpath(genpath('C:\Users\spraydata\Documents\GitHub\MBARIWireWalker')); % WireWalker functions
addpath(genpath('\\atlas.shore.mbari.org\ProjectLibrary\901805_Coastal_Biogeochemical_Sensing\WireWalker\'));
% Point to directory
cd('\\atlas.shore.mbari.org\ProjectLibrary\901805_Coastal_Biogeochemical_Sensing\WireWalker\MBARI\')
try
    % Read data
    date_start = '2025-04-28'; % Start of deployment
    filename = fullfile('data',['WW_data_composite_',date_start,'.csv']); % Build filename
    if isfile(filename)
        opts = detectImportOptions(filename);
        previousdata = readtable(filename,opts); % Read data
        previousdata.DateTime.TimeZone = "UTC";
        date_last = datestr(previousdata.DateTime(end), 'yyyy-mm-dd');
        Station_last = max(previousdata.Station);
    else
        date_last = date_start; % no file means download all data
        Station_last = 0;
    end
    % Get the current date
    date_now = datestr(datetime('now'), 'yyyy-mm-dd');
    % Build link to download data range from RBR
    baseurl = 'https://data.rbr-global.com/mbari/download/205880?from=';
    url = sprintf('%s%s&to=%s&download=Download+CSV',baseurl,date_last,date_now);
    % Download data from last date to current date
    newfile = fullfile('data',[date_now,'.csv']);
    options = weboptions;
    options.RequestMethod='get';
    options.Timeout = 10000;
    fprintf('Downloading data: %s to %s.............',date_last, date_now);
    websave(newfile,url,options);
    fprintf('DONE\n');
    % Build data as upcast profiles in a csv format
    rsk = CSV2RSK(newfile); % Converts csv into RSK struct allowing RBR functions to work on the data set
    rsk=RSKderiveseapressure(rsk); % Derive sea pressure with TEOS-10 package
    rsk=RSKderivesalinity(rsk); % Derive salinity from conductivity
    rsk = RSKderivedepth(rsk); % Derive depth from pressure
    rsk = RSKtimeseries2profiles(rsk); % Convert timeseries data into distinct up and downcast profiles 
    % pH Calibration Data for GDF006
    k2 = -0.001081;
%     k0 = -1.48321167902191;
    k0 = -1.4330; % Adjusted using canb derived mean k0 for extremes of t,s,02 below 80m. (extremes = 1.5* std in direction of upwelling)
    
    tblcols = []; % Initialize accumulator
    % Can change 1 no last Station from previousdata (will have to fix the
    % up/downcast problem)
    for i = 1:size(rsk.data, 2)
        if strcmp(rsk.data(i).direction, 'up')
            temp = rsk.data(i);
            data = temp.values;
    
            % Expand timestamp
            if isscalar(temp.tstamp) % if scalar use repmat
                tstamp = repmat(temp.tstamp, size(data, 1), 1);
            else % if vector use all data
                tstamp = temp.tstamp;
            end
    
            % Add profile (Station), lat, lon as a column
            Station = repmat(temp.profilenumber, size(data, 1), 1); % Add Station_last to keep stations consistent
            Latitude = repmat(36.780507,size(data, 1), 1);
            Longitude = repmat(-121.876059,size(data, 1), 1);
    
            % Combine time, profile number, and data
            newprof = [tstamp, Station, Latitude, Longitude, data];
    
            % Accumulate all profiles
            tblcols = [tblcols; newprof];
        end
    end
    % Cruise	Station	Type	mon/day/yr	hh:mm	Lon [°E]	Lat [°N]
    % Ensure variable names are correct and acceptable for matlab
    varNames = ['DateTime','Station','Latitude','Longitude' matlab.lang.makeValidName({rsk.channels.longName})];
    WW = array2table(tblcols, 'VariableNames', varNames);
    WW.DateTime = datetime(datevec(WW.DateTime),'TimeZone','UTC'); % UTC Matlab DateTime
    WW.Properties.VariableNames{'pH'} = 'Vrse'; % Rename 'pH' to Vrse
    WW.pH = calc_pHext(WW.Vrse,WW.Temperature,WW.Salinity,k0,k2); % Calc pH from Vrse (Need pcoefs!!)
    
    tic
    if isfile(filename)
        % Find rows in WW with timestamps not already in previousdata
        newrows = ~ismember(WW.DateTime, previousdata.DateTime);
    
        % Only keep truly new data
        WW_new = WW(newrows, :);
    
        % Append only if there's new data
        if ~isempty(WW_new)
             % Add last station number to remain consistent:
            WW_new.Station = (WW_new.Station - WW_new.Station(1)) + Station_last + 1; % Reset station number after new rows and add last station
            writetable(WW_new, filename, 'WriteMode', 'Append');
            WriteLog(date_now, ['Added profiles: ', num2str(WW_new.Station(1)), ' - ', num2str(WW_new.Station(end))])
        else
            disp('No new rows to append.');
            WriteLog(date_now, 'No new rows to append.')
        end
    else
        % File doesn't exist — save all
        writetable(WW, filename); % Save table to CSV
        WriteLog(date_now, 'New file created from scratch')
    end
    toc
    
    % Delete the new file
    newcsv = fullfile('data',[date_now,'.csv']);
    if isfile(newcsv)
        delete(newcsv)
    end
    
    % try to write ODV file
    try
        WriteODV("WW_data_composite_2025-04-28.csv")
    catch
        disp('Could not write file')
        WriteLog(date_now, 'Could not write file')
    end

    % try to make updated 1Hz figure
    try
        CreateFigure
    catch
        disp('Could not create figure')
        WriteLog(date_now, 'Could not write file')
    end

catch ME
    WriteLog(date_now, 'did not work')
    fprintf('ERROR: %s\n', ME.message);
    fprintf('STACK TRACE:\n');
    for k = 1:length(ME.stack)
        fprintf('  File: %s\n  Function: %s\n  Line: %d\n', ...
            ME.stack(k).file, ME.stack(k).name, ME.stack(k).line);
    end
end