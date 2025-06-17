function WriteODV(filename)
% Takes WireWalker data and writes a 1 Hz csv file
% Ben Werb | Bwerb@mbari.org | 6/17/2025
    folder = '\\atlas.shore.mbari.org\ProjectLibrary\901805_Coastal_Biogeochemical_Sensing\WireWalker\MBARI\data';
    fname = fullfile(folder,filename);
    WWload = readtable(fname); % read full upcast data
    time_rounded = dateshift(WWload.DateTime, 'start', 'second');  % snap to nearest second -> 8 Hz to 1 Hz
    [~, ia] = unique(time_rounded, 'stable');  % select first value for each second
    WWload = WWload(ia, :); % index first value for each second
    Cruise = repmat("MBARIWW20250428",height(WWload),1); % Make cruise col
    Type = repmat("C",height(WWload),1); % make type col
    dateStr = string(datestr(WWload.DateTime, 'mm/dd/yyyy')); % e.g., '06/02/25'
    timeStr = string(datestr(WWload.DateTime, 'HH:MM:SS')); % e.g., '14:30:21'

    % Calculate rho: Density from Absolute Salinity and Conservative
    % Temperature
    SP = WWload.Salinity;
    p = WWload.Pressure;
    lon = WWload.Longitude;
    lat = WWload.Latitude;
    t = WWload.Temperature;
    SA = gsw_SA_from_SP(SP, p, lon, lat);
    CT = gsw_CT_from_t(SA, t, p);
    WWload.rho = gsw_rho(SA, CT, p);

    % Calculate N2: Buoyancy Frequency
    [N2, p_mid] = gsw_Nsquared(SA, CT, p, lat);
    WWload.N2 = [NaN; N2];
    WWload.p_mid = [NaN; p_mid];

    % Calculate %O2Sat
    WWload.o2satper = WWload.DissolvedO2 ./...
        calcO2sat(WWload.Temperature, WWload.Salinity) .* 100; % Saturation %
    
    % Assemble data in a table
    T = table(Cruise,WWload.Station,Type,dateStr,timeStr,...
        WWload.Longitude,WWload.Latitude,'VariableNames',...
        {'Cruise','Station','Type','mm/dd/yyyy','HH:MM:SS',...
        'Lon [°E]', 'Lat [°N]'}); % rebuild table in ODV order to match glider data
    WWload.DateTime = [];
    WWload.Station = [];
    WWload.Latitude = [];
    WWload.Longitude = [];

    % Create final table to save
    WW = [T WWload]; % final table
    savefilename = fullfile(folder,'WW_Upcast_1Hz.txt');
    writetable(WW,savefilename);
end