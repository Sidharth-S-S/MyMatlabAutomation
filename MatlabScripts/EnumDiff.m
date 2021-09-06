function out= get_enum_match_list(enum_psl_folder, enum_omcl_folder, excelfilename)
%   GET_ENUM_MATCH_LIST creates and excel sheet by name excelfilename (file name with extension) with
%   the list of enumeration file names in PSL folder in Column A1 of Sheet 1 and
%   the list of enumeration file names in OMCL folder (which matches the
%   enumeration name in PSL) in Column B.It also returns 'out' which
%   contains the same results in structure format.
%
%   OUT = GET_ENUM_MATCH_LIST(enum_psl_folder, enum_omcl_folder,
%   excelfilename) returns the results in a stucture with the following
%   fields.
%       psl    -- List of enums used in psl
%       omcl    -- List of enums used in OMCL (each entry of the list is a
%       cell array.
%       omclchar   -- List of enums used in OMCL (each entry of the list is a
%       character array separated by spaces.


%Check if a last report exists. If so, delete the same

if exist (fullfile(cd,excelfilename),'file') ==2
    delete(fullfile(cd,excelfilename));
end

%Check if the file still exists. If so ,it could be because it might be
%already opened.Need to issue an error to close the last report and run the
%script again
if exist (fullfile(cd,excelfilename),'file') ==2
    error(['Could not delete the file in the path ' fullfile(cd,excelfilename) '.This may be because the file is already opened in another session.Please close the file and execute the script.The script will create a new report every time it is executed.']);
end


%Check if a last Enumfiles_different.txt exists. If so, delete the same

if exist (fullfile(cd,'Enumfiles_different.txt'),'file') ==2
    delete(fullfile(cd,'Enumfiles_different.txt'));
end

%Check if the file still exists. If so ,it could be because it might be
%already opened.Need to issue an error to close the last report and run the
%script again
if exist (fullfile(cd,'Enumfiles_different.txt'),'file') ==2
    error(['Could not delete the file in the path ' fullfile(cd,'Enumfiles_different.txt') '.This may be because the file is already opened in another session.Please close the file and execute the script.The script will create a new report every time it is executed.']);
end


if exist (fullfile(cd,'New'),'dir') ==7
    rmdir(fullfile(cd,'New'),'s');
end

%Check if the 'New' folder still exists. If so ,it could be because it might be
%already opened.Need to issue an error to close the last report and run the
%script again
if exist (fullfile(cd,'New'),'dir') ==7
    error(['Could not delete the folder in the path ' fullfile(cd,'New') '.This may be because one of the files in the folder may be already opened in another session.Please close the file and execute the script.The script will create a ''New'' folder every time it is executed.']);
end



psl_folder_contents= dir(fullfile(enum_psl_folder,'*.m'));
psl_file_names = {psl_folder_contents.name};
omcl_folder_contents=dir(fullfile(enum_omcl_folder,'*.m'));
omcl_file_names = {omcl_folder_contents.name};

%Get the names of the psl contents
count1 = 0;

for psl_file_count = 1:length(psl_file_names)
    count1 = count1+1;
    count2=0;
    for omcl_file_count = 1:length(omcl_file_names)
        
        if ~isempty(strfind(omcl_file_names{omcl_file_count},psl_file_names{psl_file_count}))
            
            %Match found
            matchlist(count1).psl = psl_file_names{psl_file_count};
            
            fldnames = fieldnames(matchlist(count1));
            if isempty(cell2mat(strfind(fldnames,'omcl')))
                matchlist(count1).omcl=  [];
            end
            count2 = count2+1;
            matchlist(count1).omcl{count2} = omcl_file_names{omcl_file_count}; %#ok<*AGROW>
        end
    end
end

out =matchlist;
out.psl;
matched_psl = {out.psl};
matched_omcl = {out.omcl};

%Update the each cell array in the matched_omcl to a character array
%separated by spaces.
count = 0;
for matched_omcl_count= 1:length(matched_omcl)
    
    matched_omcl_indiv= matched_omcl(matched_omcl_count);
    matched_omcl_indiv_char=[];
    for matched_omcl_indiv_count = 1:length(matched_omcl_indiv{1})
        matched_omcl_indiv_char = [matched_omcl_indiv_char sprintf('\n %s',matched_omcl_indiv{1}{matched_omcl_indiv_count})];
    end
    count = count +1 ;
    matched_omcl_indiv_char_array{count} = matched_omcl_indiv_char;
end
matched_omcl_char = matched_omcl_indiv_char_array;


%Write the result to the excel file.
xlswrite(excelfilename,matched_psl','Sheet1','A1');
xlswrite(excelfilename,matched_omcl_char','Sheet1','B1');

%Create separate folder with the enumerations to help developer to easily
%compare the enum values used.

matched_psl_1 = {matched_psl};
matched_omcl_1 = {matched_omcl};


for count = 1:length(matched_psl_1{1})
    
    %Create a folder of the same name as m file
    fname= strtok(matched_psl_1{1}{count},'.');
    newdirname= fullfile('New',fname);
    mkdir(newdirname);
    
    %Copy the enum file from enum_psl_folder to new directory created.
    copyfile(fullfile(enum_psl_folder,[fname '.m']), fullfile(cd,newdirname,[fname '.m']),'f');
    
    
    %Copy the corresponding enum file from OMCL to the respective folder.By
    %this way comparison with beyond control is easy.
    
    for matched_omcl_count= 1:length(matched_omcl_1{1}{count})
        copyfile(fullfile(enum_omcl_folder,[matched_omcl_1{1}{count}{matched_omcl_count}]), fullfile(cd,newdirname,[matched_omcl_1{1}{count}{matched_omcl_count}]),'f');
    end
    
end

%Lets now do a comparison of enumeration texts for each folder in the 'New'
%folder and undrstand if the enumeration definitions are different.


%Read the new folder.
new_folder_name = fullfile(cd,'New');
new_folder_names = dir(new_folder_name);
enum_diff_count = 1;
enum_diff_list = [];

for count =1:length(new_folder_names)
    if strcmp(new_folder_names(count).name,'.') || strcmp(new_folder_names(count).name,'..')
        
        continue;
    else
        
        %Read the contents of each folder and see if the enumeration definition is different.
        
        each_subfolder_m_files = dir(fullfile(new_folder_name,new_folder_names(count).name,'*.m'));
        each_subfolder_m_files = {each_subfolder_m_files.name};
        desc_count =1;
        subfolder_mfile_enum_desc_list=[];
        for subfolder_mfile_count = 1:length(each_subfolder_m_files)
            
            subfolder_mfile_path = fullfile(new_folder_name,new_folder_names(count).name,each_subfolder_m_files(subfolder_mfile_count)) ;
            subfolder_mfile_enum_desc_list{desc_count} = get_enum_text(cell2mat(subfolder_mfile_path));
            desc_count = desc_count+1;
        end
        
        %Check if the enumeration is different. If yes , we need to revisit
        %the same
        
        y = checksame(subfolder_mfile_enum_desc_list);
        if y==0
            %This means the enumerations are different.We need to list the
            %same down.
            enum_diff_list{enum_diff_count} = new_folder_names(count).name;
            enum_diff_count = enum_diff_count+1;
        end
    end
end

enum_diff_list_char = [];
for count = 1:length(enum_diff_list)
    enum_diff_list_char = [enum_diff_list_char sprintf('%s \n',enum_diff_list{count})];
end

fid_enum_diff= fopen('Enumfiles_different.txt','w+');
if ~isempty(enum_diff_list_char)
    
    enum_diff_list_char = [sprintf('The following enumerations from existing PSL are different:\n') enum_diff_list_char];
    fwrite(fid_enum_diff,enum_diff_list_char);
else
    fwrite(fid_enum_diff,'No enums are found to be different');
end

fclose(fid_enum_diff);

if exist(fullfile(cd,excelfilename),'file')== 2 && exist(fullfile(cd,'Enumfiles_different.txt'),'file')==2
    
    out=[];
    out.psl =matched_psl;
    out.omcl = matched_omcl;
    out.omclchar = matched_omcl_char;
    disp(['Completed the analysis.Please refer ' fullfile(cd,excelfilename) ' for the matching enum files betweeen PSL and OMCL',...
        ' .Please refer' fullfile(cd,'Enumfiles_different.txt') ' for the list of enumerations which are different from the existing PSL'])
    
else
    out=-1;
    disp('Error: The matching enum excel report and Enumfiles_different.txt cannot be generated');
    
end




function out= get_enum_text(enum_file_name)

[fid , ~] = fopen(enum_file_name,'r');
C= textscan(fid,'%s','Delimiter', '\t');
fclose(fid);
enum_text = [];
collect_text_flag=0;

for count= 1:length(C{1})
    
    if strcmp(C{1}{count},'enumeration')
        collect_text_flag=1;
        enum_text= [enum_text C{1}{count}]; %#ok<*AGROW>
        
    else
        if collect_text_flag==1
            enum_text= [enum_text C{1}{count}];
        end
    end
    
end

out= enum_text;


function y = checksame(x)

y = true;
num = numel(x);
for i = 1:num
    for j = 1:num
        if i~=j
            if ~isequal(x{i},x{j})
                y = false;
                return;
            end
        end
    end
end
