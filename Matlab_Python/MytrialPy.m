PE = pyenv ; 
%PythonEnvironment with properties:
%
 %         Version: "3.7"
  %     Executable: "C:\Users\tss1kor\.conda\envs\onnx_client\python.exe"
   %       Library: "C:\Users\tss1kor\.conda\envs\onnx_client\python37.dll"
    %         Home: "C:\Users\tss1kor\.conda\envs\onnx_client"
     %      Status: Loaded
%    ExecutionMode: InProcess
 %       ProcessID: "17560"
  %    ProcessName: "MATLAB"
    
pe = pyenv;
if pe.Status == 'Loaded'
    disp('To change the Python version, restart MATLAB, then call pyenv('Version','2.7').')
else
    pyenv('Version','2.7');
end

kk = py.list({'Monday','Tuesday','Wednesday','Thursday','Friday'});

%%%%%%%%%%%%%%%%%%%%  Python Exception in MATLAB during feeding data %%%%%%%%%%%%%%%%%%
try
  py.list('x','y',1) %To create multiobject data from MATLAB we need to use this syntax 
catch e
  e.message
  if(isa(e,'matlab.exception.PyException'))
    e.ExceptionObject
  end
end


%The syntax to create a Python® object pyObj is:
pyObj = py.modulename.ClassName(varargin)
%where varargin is the list of constructor arguments specified by the __init__ method in ClassName.

In MATLAB®, Python objects are reference types (handle objects) and do not adhere to the MATLAB copy-on-assignment and pass-by-value rules. 
When you copy a handle object, only the handle is copied and both the old and new handles refer to the same data. 
When you copy a MATLAB variable (a value object), the variable data is also copied. The new variable is independent of changes to the original variable.

The following example creates an object of the TextWrapper class in the Python standard library textwrap module. Read the constructor signature, __init__.

py.help('textwrap.TextWrapper.__init__')
  
Help on method __init__ in textwrap.TextWrapper:   textwrap.TextWrapper.__init__ = __init__(self, width=70, initial_indent='', subsequent_indent='', expand_tabs=True, replace_whitespace=True, fix_sentence_endings=False, break_long_words=True, drop_whitespace=True, break_on_hyphens=True) unbound textwrap.TextWrapper method
Create a default TextWrapper object. You do not need to pass any input arguments because each argument has a default value, identified by the equal sign (=) character.

tw = py.textwrap.TextWrapper;
tw = 
  Python TextWrapper with properties:

                    width: 70
        subsequent_indent: [1x1 py.str]
    wordsep_simple_re_uni: [1x1 py._sre.SRE_Pattern]
     fix_sentence_endings: 0
         break_on_hyphens: 1
         break_long_words: 1
           wordsep_re_uni: [1x1 py._sre.SRE_Pattern]
           initial_indent: [1x1 py.str]
              expand_tabs: 1
       replace_whitespace: 1
          drop_whitespace: 1
<textwrap.TextWrapper instance at 0x000000006D58F808>

To change a logical value, for example, the break_long_words property, type:
tw.break_long_words = 0;
To change a numeric value, for example, the width property, first determine the numeric type.
class(tw.width)
ans = int64
By default, when you pass a MATLAB number to a Python function, Python reads it as a float. If the function expects an integer, Python might throw an error or produce unexpected results. 
Explicitly convert the MATLAB number to an integer. For example, type:

tw.width = int64(3);
Read the help for the wrap method.

py.help('textwrap.TextWrapper.wrap')
Help on method wrap in textwrap.TextWrapper:

textwrap.TextWrapper.wrap = wrap(self, text) unbound textwrap.TextWrapper method
wrap(text : string) -> [string]
Reformat the single paragraph in 'text' so it fits in lines of
no more than 'self.width' columns, and return a list of wrapped
lines.  Tabs in 'text' are expanded with string.expandtabs(),
and all other whitespace characters (including newline) are
converted to space.  Create a list of wrapped lines, w, from input T.

  
T = 'MATLAB® is a high-level language and interactive environment for numerical computation, visualization, and programming.';
w = wrap(tw,T);
whos w
  Name      Size            Bytes  Class      Attributes

  w         1x1               112  py.list   
Convert the py.list to a cell array and display the results.

wrapped = cellfun(@char, cell(w), 'UniformOutput', false);
fprintf('%s\n', wrapped{:})
MATLAB®
is
a
high-
level
language
and
interactive
environment
for
numerical
computation,
visualization,
and
programming.

Although width is 3, setting the break_long_words property to false overrides the width value in the display.
