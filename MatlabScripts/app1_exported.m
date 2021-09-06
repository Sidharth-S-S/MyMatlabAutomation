classdef app1_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TestrunReplace               matlab.ui.Figure
        SelectTestRunFolderButton    matlab.ui.control.Button
        SelectExcelSheetButton       matlab.ui.control.Button
        ModifyCarMakerTestRunfromanMappingExcelSheetLabel  matlab.ui.control.Label
        DisplayMessageTextAreaLabel  matlab.ui.control.Label
        DisplayMessageTextArea       matlab.ui.control.TextArea
        UITable                      matlab.ui.control.Table
        ShowExcelDataButton          matlab.ui.control.Button
        ReplaceTestRunsButton        matlab.ui.control.Button
        StatusLampLabel              matlab.ui.control.Label
        StatusLamp                   matlab.ui.control.Lamp
        ModifyTableDataButton        matlab.ui.control.Button
    end

    
    properties (Access = private)
        DispMsg % Description
        TRdir % Description
        ExcelFile % Description
        MyDiffData % Description
    end
    
    methods (Access = private)
        
        function Msg = FindExcelContents(app)
            
            % Excel Contents
            opts2 = spreadsheetImportOptions("NumVariables", 3);
            % Specify sheet and range
            opts2.Sheet = "SignalDiff";
            % Specify column names and types
            opts2.VariableNames = ["PreviusSig", "NewSig","ReplaceFlag"];
            opts2.VariableTypes = ["char", "char","char"];
            
            % Import the data
            DiffData = readtable(app.ExcelFile, opts2, "UseExcel", false);
            app.UITable.ColumnName = {'Old Signal'; 'New Signal'; 'ReplaceFlag'};
            app.UITable.Data = DiffData;
            DiffData = table2cell(DiffData);
            [~,c] = size(DiffData);
            Msg = '';
            for i = 1:c
                switch(lower(DiffData{1,i}))
                    case 'previus_signals'
                        app.MyDiffData.Previus_Signals = DiffData(2:end,i);
                    case 'new_signals'
                        app.MyDiffData.New_Signals = DiffData(2:end,i);
                    case 'replace_flag'
                        app.MyDiffData.Replace_Flag = DiffData(2:end,i);
                    case ''
                        Msg = sprintf('The Column : %d does not exist.',i) ;
                        app.DisplayMessageTextArea.FontColor = [1.0, 0 ,0];
                    otherwise
                        Msg = sprintf('The Field :%s is not a Valid One. It should be previus_signals or new_signals or replace_flag.',DiffData{1,i});
                        app.DisplayMessageTextArea.FontColor = [0.69, 0 ,0];
                end
            end
                        
        end
        
        function Msg = ReplaceTestRuns(app)
            %% TestRuns Artefacts :
            TRFiles = dir(app.TRdir) ;
            TRFiles = TRFiles(~ismember({TRFiles.name},{'.','..'}));
            [~,Extensions]=strtok({TRFiles.name},'.');
            if isempty(cell2mat(Extensions)) && ~any([TRFiles.isdir])
                TRFiles = fullfile({TRFiles.folder},{TRFiles.name}) ;
                
                opts = delimitedTextImportOptions("NumVariables", 1);
                opts.Delimiter = "";
                opts.VariableTypes = "char";
                opts.VariableNames = "TestRunContents";
                opts = setvaropts(opts, "TestRunContents", "WhitespaceRule", "preserve");
                
                %% Logic to Modify
                for i = 1:numel(TRFiles)
                    TRContents = readtable(TRFiles{i},opts) ;
                    TRContents = table2cell(TRContents) ;
                    EvalContents = TRContents(contains(TRContents,'Eval ')) ;
                    EvalVars = extractBetween(EvalContents,'Eval ','=')  ;
                    DVAContents = TRContents(contains(TRContents,'DVAwr ')) ;
                    DVAvars = extractBetween(DVAContents,'DVAwr ','Abs ')  ;
                    Vars = [EvalVars;DVAvars];
                    IsSimilar = ismember(strtrim(app.MyDiffData.Previus_Signals),strtrim(Vars))...
                        & strcmp(app.MyDiffData.Replace_Flag,'1');
                    %create Replacement String by Old New and Flag
                    ReplacingData = [app.MyDiffData.Previus_Signals(IsSimilar),...
                        app.MyDiffData.New_Signals(IsSimilar)];
                    TRContentsNew = replace(TRContents,ReplacingData(:,1),ReplacingData(:,2));
                    fid = fopen(TRFiles{i},'w');
                    for j_ = 1:numel(TRContentsNew)
                        fprintf(fid,'%s\n',TRContentsNew{j_});
                    end
                    fclose(fid) ;
                    Msg{i} = sprintf('%s is Modified. \n\n',TRFiles{i}); %#ok<AGROW>
                end
                app.StatusLamp.Color = [0.0,1.0,0.0] ;
                app.DisplayMessageTextArea.FontColor = [0, 0.0 ,0];
            else
                Msg = sprintf ('The Selected TestRun Directory %s has Tests with an Extension. \nCM Test Does not have extension. Please Select Test Run Folder Properly.\n\n. Aborting !!!',app.TRdir) ;
                app.StatusLamp.Color = [1.0,0,0];
                app.DisplayMessageTextArea.FontColor = [0.93,0.69,0.13] ;
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: SelectTestRunFolderButton
        function SelectTestRunFolderButtonPushed(app, event)
            app.TRdir = uigetdir(fullfile(pwd,'..','Data','TestRun'),'Please Select the Correct Test Run Folder');
            if app.TRdir == 0
                % User clicked Cancel
                DispCellTest = "User Did not select any TestRun ." ;
                app.DisplayMessageTextArea.FontColor = [1.0, 0.0 ,0];
                app.StatusLamp.Color = [1.0,0,0];
            else
                DispCellTest = sprintf('Selected TestRun Folder is %s.',app.TRdir) ;
                app.DisplayMessageTextArea.FontColor = [0, 0.0 ,0];
                if ~isempty(app.UITable.Data)
                    app.ReplaceTestRunsButton.Enable = true ;
                end
            end
            app.DisplayMessageTextArea.FontSize = 12 ;
            app.DisplayMessageTextArea.Value = [app.DisplayMessageTextArea.Value;newline;DispCellTest];
        end

        % Button pushed function: SelectExcelSheetButton
        function SelectExcelSheetButtonPushed(app, event)
            app.ExcelFile = uigetfile({'*.xlsx','*.xlx'},'Please Select the Correct Excel Sheet for mapping');
            if app.ExcelFile == 0
                % User clicked Cancel
                DispCell = "The User Clicked Cancel to Select the Excel." ;
                app.ShowExcelDataButton.Enable = false ;
                app.DisplayMessageTextArea.FontColor = [1.0, 0.0 ,0];
                app.StatusLamp.Color = [1.0,0,0];
            else
                DispCellExcel = sprintf("The Selected Excel Sheet for Mapping is %s.\n",app.ExcelFile) ;
                app.DisplayMessageTextArea.FontColor = [0, 0.0 ,0];
                if exist(app.TRdir,"file")==7
                    DispCellTest = sprintf('Selected TestRun Folder is %s.',app.TRdir) ;
                    DispCell = [DispCellExcel;newline;DispCellTest] ;
                else
                    DispCell = DispCellExcel ;
                end
                app.ShowExcelDataButton.Enable = true ;
            end
            app.DisplayMessageTextArea.FontSize = 12 ;
            app.DisplayMessageTextArea.Value = DispCell;
        end

        % Button pushed function: ShowExcelDataButton
        function ShowExcelDataButtonPushed(app, event)
            if exist(app.ExcelFile,"file")==2
                FindExcelContents(app)
                app.StatusLamp.Color = [0.0,1.0,0.0] ;
                app.ModifyTableDataButton.Enable = true;
                if exist(app.TRdir,"file")==7
                    app.ReplaceTestRunsButton.Enable = true ;
                end
            else
                app.DisplayMessageTextArea.Value = [app.DisplayMessageTextArea.Value;newline;'Please Select the Excel Sheet First .!!!'];
                app.StatusLamp.Color = [1.0,0,0];
            end
        end

        % Button pushed function: ReplaceTestRunsButton
        function ReplaceTestRunsButtonPushed(app, event)
            if (exist(app.ExcelFile,"file")==2 && exist(app.TRdir,"file")==7 )
                Msg = ReplaceTestRuns(app) ;
                app.DisplayMessageTextArea.Value = Msg ;
                app.ReplaceTestRunsButton.Enable = false ;
                app.ShowExcelDataButton.Enable = false ;
                app.ModifyTableDataButton.Enable = false ;
            else
                app.DisplayMessageTextArea.Value = [app.DisplayMessageTextArea.Value;newline;'Please Select the Test Runs and Excel Sheet First .!!!'];
                app.StatusLamp.Color = [1.0,0.0,0.0] ;
            end
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            indices = event.Indices;
            newData = event.NewData;
            switch indices(2)
                case 1
                    app.MyDiffData.Previus_Signals{indices(1)-1} = newData ;
                case 2
                    oldData = app.MyDiffData.New_Signals{indices(1)-1};
                    app.MyDiffData.New_Signals{indices(1)-1} = newData ;
                    app.DisplayMessageTextArea.Value = sprintf('The New Signal is changed from %s to %s.',oldData,newData);
                case 3
                    oldData = app.MyDiffData.Replace_Flag{indices(1)-1};
                    app.MyDiffData.Replace_Flag{indices(1)-1} = newData ;
                    app.DisplayMessageTextArea.Value = sprintf('Replace Flag for The Signal %s is changed from %s to %s.',app.MyDiffData.Previus_Signals{indices(1)-1},oldData,newData);
            end
            app.StatusLamp.Color = [0.93,0.69,0.1];
        end

        % Button pushed function: ModifyTableDataButton
        function ModifyTableDataButtonPushed(app, event)
            app.UITable.ColumnEditable = [false true true];
            app.StatusLamp.Color = [0.93,0.69,0.13] ;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create TestrunReplace and hide until all components are created
            app.TestrunReplace = uifigure('Visible', 'off');
            app.TestrunReplace.Position = [100 100 1096 720];
            app.TestrunReplace.Name = 'UI Figure';

            % Create SelectTestRunFolderButton
            app.SelectTestRunFolderButton = uibutton(app.TestrunReplace, 'push');
            app.SelectTestRunFolderButton.ButtonPushedFcn = createCallbackFcn(app, @SelectTestRunFolderButtonPushed, true);
            app.SelectTestRunFolderButton.FontName = 'Bell MT';
            app.SelectTestRunFolderButton.FontSize = 14;
            app.SelectTestRunFolderButton.FontWeight = 'bold';
            app.SelectTestRunFolderButton.Position = [646 614 153 26];
            app.SelectTestRunFolderButton.Text = 'Select TestRun Folder';

            % Create SelectExcelSheetButton
            app.SelectExcelSheetButton = uibutton(app.TestrunReplace, 'push');
            app.SelectExcelSheetButton.ButtonPushedFcn = createCallbackFcn(app, @SelectExcelSheetButtonPushed, true);
            app.SelectExcelSheetButton.FontName = 'Bell MT';
            app.SelectExcelSheetButton.FontSize = 14;
            app.SelectExcelSheetButton.FontWeight = 'bold';
            app.SelectExcelSheetButton.Position = [21 614 128 26];
            app.SelectExcelSheetButton.Text = 'Select Excel Sheet';

            % Create ModifyCarMakerTestRunfromanMappingExcelSheetLabel
            app.ModifyCarMakerTestRunfromanMappingExcelSheetLabel = uilabel(app.TestrunReplace);
            app.ModifyCarMakerTestRunfromanMappingExcelSheetLabel.FontName = 'Modern No. 20';
            app.ModifyCarMakerTestRunfromanMappingExcelSheetLabel.FontSize = 20;
            app.ModifyCarMakerTestRunfromanMappingExcelSheetLabel.FontWeight = 'bold';
            app.ModifyCarMakerTestRunfromanMappingExcelSheetLabel.FontColor = [0 0 1];
            app.ModifyCarMakerTestRunfromanMappingExcelSheetLabel.Position = [296 675 489 22];
            app.ModifyCarMakerTestRunfromanMappingExcelSheetLabel.Text = 'Modify CarMaker TestRun from an Mapping ExcelSheet';

            % Create DisplayMessageTextAreaLabel
            app.DisplayMessageTextAreaLabel = uilabel(app.TestrunReplace);
            app.DisplayMessageTextAreaLabel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.DisplayMessageTextAreaLabel.HorizontalAlignment = 'right';
            app.DisplayMessageTextAreaLabel.FontName = 'Bell MT';
            app.DisplayMessageTextAreaLabel.FontSize = 14;
            app.DisplayMessageTextAreaLabel.Position = [832 532 102 22];
            app.DisplayMessageTextAreaLabel.Text = 'Display Message';

            % Create DisplayMessageTextArea
            app.DisplayMessageTextArea = uitextarea(app.TestrunReplace);
            app.DisplayMessageTextArea.HorizontalAlignment = 'center';
            app.DisplayMessageTextArea.FontName = 'Bell MT';
            app.DisplayMessageTextArea.FontWeight = 'bold';
            app.DisplayMessageTextArea.Position = [707 74 351 429];

            % Create UITable
            app.UITable = uitable(app.TestrunReplace);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'};
            app.UITable.RowName = {};
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.FontName = 'Times New Roman';
            app.UITable.FontSize = 10;
            app.UITable.Position = [21 74 642 428];

            % Create ShowExcelDataButton
            app.ShowExcelDataButton = uibutton(app.TestrunReplace, 'push');
            app.ShowExcelDataButton.ButtonPushedFcn = createCallbackFcn(app, @ShowExcelDataButtonPushed, true);
            app.ShowExcelDataButton.FontName = 'Bell MT';
            app.ShowExcelDataButton.FontSize = 14;
            app.ShowExcelDataButton.FontWeight = 'bold';
            app.ShowExcelDataButton.Enable = 'off';
            app.ShowExcelDataButton.Position = [220 614 126 26];
            app.ShowExcelDataButton.Text = 'Show Excel Data';

            % Create ReplaceTestRunsButton
            app.ReplaceTestRunsButton = uibutton(app.TestrunReplace, 'push');
            app.ReplaceTestRunsButton.ButtonPushedFcn = createCallbackFcn(app, @ReplaceTestRunsButtonPushed, true);
            app.ReplaceTestRunsButton.FontName = 'Bell MT';
            app.ReplaceTestRunsButton.FontSize = 14;
            app.ReplaceTestRunsButton.FontWeight = 'bold';
            app.ReplaceTestRunsButton.Enable = 'off';
            app.ReplaceTestRunsButton.Position = [879 614 126 26];
            app.ReplaceTestRunsButton.Text = 'Replace TestRuns';

            % Create StatusLampLabel
            app.StatusLampLabel = uilabel(app.TestrunReplace);
            app.StatusLampLabel.HorizontalAlignment = 'right';
            app.StatusLampLabel.FontName = 'Bell MT';
            app.StatusLampLabel.FontSize = 16;
            app.StatusLampLabel.FontWeight = 'bold';
            app.StatusLampLabel.Position = [499 561 49 22];
            app.StatusLampLabel.Text = 'Status';

            % Create StatusLamp
            app.StatusLamp = uilamp(app.TestrunReplace);
            app.StatusLamp.Position = [563 562 20 20];
            app.StatusLamp.Color = [0.9294 0.6902 0.1294];

            % Create ModifyTableDataButton
            app.ModifyTableDataButton = uibutton(app.TestrunReplace, 'push');
            app.ModifyTableDataButton.ButtonPushedFcn = createCallbackFcn(app, @ModifyTableDataButtonPushed, true);
            app.ModifyTableDataButton.FontName = 'Bell MT';
            app.ModifyTableDataButton.FontSize = 14;
            app.ModifyTableDataButton.FontWeight = 'bold';
            app.ModifyTableDataButton.Enable = 'off';
            app.ModifyTableDataButton.Position = [423 614 136 26];
            app.ModifyTableDataButton.Text = 'Modify Table Data ';

            % Show the figure after all components are created
            app.TestrunReplace.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.TestrunReplace)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TestrunReplace)
        end
    end
end