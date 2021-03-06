# docker-vm

The easiest way to get started with [Docker](https://www.docker.com/) on Mac OS X (tested on OS X Yosemite 10.10.1) 
and Windows (tested on Windows 10 Pro Insider Preview. Build 10074).

#### Goals 
- Transparency 
    - Everything (excluding base VM definition) is in a single, under 50 lines long `Vagrantfile`. 
- Configurability
    - Changes are inevitable so it's better when the process is quick and painless. Vagrant makes switching to a 
    different provider, changing base image (default one is 
    [Ubuntu 14.04 amd64 from phusion](https://github.com/phusion/open-vagrant-boxes)), etc. extremely easy.    
- Performance  
    - NFS/SMB instead of vboxsf (a.k.a. VirtualBox Shared Folders) 
    [by default](http://mitchellh.com/comparing-filesystem-performance-in-virtual-machines). rsync/unison when you need them. 
- Utility
    - VM is controlled by [Vagrant](https://www.vagrantup.com/), meaning that you get stuff like `vagrant share`, 
    `vagrant package`, etc. out of box.

You are encouraged to fork and change this repo to suit **your needs**.

## How does it work?

When you boot the VM Docker starts listening on port 2376. Each time you call `docker` (or `docker-compose`, ...) on the host
it sends a request (using the value of $DOCKER_HOST environment variable) to the guest OS. Together with `/Users/USERNAME ->
/Users/USERNAME` (on Mac OS X) and `C:\Users\USERNAME -> /c/Users/USERNAME & /cygwin/c/Users/USERNAME` mapping it allows
to use Docker client the way you would on Linux (sort of).

## Installation

Irrespective of whether you're going to go with "Automated" or "Manual" setup, please make sure you have
[Git](https://git-scm.com/downloads), [Docker](https://docs.docker.com/installation/binaries/) client (grab it from [here](https://docs.docker.com/installation/binaries/) (latest - Mac OS X: [x86_64](https://get.docker.com/builds/Darwin/x86_64/docker-latest.tgz) / Windows: [i386](https://get.docker.com/builds/Windows/i386/docker-latest.zip)/[x86_64](https://get.docker.com/builds/Windows/x86_64/docker-latest.zip))) (tested on 1.6.1),
[Vagrant](https://www.vagrantup.com/downloads.html) (tested on 1.7.2) &
[VirtualBox](https://www.virtualbox.org/wiki/Downloads) (tested on 4.3.26) installed.

### Automated (Mac OS X only)

```sh
curl -o- https://raw.githubusercontent.com/shyiko/docker-vm/master/install.sh | bash
```
> (reopen terminal/tab on completion)

NOTE that if you get something like "-bash: docker-vm: command not found" then it's probably because ~/.bashrc is not 
sourced from ~/.bash_profile. In that case run `echo 'if [ -f ~/.bashrc ]; then source ~/.bashrc; fi' >> ~/.bash_profile` and restart your terminal/tab.

The script clones the docker-vm repository to ~/.docker-vm and adds initialization
code to ~/.bashrc (or ~/.bash_profile, ~/.zshrc, ~/.profile, whichever it finds first).
It also appends `192.168.42.10 docker-vm` to the /etc/hosts so that you would be able to reference
VM by name and not just ip address (e.g. `http://docker-vm:8000/`).

You can customize repository url, checkout directory and profile using the
DOCKER_VM_SOURCE, DOCKER_VM_DIR, and PROFILE variables (e.g.
`curl ... | DOCKER_VM_SOURCE=http://github.com/YOUR_NAME/docker-vm.git bash` to
use your fork instead of this repo).

### Manual

* Mac OS X

```sh
git clone https://github.com/shyiko/docker-vm.git ~/.docker-vm

# NOTE: unless you want to execute lines below every time you open up a new terminal/tab -
#       consider adding them to the ~/.bash_profile (or whichever profile you use)
#       (more on that here - http://ss64.com/osx/syntax-bashrc.html)
docker-vm() ( cd ~/.docker-vm && exec vagrant "$@" )

export DOCKER_HOST=tcp://192.168.42.10:2376
unset DOCKER_TLS_VERIFY # if boot2docker is installed
```

* Windows

> MSYS/Cygwin users only: see installation instructions for Mac OS X.

(execute in `cmd`)

```sh
git clone https://github.com/shyiko/docker-vm.git "%USERPROFILE%/.docker-vm"

(
echo @ECHO OFF
echo SETLOCAL
echo cd /D ^%USERPROFILE^%\.docker-vm
echo vagrant %*
echo ENDLOCAL
) > %SystemRoot%\system32\docker-vm.bat

set DOCKER_HOST=tcp://192.168.42.10:2376
unset DOCKER_TLS_VERIFY
```

## Usage

```sh
docker-vm up # boot up the vm (check "docker-vm --help" for the list of available commands)

# verify that docker client is able to connect to the daemon running inside the vm
docker version

# start using docker *
docker run -v $(pwd):/usr/share/nginx/html -d -p 8080:80 nginx
echo "hello world" > index.html
open http://docker-vm:8080/ # **
```

\* on Windows `$(pwd)` needs to be replaced with /c/Users/USERNAME/... (unless you are using MSYS/Cygwin)

\** if you don't have `192.168.42.10 docker-vm` in `/etc/hosts`
(or [equivalent](http://superuser.com/questions/525688/whats-the-windows-equivalent-of-etc-hosts) on Windows) -
replace `http://docker-vm:8080/` with `http://192.168.42.10:8080/`.

> Note that `docker-vm` is basically just an alias for `vagrant` which means that
you can use all the [commands](https://docs.vagrantup.com/v2/cli/index.html) supported by the latter (e.g. `docker-vm suspend`, `docker-vm status`, ...).

Getting things to work on Windows can be a little bit tricky (what a suprise, right). Check out the "Troubleshooting" section (further in the document) if you experience any problems with `docker-vm up`.

## A note on docker-compose

Right now [docker-compose](https://github.com/docker/compose) is available for Linux / Mac OS X only. Windows support is coming in [docker/compose#1085](https://github.com/docker/compose/issues/1085). Until then, one way to get docker-compose on Windows is to:

1. Enter the VM with `docker-vm ssh` and install docker-compose by executing ```sudo sh -c "curl -L https://github.com/docker/compose/releases/download/1.3.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose"```.

2. Create docker-compose alias. If you are using MSYS/Cygwin then it's a matter of adding `docker-compose() ( docker-vm ssh -c "cd $(pwd) && exec docker-compose $*" )` to ~/.bashrc, otherwise - execute (in `cmd`): 
    ```sh
    (
    echo @ECHO OFF
    echo SETLOCAL
    echo SET pwd=^%cd^:\=/%
    echo docker-vm ssh -c ^"cd ^%pwd^:C:/=/c/% ^&^& exec docker-compose %*^"
    echo ENDLOCAL
    ) > %SystemRoot%\system32\docker-compose.bat
    ```

## Advanced
 
### Performance considerations 

Sooner or later, chances are that you'll have to deal with a lot of small files. And the things is - neither vboxsf nor NFS/SMB 
may be up to the task. Here are some numbers to visually demonstrate the issue (time taken to make a copy of 
`node_modules` containing 32k of files / 290mb in size on MacBook Pro (Retina, Mid 2012), obviously YMMV):

| VirtualBox native | native | Network File System (NFS) | VirtualBox Shared Folders (vboxsf) |
| ----------------- | ------ | ----- | ------ |
| 17.5s             | 18.5s  | 2m10s | 3m25s  |

The good new is - you can continue using NFS/SMB or even vboxsf (as they are not that bad when you have fewer files) and switch to 
`rsync`/`unison` only when necessary (more on that in a bit). The solution is to use `mount -o bind`, which
allows to mount arbitrary directory over the other already mounted one (including subtree), like so:    

```sh
docker-vm ssh -c "
    SOURCE_DIR=/Users/USERNAME/Projects &&
    MOUNT_ROOT=/home/vagrant/.mnt &&
    mkdir -p $MOUNT_ROOT/$SOURCE_DIR && 
    sudo mount -o bind $MOUNT_ROOT/$SOURCE_DIR $SOURCE_DIR"        
``` 

After that just `rsync`/`unison` files to `$MOUNT_ROOT/$SOURCE_DIR`.

#### Uni-directional syncing (using rsync)

Check out "vagrant [rsync](https://docs.vagrantup.com/v2/cli/rsync.html)" and "vagrant [rsync-auto](https://docs.vagrantup.com/v2/cli/rsync-auto.html)". 
For a one time sync you may find `rsync -av SOURCE_DIR vagrant@192.168.42.10:TARGET_DIR` (password is `vagrant`) to be more convenient, though.

#### Bi-directional syncing (using [unison](https://www.cis.upenn.edu/~bcpierce/unison/index.html)) 

> `unison` must be installed both on host and guest OSs (**make sure versions match**).  
On Mac OS X - `brew install unison` (2.48.3 at the time of writing).   
On Windows - `choco install unison -version 2.48.3` (provided [chocolatey](https://chocolatey.org/) is installed).

> To install unison inside the VM:   
`sudo apt-get update && sudo apt-get install -y ocaml build-essential exuberant-ctags &&
curl http://www.seas.upenn.edu/~bcpierce/unison/download/releases/unison-2.48.3/unison-2.48.3.tar.gz | tar xz -C /tmp &&
(cd /tmp/unison-* && make UISTYLE=text && sudo cp unison /usr/local/bin/)`

```sh
# start unison daemon
docker-vm ssh -c "unison -socket 5000"
 
# start syncing (see `unison -help` for more information)  
unison SOURCE_DIR socket://192.168.42.10:5000/TARGET_DIRECTORY \
    -terse -auto -prefer=SOURCE_DIR -batch -repeat 3
```

#### Mounting NFS volumes manually

(it might come in handy if you don't want your whole /Users/USER directory to be mounted inside the VM and 
 narrowing paths with multiple `config.vm.synced_folder` feels too "static") 
 
```sh 
docker-vm ssh -c "mkdir -p SOURCE_DIRECTORY && 
    mount -o 'vers=3,udp' 192.168.42.1:SOURCE_DIRECTORY SOURCE_DIRECTORY"
``` 

> Don't forget to update /etc/fstab (in your guest OS) if you want to make this link persistent.      

## Troubleshooting

* (issue [#12182](https://www.virtualbox.org/ticket/12182))
  C:\>docker-vm up  
  VBoxManage.exe: error: Failed to create the host-only adapter
  ...
  
  WORKAROUND: Settings -> View Network Connections -> Ethernet N ->
  Details... -> select "Internet Protocol Version 4 (TCP/IPv4)" -> Properties -> set "IP address" to 192.168.42.1. 
  Try vagrant up again.  

* C:\>docker-vm up  
  The guest machine entered an invalid state while waiting for it to boot. Valid states are 'starting, running'. The machine is in the 'poweroff' state. Please verify everything is configured properly and try again.

  WORKAROUND: Start VirtualBox, select VM named docker-vm... and click 'Start'. If you get an error similar to 'Failed to open a session for the virtual machine docker-vm... . VT-x is not available. (VERR_VMX_NO_VMX).' then [turn Hyper-V off](http://www.hanselman.com/blog/SwitchEasilyBetweenVirtualBoxAndHyperVWithABCDEditBootEntryInWindows81.aspx).

* (issue [#3139](https://github.com/mitchellh/vagrant/issues/3139))
  C:\>docker-vm up  
  Clearing any previously set forwarded ports  
  ... or similar and then it just hangs.  

  SOLUTION: Either install [PowerShell 3](http://www.microsoft.com/en-us/download/details.aspx?id=34595) or remove/comment out ", type: smb" in [Vagrantfile](https://github.com/shyiko/docker-vm/blob/master/Vagrantfile#L25). See related issue for more information. 

* C:\>docker-vm ssh  
  `ssh` executable not found in any directories in the %PATH% variable. Is an
  SSH client installed? Try installing Cygwin, MinGW or Git, all of which
  contain an SSH client. Or use your favorite SSH client with the following
  authentication information shown below:
  ...
  
  SOLUTION: Install [Git for Windows](http://git-scm.com/download/win) (tested on 1.9.5) and make sure 
  "C:\Program Files (x86)\Git\bin" is on the [PATH](http://www.computerhope.com/issues/ch000549.htm).
   
