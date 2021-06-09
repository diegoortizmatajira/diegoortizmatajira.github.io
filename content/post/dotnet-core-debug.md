---
title: "Debugging a .Net Core application running in a Docker container, using VS Code"
date: 2017-09-02T15:51:08-05:00
description: "Describes how to enable debugging a .Net Core from VsCode while running on docker" 
featured: true 
draft: false 
toc: true 
# menu: main
#featureImage: "/images/path/file.jpg" 
#thumbnail: "/images/path/thumbnail.png" 
#shareImage: "/images/path/share.png" 
codeMaxLines: 10 
codeLineNumbers: false 
figurePositionShow: true 
categories:
- Development
tags:
- Docker
- CSharp
# comment: false # Disable comment if false.
---


With today’s technologies, it is very easy to develop and run multi-platform applications since we have code editors such as Visual Studio Code, Microsoft .Net Core (2.0 in its most recent version) and Docker containers.

On the Windows platform, Visual Studio 2017 provides the tools to develop .Net Core applications and support for debugging directly in a Docker container.

But in other platforms (Linux, MacOS) is not so clear the process to be able to perform this type of debugging processes; this is the reason to write this article.

The purpose of this article is to show how to use Visual Studio Code (VS Code) to configure a .Net Core project running on a Docker container and to be able to debug it.

The source code of the project created for this article is published in GitHub:
```
https://github.com/diegoortizmatajira/DockerDebug
```

## Pre requirements

