function CreateFigure
    folder = '\\atlas.shore.mbari.org\ProjectLibrary\901805_Coastal_Biogeochemical_Sensing\WireWalker\MBARI';
    fname = fullfile(folder,'data','WW_Upcast_1Hz.txt');
    
    % Load data
    T = readtable(fname);
    idxQC = T.pH > 6.8 & T.pH < 8.8; % simple QC
    T = T(idxQC,:);
    T.DateTime = T.mm_dd_yyyy + T.HH_MM_SS;
    T.DateTime.TimeZone = "UTC";
    
    % Calculate rho: Density from Absolute Salinity and Conservative
    % Temperature
    SP = T.Salinity;
    p = T.Pressure;
    lon = T.Lon__E_;
    lat = T.Lat__N_;
    t = T.Temperature;
    SA = gsw_SA_from_SP(SP, p, lon, lat);
    CT = gsw_CT_from_t(SA, t, p);
    T.rho = gsw_rho(SA, CT, p);

    % Calculate N2: Buoyancy Frequency
    [N2, p_mid] = gsw_Nsquared(SA, CT, p, lat);
    T.N2 = [NaN; N2];
    T.p_mid = [NaN; p_mid];
    
    % Set xlims
    xrange = [min(T.DateTime) max(T.DateTime)];
    
    % Compute percentile-based color limits for each variable
    t_clim  = prctile(T.Temperature,  [1 99]);
    s_clim  = prctile(T.Salinity,  [1 99]);
    o2_clim = prctile(T.DissolvedO2, [1 99]);
    ph_clim = prctile(T.pH, [1 99]);
    chl_clim = prctile(T.ChlorophyllA, [5 99]); % Removing the focus from the low data in the clim.
    rho_clim = prctile(T.rho, [1 99]);
    N2_clim = prctile(T.N2, [1 99]);

    % Create figure and tiled layout
    fig = figure('Units','normalized','Position',[0 0 1 1],'Visible','off'); % full screen
    tl = tiledlayout(7,1,"TileSpacing","tight","Padding","tight");
    title(tl,'MBARI C1 WireWalker')
    ylabel(tl,'Depth [m]')
    
    % Plot 1: Temperature
    nexttile
    scatter(T,"DateTime","Depth",ColorVariable="Temperature",Marker=".")
    cb = colorbar;
    ylabel(cb,'^oC')
    set(gca,'Ydir','Reverse')
    title('Temperature')
    xlabel('')
    ylabel('')
    caxis(t_clim)
    xlim(xrange)

    % Plot 2: Salinity
    nexttile
    scatter(T,"DateTime","Depth",ColorVariable="Salinity",Marker=".")
    cb = colorbar;
    ylabel(cb,'PSU')
    set(gca,'Ydir','Reverse')
    title('Salinity')
    xlabel('')
    ylabel('')
    caxis(s_clim)
    xlim(xrange)

    % Plot 3: Dissolved Oxygen
    nexttile
    scatter(T,"DateTime","Depth",ColorVariable="DissolvedO2",Marker=".")
    cb = colorbar;
    ylabel(cb,'\mumol/L')
    set(gca,'Ydir','Reverse')
    title('Doxy')
    xlabel('')
    ylabel('')
    caxis(o2_clim)
    xlim(xrange)

    % Plot 4: pH
    nexttile
    scatter(T,"DateTime","Depth",ColorVariable="pH",Marker=".")
    colorbar
    set(gca,'Ydir','Reverse')
    title('pH')
    xlabel('')
    ylabel('')
    caxis(ph_clim)
    xlim(xrange)

    % Plot 5: Chlorophyll
    nexttile
    scatter(T,"DateTime","Depth",ColorVariable="ChlorophyllA",Marker=".")
    cb = colorbar;
    ylabel(cb,'\mug/L')
    set(gca,'Ydir','Reverse')
    title('Chlorophyll')
    xlabel('')
    ylabel('')
    caxis(chl_clim)
    xlim(xrange)

    % Plot 6: rho
    nexttile
    scatter(T,"DateTime","Depth",ColorVariable="rho",Marker=".")
    cb = colorbar;
    ylabel(cb,'kg/m^3')
    set(gca,'Ydir','Reverse')
    title('rho')
    xlabel('')
    ylabel('')
    caxis(rho_clim)
    xlim(xrange)

    % Plot 7: N2
    nexttile
    scatter(T,"DateTime","Depth",ColorVariable="N2",Marker=".")
    cb = colorbar;
    ylabel(cb,'s^-2')
    set(gca,'Ydir','Reverse')
    title('N2: Buoyancy Frequency')
    xlabel('')
    ylabel('')
    caxis(N2_clim)
    xlim(xrange)

    cd(fullfile(folder,'figures'))
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    savefilename = fullfile(folder, 'figures', ['TimeSeries_1Hz_' timestamp '.png']);
    exportgraphics(fig, savefilename, 'Resolution', 150); % Adjust resolution as needed

% PDF
%     % Set up PDF export properties
%     set(fig,'PaperOrientation','portrait');
%     set(fig,'PaperUnits','normalized');
%     set(fig,'PaperPosition', [0 0 1 1]); % fill the page
%     
%     cd(fullfile(folder,'figures'))
%     timestamp = datestr(now, 'yyyymmdd_HHMMSS');
%     savefilename = fullfile(folder, 'figures', ['TimeSeries_1Hz_' timestamp '.pdf']);
%     print(fig, savefilename, '-dpdf', '-fillpage');

end
