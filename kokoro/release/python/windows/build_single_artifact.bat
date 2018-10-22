setlocal

if %PYTHON%==C:\python35_32bit set generator=Visual Studio 14
if %PYTHON%==C:\python35_32bit set vcplatform=Win32

if %PYTHON%==C:\python35 set generator=Visual Studio 14 Win64
if %PYTHON%==C:\python35 set vcplatform=x64

if %PYTHON%==C:\python36_32bit set generator=Visual Studio 14
if %PYTHON%==C:\python36_32bit set vcplatform=Win32

if %PYTHON%==C:\python36 set generator=Visual Studio 14 Win64
if %PYTHON%==C:\python36 set vcplatform=x64

REM Prepend newly installed Python to the PATH of this build (this cannot be
REM done from inside the powershell script as it would require to restart
REM the parent CMD process).
SET PATH=%PYTHON%;%PYTHON%\Scripts;%OLD_PATH%
python -m pip install -U pip
pip install wheel

REM Check that we have the expected version and architecture for Python
python --version
python -c "import struct; print(struct.calcsize('P') * 8)"

rmdir /s/q protobuf
git clone https://github.com/google/protobuf.git

REM Checkout release commit
cd %REPO_DIR%
git checkout %BUILD_COMMIT%
git cherry-pick 0a59054c30e4f0ba10f10acfc1d7f3814c63e1a7

REM ======================
REM Build Protobuf Library
REM ======================

mkdir src\.libs

mkdir vcprojects
pushd vcprojects
cmake -G "%generator%" -Dprotobuf_BUILD_SHARED_LIBS=%BUILD_DLL% -Dprotobuf_UNICODE=%UNICODE% -Dprotobuf_BUILD_TESTS=OFF ../cmake
msbuild protobuf.sln /p:Platform=%vcplatform% /p:Configuration=Release
dir /s /b
popd
copy vcprojects\Release\libprotobuf.lib src\.libs\libprotobuf.a
copy vcprojects\Release\libprotobuf-lite.lib src\.libs\libprotobuf-lite.a
SET PATH=%cd%\vcprojects\Release;%PATH%
dir vcprojects\Release

REM ======================
REM Build python library
REM ======================

cd python

REM sed -i 's/\ extra_compile_args\ =\ \[\]/\ extra_compile_args\ =\ \[\'\/MT\'\]/g' setup.py

python setup.py bdist_wheel --cpp_implementation --compile_static_extension
dir dist
copy dist\* %ARTIFACT_DIR%
dir %ARTIFACT_DIR%
cd ..\..
