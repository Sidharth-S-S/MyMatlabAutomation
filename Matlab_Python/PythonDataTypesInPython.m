% Use Python str Type in MATLAB . This example shows how to use the Python® path separator character (;). In MATLAB®, a Python character is a py.str variable.
p = py.os.path.pathsep
% MATLAB uses the same path separator character, ;.
c = pathsep
isequal(class(p),class(c))
Convert p to a MATLAB type and append the character to a file name.
f = ['myfile' char(p)]

%% OS Commands MATLAB ; import OS in Python
% py.os.name  ;; nt : Windows
% py.os.linesep
% py.os.chdir
% py.os.getcwd
% py.os.listdir
% py.os.mkdir
% py.os.rename
% py.os.rmdir
% py.os.system
% py.os.getpid
% py.os.waitpid
% py.os.getlogin
% py.os.kill
% py.os.open
% py.os.close
% py.os.read
% py.os.write
% py.os.cpu_count
% py.os.F_OK / R_OK / W_OK
% py.os.error
% py.os.makedirs / removedirs
% py.os.sep
% py.os.pathsep
% py.os.curdir
% py.os.getenv


%% Python Data Types in MATLAB 
% Index into Python String ; compares indexing into a MATLAB® character vector with indexing into the Python variable.
str = 'myfile';
str(1)
  
pstr = py.str(str);
pstr(1)
  
%% Pass MATLAB Backslash Control Character(\) 
%Insert the new line control character \n by calling the MATLAB® sprintf function. Python replaces \n with a new line.
py.str(sprintf('The rain\nin Spain.'))

  O/P : 
  The rain
  in Spain.
    
%Without the sprintf function, both MATLAB and Python interpret \ as a literal backslash.
py.str('The rain\nin Spain.')
O/P: 
The rain\nin Spain.    

  %Pass this string to a Python string method split. Python treats the MATLAB character vector as a raw string and adds a \ character to preserve the original backslash.
split(py.str('The rain\nin Spain.'))

  O/p:     ['The', 'rain\\nin', 'Spain.']

%% Create Python list Variable
students = py.list({'Robert','Mary','Joseph'})
n = py.len(students)

%Use Python List of Numeric Types in MATLAB
%This example shows how to convert a Python® list of numeric values into a MATLAB® array of double.
%A Python list contains elements of any type and can contain elements of mixed types. 
%The MATLAB double function used in this example assumes that all elements of the Python list are numeric.

P = py.list({int32(1), int32(2), int32(3), int32(4)})
class(P{1})
cP = cell(P);
A = cellfun(@double,cP)

%%Index into Python List
C = {1,2,3,4};
n = C(end);
n = C{end}
%By default if we do not provide the data type while feeding in , Python automatically accepts as float and then shows the data as   1.0 , 2.0 ,3.0,4.0
li = py.list(C)
n = li(end)
n = li{end}
  
%%Use Python List as Values in for Loop
li = py.list({1,2,3,4});
for n = li
    disp(n{1})
end

%%Nested List
matrix = py.list({{1, 2, 3, 4},{'hello','world'},{9, 10}});
disp(char(matrix{2}{2}))
  
%%Display Stepped Range of Python Elements .  in Python is start:stop:step. In MATLAB®, the syntax is of the form start:step:stop. 
li = py.list({'a','bc',1,2,'def'});
li(1:2:end)

%%Create Python tuple Variable
student = py.tuple({'Robert',19,'Biology'})
%%Index into Python Tuple
t = py.tuple({'a','bc',1,2,'def'});
t(1:2)
mt = cell(t)
mt{2}

%%Create Singleton Python tuple Variable
subject = py.tuple({'Biology'})
  
%%Create Python dict Variable
studentID = py.dict(pyargs('Robert',357,'Mary',229,'Jack',391))
%%Index into Python dict
customers = py.dict
%Populate the dict variable with customer names and account numbers and display the results. The output depends on your Python® version.
customers{'Smith'} = int32(2112);
customers{'Anderson'} = int32(3010);
customers{'Audrey'} = int32(4444);
customers{'Megan'} = int32(5000);
customers

Read the account number for customer Anderson.
acct = customers{'Anderson'}

Convert to a MATLAB variable.
C = struct(customers)
acct = C.Anderson

%%Pass dict Argument to Python Method
menu = py.dict(pyargs('soup',3.57,'bread',2.29,'bacon',3.91,'salad',5.00));
update(menu,py.dict(pyargs('bread',2.50)))
menu

%%Use Python Numeric Types in MATLAB
pynum = py.math.radians(90)
% py.math.isnan
% py.math.acos
% py.math.acosh
% py.math.asin
% py.math.atan
% py.math.exp
% py.zip
% py.enumerate
% py.bool
% py.len
% py.filter
% py.map
% py.set
% py.format

%%Call Python Methods with Numeric Arguments
load patients.mat
class(Height)
size(Height)
%% Transform Height to a 1-by-N matrix before calling fsum.
py.math.fsum(Height')
             
%%Call Methods on Python Variables
P = py.sys.path;
methods(P)
py.help('list.append')
append(P,pwd)
Add the current folder to the end of the path.
append(P,pwd)
%%Display the number of folders on the path. The list has py.len elements. Your value might be different. The type of this number is py.int.
py.len(P)
             
%% Call Python eval Function
Read the help for eval.
py.help('eval')
%Create a Python dict variable for the x and y values.
workspace = py.dict(pyargs('x',1,'y',6))
%Evaluate the expression.
res = py.eval('x+y',workspace)
%Add two numbers without assigning variables. Pass an empty dict value for the globals parameter.
res = py.eval('1+6',py.dict)
