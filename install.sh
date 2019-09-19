#!/bin/sh

# Will create a working toolchain under macOS
OS=$(uname -s)
if [ "$OS" != Darwin ] ; then
  echo "WARNING: Unsupport \"$OS\" OS. This script is only intended to use on macOS"
  exit 1
fi

if [ "$(uname -s)" = Linux ] ; then
	PROFILE=~/.bashrc
else
	PROFILE=~/.profile
fi

# need to test for these, because if they exist than bash won't read .profile
for PRO in ~/.bash_profile ~/.bash_login ~/.bashrc ; do
  [ -r "$PRO" ] && PROFILE="$PRO"
done

ataridevroot=$PWD

cat <<EOF

___________________________Atart 2600 Dev__________________________

This script will update your $PROFILE file to 
set the following variables each time you open a concole window.

  export ATARIDEVROOT="$ataridevroot"
  export PATH=\$PATH:\$ATARIDEVROOT/bin
  alias atari='cd \$ATARIDEVROOT'

After it installs the toolchain to programm for the Atari 2600 on macOS

____________________________________________________________________

      Hit [ENTER] to begin, or type q and [ENTER] to quit.

EOF
read ANSWER
[ "$ANSWER" ] && exit 2

echo "Update $PROFILE ..."

# Ensure the profile exists
[ -r "$PROFILE" ] || touch "$PROFILE"

# Create a backup of the profile...
cp "$PROFILE" "$PROFILE.$(date +%y%m%d%H%M%S)"

# Remove any old  entries 
grep -v ATARIDEVROOT "$PROFILE" > "$PROFILE.new"

echo "## ATARIDEVROOT variables, added by install.sh at $(date +%y/%m/%d)" >> "$PROFILE.new"
echo "export ATARIDEVROOT=\"$ataridevroot\"" >> "$PROFILE.new"
echo 'export PATH=$PATH:$ATARIDEVROOT/bin' >> "$PROFILE.new"
echo "alias atari=\"cd $ataridevroot\"" >> "$PROFILE.new"

if [ ! -r "$PROFILE.new" ] ; then
  echo
  echo "ERROR: Could not create the new profile."
  exit 3
fi

# move the contents instead, to preserve any custom permissions on the profile
cat "$PROFILE.new" > "$PROFILE" && rm "$PROFILE.new"

export ATARIDEVROOT="$ataridevroot"

# Create folders
echo "Create folder(s)..."
mkdir bin
mkdir examples
mkdir tools
mkdir includes
cd tools

# Get assembler
echo "Download assembler..."
curl -LO  "https://github.com/munsie/dasm/archive/master.zip"
unzip master.zip
mv dasm-master dasm
rm $ATARIDEVROOT/tools/master.zip

# Make it
cd dasm/src
make
cp dasm $ATARIDEVROOT/bin/dasm
cp $ATARIDEVROOT/tools/dasm/test/atari2600/boing26.asm $ATARIDEVROOT/examples/sample1.asm
cp $ATARIDEVROOT/tools/dasm/machines/atari2600/macro.h $ATARIDEVROOT/includes/macro.h
cp $ATARIDEVROOT/tools/dasm/machines/atari2600/vcs.h $ATARIDEVROOT/includes/vcs.h

# Get emulator
echo "Download emulator..."
cd $ATARIDEVROOT/tools
curl -LO  "http://www.whimsey.com/z26/z26_407_src.zip"
unzip z26_407_src.zip
rm $ATARIDEVROOT/tools/z26_407_src.zip
mv z26_407_src z26
cd z26
make
cp z26 $ATARIDEVROOT/bin/z26

# Create build command
cd $ATARIDEVROOT/bin
echo 'dasm $1 -I"$ATARIDEVROOT/tools/basic/include" -f3 -o$1.bin' >> "ataribuild.sh"
echo 'z26 $1.bin' >> "ataribuild.sh"
chmod a+x ataribuild.sh

# End message
cat <<EOF


Installation was successfully!

Don't wait and tryout now!  

  1. Open another terminal window. 
  2. type: atari
  3. type: cd examples
  3. type: ataribuild.sh sample1.asm

This will create a binary file and start it in the emulator 

EOF

