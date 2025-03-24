# Build & install Lua on macOS

# We will compile Lua 5.1 because it is compatible with openresty/lapis.
# Replace the variables from line 30 ff to install a diffrent version.

# See: https://www.lua.org/manual/5.1/

# NOTE:
# We create a dedicated directory for the Lua stuff to put all the stuff in.

## Tested on ...

sysctl -n machdep.cpu.brand_string # Apple M1
sw_vers -productName               # macOS
sw_vers -productVersion            # 14.5

## Install build tools

xcode-select --install
# Optional: Update all software
softwareupdate --install --all

## Create Lua Directory

# Where to install lua, luajit, luarocks ..?
LUA=~/devop/lua
mkdir -p $LUA

## Download and Extract Lua Sources
cd /tmp
wget https://www.lua.org/ftp/lua-5.1.5.tar.gz

# Optional: Check hash
shasum -a 256 lua-5.1.5.tar.gz | grep -q '2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333' &&
  echo "Hash matches" || echo "Hash does not match"

tar xvf lua-5.1.5.tar.gz
cd lua-5.1.5/

## Modify Makefile to set destination dir

sed -i '' "s#/usr/local#${LUA}/#g" Makefile

## Compile and install Lua
make macosx
make test && make install

## Optional: Update environment variables
# We place the Lua related variabls in a dedicated file and source it.

echo 'export PATH=${LUA}bin:$PATH' >>${LUA}/.profile
echo "export LUA_CPATH=${LUA}lib/lua/5.1/?.so" >>${LUA}/.profile
echo "export LUA_PATH=${LUA}share/lua/5.1/?.lua;;" >>${LUA}/.profile
echo "export MANPATH=${LUA}share/man:\$MANPATH" >>${LUA}/.profile
echo 'source ${LUA}/.profile' >>~/.bashrc
echo 'source ${LUA}/.profile' >>~/.zshrc

source ${LUA}/.profile

### Verify Lua Installation

which lua
lua -v
# Expected Output: Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio
file ${LUA}/bin/lua
# Expected Output: ... Mach-O 64-bit executable arm64

### Build and install LuaRocks

cd /tmp
wget https://luarocks.org/releases/luarocks-3.9.1.tar.gz

# Extract and enter the directory
tar xvf luarocks-3.9.1.tar.gz
cd luarocks-3.9.1/

# Configure and install LuaRocks
./configure --prefix=${LUA} --with-lua=${LUA} --lua-suffix=5.1 --with-lua-include=${LUA}/include
make build && make install

# Verify LuaRocks installation
lua -v
luarocks --version

### Build and Install LuaJIT

# Create a git folder in the Lua directory to keep things together (optional)
mkdir $LUA/git
cd $LUA/git

# Clone the LuaJIT repository
git clone https://luajit.org/git/luajit.git
cd luajit

# Get macOS version and set MACOSX_DEPLOYMENT_TARGET
MACOS_VERSION=$(sw_vers -productVersion)
MACOSX_DEPLOYMENT_TARGET=${MACOS_VERSION%.*}

# Compile and install LuaJIT
MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} make
MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} make install PREFIX=${LUA}

source ${LUA}/.profile
luajit -v

### Install LuaSec for Testing

# Add external dependencies directory to LuaRocks config
echo 'external_deps_dirs = { "/opt/homebrew" }' >>${LUA}/etc/luarocks/config-5.1.lua

## Install LuaSec rock (optional to test luarocks)
# Ensure OpenSSL is installed - for example via Homebrew
# brew install openssl
# you may adjust the path to libs
luarocks --local install luasec \
  OPENSSL_INCDIR=/opt/homebrew/Cellar/openssl@3/3.3.0/include/ \
  OPENSSL_LIBDIR=/opt/homebrew/Cellar/openssl@3/3.3.0/lib
