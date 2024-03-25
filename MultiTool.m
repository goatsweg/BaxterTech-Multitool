%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This function contains the entire program code for the BaxterTech
%  MultiTool MATLAB edition version 0.1
%
%  Author: Trey Baxter
%  Date: 3/25/2024
%
%  To Do List:
%     - Finish shelving layout
%     - add adjustable rectangles for shelf layout design
%     - add settings to change decay time (time for an entry to get culled)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function boxSelector()
    
    clear; clc;
    
    % set selected row indices to 1 to make it global variable(bad way to 
    % do this, but oh well)
    selectedIndex = 1;
    
    % Define the data file name
    fileName = 'expiration.csv';
    shelfFile = 'shelves.csv';
    
    % check if the file containing the shelf locations exists. If it does
    % not, then create a new shelf file with a filler shelf. MATLAB's
    % exist() function can be slow, better validation would be nice
    if exist(shelfFile, 'file')
        shelfData = readtable(shelfFile);
    else
        % commented to remove chance of overwriting shelf file, I don't
        % trust MATLAB
        
        %{
        shelfData = [.1, .1, .2, .2, "Sample"];
        startX = .1;
        startY = .1;
        widths = .2;
        heights = .2;
        label = "sample";
        shelfData = table(startX, startY, widths, heights, label);
        %}
    end
    
    % Check if the expirations data file exists
    if exist(fileName, 'file')
        % Load data from the CSV file
        dataMatrix = readtable(fileName);
        
        % initialize shelf structure
        shelf = struct();
        
        % set N to the number of shelves
        N = height(shelfData.startX);
        
        % Iterate over each shelf
        for i = 1:N
            % Get the entries related to the shelf in question
            rows = dataMatrix(dataMatrix.ID == i, :);
            
            % set variable that tracks which values to kill
            killrow = [];
            
            % check if there is at least 2 entries and then kills all
            % entries over 60 days. If you have 2 over 60 days it will kill
            % both, but this shouldn't come up often or be a problem
            for k = 1:height(rows)
                if (datetime("today") - rows.Date(k) > 60 ...
                        && height(rows) > 1)
                    killrow = [killrow; k];
                end
            end
            % kill the rows
            rows(killrow,:) = [];
            % Assign the remaining expiration date entries to a shelf
            % structure field unique to each shelf
            shelf.(sprintf('ID%d', i)) = rows;
        end

    else
        % Create a new data file in the event that the desired one did not
        % exist
        ID = 1;
        Name = "John Doe";
        Date = "2000-01-01";
        dataMatrix = table(ID, Name, Date);
    end

    % get screen size (1 x 4 array with [left, bottom, width, height])
    screenSize = get(groot, 'Screensize');
    box_id = 1;
    
    % store standard screen size measurements
    thirdScreen = screenSize ./ 3;
    halfScreen = screenSize ./ 2;
    
    shelfDataPos = [2 * thirdScreen(3) * shelfData.startX,...
        screenSize(4) * shelfData.startY, 2 * thirdScreen(3) * shelfData.widths,...
        screenSize(4) * shelfData.heights]

    % Create the main figure window
    fig = uifigure;
    uiFig.Position = screenSize;
    % Set Resize property to 'off'
    uiFig.Resize = 'off';
    drawnow;

    % Create a panel on the left side for box selection
    panelLeft = uipanel(fig, 'Position', ...
                              [10, 10, 2 * thirdScreen(3), screenSize(4)]);

    % Initialize unique IDs for each box
    boxIDs = 1:N;
    numBoxes = numel(boxIDs);

    % Create buttons for box selection
    %{
    for i = 1:numBoxes
        uibutton(panelLeft, 'Text', ['Box ', num2str(i)], ...
            'Position', [10, 400 - 40*i, 100, 30], ...
            'Tag', num2str(boxIDs(i)), ...
            'ButtonPushedFcn', {@boxSelected, boxIDs(i)});
    end
    %}
    
    for k = 1:numBoxes
        uibutton(panelLeft, 'Text', shelfData.label(k), ...
            'Position', shelfDataPos(k,:), ...
            'Tag', num2str(boxIDs(k)), ...
            'ButtonPushedFcn', {@boxSelected, boxIDs(k)});
    end

    % Create a panel on the right side for displaying selected data
    panelRight = uipanel(fig, 'Position', ...
           [20+2 * thirdScreen(3), 10, thirdScreen(3), screenSize(4)]);

    % Create a table for displaying selected data
    dataTable = uitable(panelRight, 'Units', 'normalized', 'Position', ...
        [.05, .6, .8, .25], ...
        'ColumnName', {'Name', 'Date'}, ...
        'ColumnWidth', {thirdScreen(3)*.4, thirdScreen(3)*.4}, ...
        'ColumnEditable', false, 'SelectionType', 'row',...
        'CellSelectionCallback', @onCellSelection);
    
    % Create a button for removing data
    removeButton = uibutton(panelRight, 'Text', 'Remove Entry', ...
        'Position', [thirdScreen(3) * .23, screenSize(4) * .54, ...
        thirdScreen(3) * 1/6, screenSize(4) * 1/20], ...
        'ButtonPushedFcn', @removeData);

    % Create a button for adding entries
    addEntryButton = uibutton(panelRight, 'Text', 'Add Entry', ...
        'Position', [thirdScreen(3) * .05, screenSize(4) * .54, ...
        thirdScreen(3) * 1/6, screenSize(4) * 1/20], ...
        'ButtonPushedFcn', @addEntry);

    updateDataFile();
    
    function onCellSelection(~, event)
        selectedIndex = event.Indices(1);
    end
    
    % Callback function for box selection
    function boxSelected(~, ~, boxID)
        % Update the table with selected data
        if isfield(shelf, sprintf('ID%d', boxID))
            dataTable.Data = [shelf.(sprintf('ID%d', boxID)).Name,...
                          string(shelf.(sprintf('ID%d', boxID)).Date)];
        else
            dataTable.Data = [];
        end
        
        % used to track current box ID for data entry
        box_id = boxID;
    end

    % Callback function for adding entries
    function addEntry(~, ~)
        % Prompt the user for a name
        inputName = inputdlg('Enter a name:', 'Name', 1);
        if isempty(inputName)
            return; % Exit if the user cancels
        end
        %name = name{1}; % Extract name from cell array

        % Prompt the user for a date (autofilled with today's date)
        defaultDate = datestr(now, 'yyyy-mm-dd');
        inputDate = inputdlg('Enter a date (yyyy-mm-dd):', 'Date', 1, {defaultDate});
        if isempty(inputDate)
            return; % Exit if the user cancels
        end
        %date = date{1}; % Extract date from cell array

        % Append the new entry to the data matrix
        shelf.(sprintf('ID%d', box_id)) = [shelf.(sprintf('ID%d', box_id));...
        {box_id, inputName, inputDate}];
    
        % sort data by date
        %{
        shelf.(sprintf('ID%d', i)) = sortrows(shelf.(sprintf('ID%d', i)), ...
                shelf.(sprintf('ID%d', i)).Date);
        %}
        
        % Update the original data file
        updateDataFile();
        dataTable.Data = [shelf.(sprintf('ID%d', box_id)).Name,...
                          string(shelf.(sprintf('ID%d', box_id)).Date)];
    end

    % Callback function for removing data
    function removeData(~, ~)

        % Prompt the user for confirmation
        choice = questdlg('Are you sure you want to remove the selected entry?', ...
            'Remove Data', ...
            'Yes', 'No');

        % Handle user response
        if strcmp(choice, 'Yes')
            % Remove the selected row(s) from the data matrix
            shelf.(sprintf('ID%d', box_id))(selectedIndex, :) = [];
            dataTable.Data = [shelf.(sprintf('ID%d', box_id)).Name,...
                          string(shelf.(sprintf('ID%d', box_id)).Date)];

            % Update the original data file
            updateDataFile();
        end
    end

    % Function to update the original data file
    function updateDataFile()
        saveMatrix = [];
        % Write the data matrix to the CSV file
        for i = 1:length(shelfData.widths)
            % concatenates together each of the shelf structure fields
            saveMatrix = [saveMatrix; shelf.(sprintf('ID%d', i))];
            
            % finds button associated with current iteration
            desiredButton = findobj(panelLeft, 'Tag', num2str(i))
            
            % update color as required
            if datetime("today") - max(shelf.(sprintf('ID%d', i)).Date) < 30
                desiredButton.BackgroundColor = [0, 0.7, 0];
            else
                desiredButton.BackgroundColor = [0.7, 0, 0];
            end
                
        end
        writetable(saveMatrix, fileName);
    end


end
