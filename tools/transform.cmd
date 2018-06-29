@echo off 
setlocal

@rem  This script uses the Apache Xalan 2.7.1 XSLT processor
@rem  For a description of Xalan command-line parameters see http://xalan.apache.org/xalan-j/commandline.html
@rem
@rem  Prerequisites
@rem  - Java SE is installed and in the PATH - download from http://www.oracle.com/technetwork/java/javase/downloads/index.html 
@rem  - git is installed and in the PATH - download from https://git-for-windows.github.io/
@rem  - Xalan is installed and CLASSPATH contains xalan.jar and serializer.jar - download from http://xalan.apache.org/xalan-j/downloads.html
set CLASSPATH=%XALAN_HOME%/xalan.jar;%XALAN_HOME%/serializer.jar
@rem    Alternative: Xalan is installed and CLASSPATH contains xalan.jar and serializer.jar - download from http://xalan.apache.org/xalan-j/downloads.html
@rem set CLASSPATH=<path to Xalan>/xalan.jar;<path to Xalan>/serializer.jar
@rem  - YAJL's json_reformat from https://github.com/lloyd/yajl has been compiled and is in the PATH
@rem  - Node.js is installed - download from https://nodejs.org/
@rem  - ajv-cli is installed - npm install -g ajv-cli

set done=false
set here=%~dp0

for %%F in (%*) do (
  call :process %%F
)

if [%*] == [] (
  echo Usage: transform [FILE]...
) 

endlocal
exit /b


:process
  echo %1
  
  java.exe org.apache.xalan.xslt.Process -L -XSL %here%V4-CSDL-to-JSONSchema.xsl -IN %1 -OUT %~dpn1.tmp.json

  json_reformat.exe < %~dpn1.tmp.json > %~dpn1.schema.json
  if not errorlevel 1 (
    del %~dpn1.tmp.json
    
    git.exe --no-pager diff %~dpn1.schema.json
    
    call ajv -s %here%odata-meta-schema.json -d %~dpn1.schema.json > nul
  )
exit /b