-   [Visual Studio Code](http://code.visualstudio.com/): Code Editor
-   [Microsoft .Net Core SDK](https://www.microsoft.com/net/core) (2.0 or even 1.1)
-   [Docker](https://www.docker.com/get-docker): Platform for application containers.
-   [Node JS](http://nodejs.org/): Required to install NPM packages (such as yeoman and its templates)
-   [Yeoman](http://yeoman.io/): Tool for generating templates
-   [Yeoman docker template](https://github.com/Microsoft/generator-docker#readme): to generate files needed to use Docker with the project

**Note**: NodeJS, Yeoman, and docker template for Yeoman are not strictly necessary, but allow you to quickly generate additional files needed to enable Docker.

## Procedure

**Note**: The steps shown below were done on Linux platform, but the procedure must be the same for other platforms.

### Step 1: Creating the .Net Core Project

Creating the .Net Core project from the terminal using the Command Line Interface (CLI) of the SDK:

```
mkdir DockerDebug
cd DockerDebug
dotnet new console
```

![](https://i0.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug01-1.png?resize=648%2C481)

### Step 2: Add Docker Support

In this step the Yeoman application will be used to generate the necessary files to enable the generation of the containers for debugging and / or final for deployment in other environments.

In the same folder:
```
yo docker
```
![](https://i0.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug02-1.png?resize=648%2C478)

You must select the “.NET Core” option and proceed to answer the following questions:

-   **Language**: .NET Core
-   **Version of .NET Core**: rtm (Note: yeoman generator was originally created for version 1.0)
-   **The project uses a web server**: No, in this case it is a console project.
-   **Image Name**: This is the name of the image of the docker container to be generated, it can be modified if desired.
-   **Service name**: This is the name of the service that the container will play in the application when it is launched using docker-compose, it can be modified if desired.
-   **Name of the Compose project**: This is the name of the docker-compose file, it can be modified if desired.

![](https://i0.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug03-1.png?resize=648%2C569)

**Note**: An error message is generated indicating that the file “project.json” can not be found. Please omit this message, since the project.json files from .Net Core 1.1. were replaced by the “.csproj” project file.

### Step 3: Open the project in Visual Studio Code

There are two options:

Open the Visual Studio Code and find the folder where the project was created  
From the same terminal run the command:

Code .

![](https://i1.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug04-1.png?resize=648%2C441)

As you can see, thanks to yeoman and its docker generator, the project has the following files:

-   **.vscode / launch.json**: contains the settings for launching the application from the debugger
-   **.vscode / tasks.json**: contains the configuration of the commands required to prepare the container and launch it for debugging.
-   **docker.compose.debug.yml**: contains the settings for orchestrating and debugging the application and other services required by docker-compose.
-   **docker.compose.yml**: contains the configuration to orchestrate the application and other services required by docker-compose in an environment other than development.
-   **Dockerfile**: contains the process definition to build the docker image in an environment other than development.
-   **Dockerfile.debug**: contains the process definition to build the docker image enabled for debugging.
-   **dockerTask.ps1**: contains the script with the commands to launch the container in debug mode using PowerShell (Windows)
-   **dockerTask.sh**: contains the script with the commands to launch the container in debug mode using Shell commands (Linux and MacOs)

### Step 4: Adjust Configuration Files

Given that the yeoman docker generator was originally created for .Net Core 1.0, you need to make adjustments to several files to work with .Net Core 1.1 and / or .Net Core 2.0 versions.

#### Update .csproj project file

Add the following lines to the file inside the ```<Project> </ Project>```
```
<ItemGroup>
  <None Update="Dockerfile">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </None>
  <None Update="Dockerfile.Debug">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </None>
  <None Update="docker-compose.yml">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </None>
  <None Update="docker-compose.debug.yml">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </None>
</ItemGroup>
```
These lines tell the project to include docker support files when it generates publication files.

#### Update dockerfile

In the file dockerfile you must adjust the base image of docker to use according to the version of .Net Core (in this case 2.0).

Original file:
```
FROM **microsoft/dotnet:1.0.0-core**
WORKDIR /app
ENTRYPOINT \["dotnet", "DockerDebug.dll"\]
COPY . /app
```
Adjusted file:
```
FROM **microsoft/dotnet:2.0.0-runtime**
WORKDIR /app
ENTRYPOINT \["dotnet", "DockerDebug.dll"\]
COPY . /app
```
#### Update dockerfile.debug

in the dockerfile.debug file you must adjust the docker base image and the commands required to enable debugging:

Original file:
```
FROM **microsoft/dotnet:1.0.0-preview2-sdk**
ENV NUGET\_XMLDOC\_MODE skip
ARG CLRDBG\_VERSION=VS2015U2
WORKDIR /clrdbg
**RUN curl -SL https://raw.githubusercontent.com/Microsoft/MIEngine/getclrdbg-release/scripts/GetClrDbg.sh --output GetClrDbg.sh \\**
 **&& chmod 700 GetClrDbg.sh \\**
 **&& ./GetClrDbg.sh $CLRDBG\_VERSION \\**
 **&& rm GetClrDbg.sh**
WORKDIR /app
ENTRYPOINT \["/bin/bash", "-c", "if \[ -z \\"$REMOTE\_DEBUGGING\\" \]; then dotnet DockerDebug.dll; else sleep infinity; fi"\]
COPY . /app
```
Adjusted file
```
FROM **microsoft/dotnet:2.0.0-sdk**
ENV NUGET\_XMLDOC\_MODE skip
ARG CLRDBG\_VERSION=VS2015U2
WORKDIR /clrdbg
**RUN apt-get update \\**
 **&& apt-get install -y --no-install-recommends \\**
 **unzip \\**
 **&& rm -rf /var/lib/apt/lists/\* \\**
 **&& curl -sSL https://aka.ms/getvsdbgsh | bash /dev/stdin -v latest -l /vsdbg**
WORKDIR /app
ENTRYPOINT \["/bin/bash", "-c", "if \[ -z \\"$REMOTE\_DEBUGGING\\" \]; then dotnet DockerDebug.dll; else sleep infinity; fi"\]
COPY . /app
```
This is due to adjustments made to the Microsoft utilities that allow debugging.

#### Update dockerTask.ps1

On line 45 change:
```
$framework = "**netcoreapp1.0**"
```
with _netcoreapp1.1_ o _netcoreapp2.0_ as appropriate:
```
$framework = "**netcoreapp2.0**"
```
On line 110 change:
```
docker exec -i $containerId **/clrdbg/clrdbg --interpreter=mi**
```
with
```
docker exec -i $containerId **/vsdbg/vsdbg --interpreter=vscode** 
```
#### Update dockerTask.sh

On line 6 change:
```
framework="**netcoreapp1.0**"
```
with _netcoreapp1.1_ o _netcoreapp2.0_ as appropiate:
```
framework="**netcoreapp2.0**"
```
On line 80 change:
```
docker exec -i $containerId **/clrdbg/clrdbg --interpreter=mi**
```
with:
```
docker exec -i $containerId **/vsdbg/vsdbg --interpreter=vscode**
```
#### Update .vscode/launch.json

On section “_pipeTransport_” include the following highlighted line:
```
 "pipeTransport": {
   **"debuggerPath": "/vsdbg/vsdbg",**
   "pipeProgram": "/bin/bash",
   "pipeCwd": "${workspaceRoot}",
   "pipeArgs": \[ "-c", "./dockerTask.sh startDebugging" \],
   "windows": {
     "pipeProgram": "${env.windir}\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe",
     "pipeCwd": "${workspaceRoot}",
     "pipeArgs": \[ ".\\\\dockerTask.ps1", "-StartDebugging" \]
  }
```
#### Update the tasks.json file

By default the docker generator for Yeoman, only generates the configuration for Windows and for OSX, leaving out the Linux configuration. To solve this, just copy the “osx” section and name it “linux”
```
{
    // See https://go.microsoft.com/fwlink/?LinkId=733558
    // for the documentation about the tasks.json format
    "version": "0.1.0",
    "windows": {
        "command": "powershell",
        "options": {
            "cwd": "${workspaceRoot}"
        },
        "tasks": \[
            {
                "taskName": "build",
                "suppressTaskName": true,
                "args": \["-ExecutionPolicy", "RemoteSigned", ".\\\\dockerTask.ps1", "-Build", "-Environment", "debug" \],
                "isBuildCommand": true,
                "showOutput": "always",
                "echoCommand": true
            },
            {
                "taskName": "compose",
                "suppressTaskName": true,
                "args": \["-ExecutionPolicy", "RemoteSigned", ".\\\\dockerTask.ps1", "-Compose", "-Environment", "debug" \],
                "isBuildCommand": false,
                "showOutput": "always",
                "echoCommand": true
            },
            {
                "taskName": "composeForDebug",
                "suppressTaskName": true,
                "args": \["-ExecutionPolicy", "RemoteSigned", ".\\\\dockerTask.ps1", "-ComposeForDebug", "-Environment", "debug" \],
                "isBuildCommand": false,
                "showOutput": "always",
                "echoCommand": true
            }
        \]
    },
 "**osx**": {
        "command": "/bin/bash",
        "options": {
            "cwd": "${workspaceRoot}"
        },
        "tasks": \[
            {
                "taskName": "build",
                "suppressTaskName": true,
                "args": \[ "-c", "./dockerTask.sh build debug" \],
                "isBuildCommand": true,
                "showOutput": "always"
            },
            {
                "taskName": "compose",
                "suppressTaskName": true,
                "args": \[ "-c", "./dockerTask.sh compose debug" \],
                "isBuildCommand": false,
                "showOutput": "always"
            },
            {
                "taskName": "composeForDebug",
                "suppressTaskName": true,
                "args": \[ "-c", "./dockerTask.sh composeForDebug debug" \],
                "isBuildCommand": false,
                "showOutput": "always"
            }
        \]
    },
    "**linux**": {
        "command": "/bin/bash",
        "options": {
            "cwd": "${workspaceRoot}"
        },
        "tasks": \[
            {
                "taskName": "build",
                "suppressTaskName": true,
                "args": \[ "-c", "./dockerTask.sh build debug" \],
                "isBuildCommand": true,
                "showOutput": "always"
            },
            {
                "taskName": "compose",
                "suppressTaskName": true,
                "args": \[ "-c", "./dockerTask.sh compose debug" \],
                "isBuildCommand": false,
                "showOutput": "always"
            },
            {
                "taskName": "composeForDebug",
                "suppressTaskName": true,
                "args": \[ "-c", "./dockerTask.sh composeForDebug debug" \],
                "isBuildCommand": false,
                "showOutput": "always"
            }
        \]
    }
}
```
### Step 5: Compile

**Note**: In order to compile on Linux, you must first assign execute permissions to the dockerTask.sh file by using the following command in the terminal:
```
chmod +x dockerTask.sh
```
When compiling the solution, you should get a result like this:
```
Building the project (debug).
Microsoft (R) Build Engine versión 15.3.409.57025 para .NET Core
Copyright (C) Microsoft Corporation. Todos los derechos reservados.

DockerDebug -> /home/diegoortizmatajira/Código/Sandbox/DockerDebug/bin/debug/netcoreapp2.0/debian.8-x64/DockerDebug.dll
 DockerDebug -> /home/diegoortizmatajira/Código/Sandbox/DockerDebug/bin/debug/netcoreapp2.0/publish/
Building the image dockerdebug (debug).
Building dockerdebug
Step 1/8 : FROM microsoft/dotnet:2.0.0-sdk
 ---> a7dd4972fc95
Step 2/8 : ENV NUGET\_XMLDOC\_MODE skip
 ---> Using cache
 ---> 5185bef2ef3b
Step 3/8 : ARG CLRDBG\_VERSION=VS2015U2
 ---> Using cache
 ---> 6fbf2e0c733e
Step 4/8 : WORKDIR /clrdbg
 ---> Using cache
 ---> 0547ccd07803
Step 5/8 : RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/\* && curl -sSL https://aka.ms/getvsdbgsh | bash /dev/stdin -v latest -l /vsdbg
 ---> Using cache
 ---> 9817b6e47d20
Step 6/8 : WORKDIR /app
 ---> Using cache
 ---> ac302cab1a38
Step 7/8 : ENTRYPOINT /bin/bash -c if \[ -z "$REMOTE\_DEBUGGING" \]; then dotnet DockerDebug.dll; else sleep infinity; fi
 ---> Running in 5bf34ee4c155
 ---> 5e92325ef187
Removing intermediate container 5bf34ee4c155
Step 8/8 : COPY . /app
 ---> 11678806ad1c
Removing intermediate container 0a7a94fbfaaf
Successfully built 11678806ad1c
Successfully tagged dockerdebug:debug
```
In this way, it is evident that the image of the application for debugging was correctly created.

![](https://i2.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug05-1.png?resize=648%2C449)

### Step 6: Debug the application

For test purposes, a simple code fragment is added to the application and a breakpoint is defined in order to validate the possibility of debugging the code:

![](https://i0.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug06-1.png?resize=648%2C449)

And proceed to run the application and verify that the breakpoint is reached and that normal debugging tools can be used.

![](https://i1.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug07-1.png?resize=648%2C448)

You can verify that the container is running using the Docker command-line interface (CLI) in the terminal window.
```
docker ps
```
![](https://i0.wp.com/get-software.com.co/wp-content/uploads/2017/09/dockerdebug08-1.png?resize=648%2C134)

## Conclusion

According to what was done, it was possible to configure in Visual Studio Code a .Net Core application that runs in a Docker container and can be debugged as if the application was executed directly on the development team.

This enables the creation and debugging of complex applications that interact with multiple containers and are orchestrated using a docker-compose.yml file.

**NOTE**: In spite of orchestrating services with docker-compose, it will not be possible to scale the service being debugged, since the debugger can only be connected to one container at a time.