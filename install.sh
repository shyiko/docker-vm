#!/bin/bash -e

{ # this ensures the entire script is downloaded

DOCKER_VM_SOURCE=${DOCKER_VM_SOURCE:-https://github.com/shyiko/docker-vm.git}

if [ ! -z "$DOCKER_VM_SOURCE_BRANCH" ]; then
  DOCKER_VM_SOURCE="-b $DOCKER_VM_SOURCE_BRANCH $DOCKER_VM_SOURCE"
fi

if [ -z "$DOCKER_VM_DIR" ]; then
  DOCKER_VM_DIR="$HOME/.docker-vm"
fi

if [ -z "$(which git)" ]; then
  echo "`git` must be installed and available on the PATH"
  exit 1
fi

(cd $DOCKER_VM_DIR 2>/dev/null && git pull) || git clone $DOCKER_VM_SOURCE $DOCKER_VM_DIR

detect_profile() {
  if [ -f "$PROFILE" ]; then
    echo "$PROFILE"
  elif [ -f "$HOME/.bashrc" ]; then
    echo "$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    echo "$HOME/.bash_profile"
  elif [ -f "$HOME/.zshrc" ]; then
    echo "$HOME/.zshrc"
  elif [ -f "$HOME/.profile" ]; then
    echo "$HOME/.profile"
  fi
}

PROFILE=$(detect_profile)

SOURCE_STR="\n# https://github.com/shyiko/docker-vm
export DOCKER_HOST=tcp://192.168.42.10:2376
unset DOCKER_TLS_VERIFY # just in case boot2docker is installed
export DOCKER_VM_DIR=$DOCKER_VM_DIR
docker-vm() ( cd \$DOCKER_VM_DIR && exec vagrant \"\$@\" )"

if [ -z "$PROFILE" ] ; then
  echo "Profile not found. Tried \$PROFILE, ~/.bashrc, ~/.bash_profile, ~/.zshrc, and ~/.profile."
  echo "Create one of them and run this script again"
  echo "OR"
  echo "Append the following lines to the correct file yourself:"
  printf "$SOURCE_STR"
  echo
else
  if ! grep -qc 'docker-vm' "$PROFILE"; then
    echo "Appending source string to $PROFILE"
    printf "$SOURCE_STR\n" >> "$PROFILE"
  else
    echo "Source string already in $PROFILE"
  fi
fi

} # this ensures the entire script is downloaded


