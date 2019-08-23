#!/bin/bash

#     GUI Config System - Copyright 2019, Lach Sławomir <slawek@lach.art.pl>
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#     
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#     
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

function fatal_kdialog
{
  echo "$1"
  $DIALOG --msgbox "$1"
  exit 1
}

function displ_file_kdialog
{
  $DIALOG --textbox "$1"
}

function ask_kdialog
{
  $DIALOG  --yesno "$1"
}

function ask_to_continue_kdialog
{
  ask_kdialog "$1"
  if [ ! $? -eq 0 ]; then exit; fi
}

function select_file_kdialog
{
  $DIALOG --getopenfilename "$PWD" "*"
}


function fatal_zenity
{
  echo "$1"
  $DIALOG --error --text="$1"
  exit 1
}

function displ_file_zenity
{
  $DIALOG --text-info --cancel-label="ok" --filename="$1"
}

function ask_zenity
{
  $DIALOG  --question --text="$1"
}

function ask_to_continue_zenity
{
  ask_zenity "$1"
  if [ ! $? -eq 0 ]; then exit; fi
}

function select_file_zenity
{
  $DIALOG --file-selection
}

function fatal_dialog
{
  $DIALOG --msgbox  "$1" 5 200
  exit 1
}

function displ_file_dialog
{
  $DIALOG --textbox "$1" 200 200
}

function ask_dialog
{
  $DIALOG  --yesno "$1" 200 200
}

function ask_to_continue_dialog
{
  ask_dialog "$1"
  if [ ! $? -eq 0 ]; then exit; fi
}

function select_file_dialog
{
  local dir
  dir="$PWD"
  while [ -d "$dir" ]; do
     dir=${dir/\/\//\/}
     dir=`$DIALOG --stdout --fselect "$dir/" 20 200`
  done
  echo $dir
}

if [ "x$DIALOG" == "x" ]; then
if [ "x$XDG_SESSION_DESKTOP" == "xKDE" ]; then
  DIALOG=kdialog
elif [ "x$XDG_SESSION_DESKTOP" != "xGNOME" ]; then
  DIALOG=zenity
elif [ "x$DISPLAY" != "x" ]; then
   if [ "x`which kdialog`" != "x" ]; then
     DIALOG=kdialog
   elif [ "x`which zenity`" != "x" ]; then
     DIALOG=zenity
   else
     DIALOG=dialog
   fi
else
  DIALOG=dialog
  
fi
fi

if [ "x$DISPLAY" == "x" ]; then
  DIALOG=dialog
fi

if [ "x$DIALOG" == 'xdialog' ] && [ -F 0 ]; then
  wall 'Cannot find usable dialog program'
  exit 1
fi

if [ "x$DIALOG" == 'xdialog' ]; then

  fatal=fatal_dialog
  display_file=displ_file_dialog
  ask_to_continue=ask_to_continue_dialog
  ask=ask_dialog
  select_file=select_file_dialog
elif [ "x$DIALOG" == 'xzenity' ]; then
   
   fatal=fatal_zenity
   display_file=displ_file_zenity
   ask_to_continue=ask_to_continue_zenity
   ask=ask_zenity
   select_file=select_file_zenity
elif [ "x$DIALOG" == 'xkdialog' ]; then
   
  
  fatal=fatal_kdialog
  display_file=displ_file_kdialog
  ask_to_continue=ask_to_continue_kdialog
  ask=ask_kdialog
  select_file=select_file_kdialog
fi

path=$1
if [ "x$path" == "x" ]; then
  path=`$select_file`
  [ "x$path" == "x" ] && $fatal 'Sorry, you must provide a path to archive'
fi

if [ ! $UID -eq 0 ]; then
  $ask "Currently it's a necessary to run this utility as root. Relaunch as root?"
  if [ $? -eq 0 ]; then
    
    #joined="${@}"
    while [ ! "x$1" == "x" ]; do
      
      joined=${joined}\ \"
      arg=${1}
      arg=${arg//\\/\\\\}
      arg=${arg//\"/\\\"}
      joined=${joined}${arg}\"
      shift
      done
    xdg-su -c "/bin/bash -c \"\\\"$0\\\" $joined"
    wait $!
  fi
fi

output=`mktemp -d`
steps=`mktemp -d`
runtime=`mktemp -d`

trap "echo Removing $output; rm -rf $output; echo Removing $steps; rm -rf $steps; echo Removing $runtime; rm -rf $runtime;" TERM EXIT

tar -xf "$path" -C $output 2> $steps/0-errors

if [ ! $? -eq 0 ]; then
   
  $display_file $steps/0-errors
  exit 1
fi

if [ ! -f $output/metainfo-package-list ] ||  [ "$(wc -c $output/metainfo-package-list | cut -d' ' -f1 )" -eq 0 ]; then
  $fatal "Empty package list file or package list file doesn't exist!"
  exit 1
fi

if [ ! -f $output/metainfo-flatpak ] ||  [ "$(wc -c $output/metainfo-package-list | cut -d' ' -f1 )" -eq 0 ]; then
  $fatal "Empty metainfo for flatpak file or flatpak metainfo file doesn't exist!"
  exit 1
fi

echo Bellow are attached errors ocour during invocation of copy operation > $steps/1-errors-issue

echo Bellow are attached list of packages and files to modify > $steps/1

for a in $(cat $output/metainfo-package-list); do
   
   echo 'Package:' $a
   for b in $(rpm -ql $a); do
    ok=true
      mkdir -p ${runtime}/`dirname $b` || ok=false
      if [ ! -e ${runtime}/${b} ]; then
      
        cp -r "$b" ${runtime}/${b} || ok=false
      fi
    
    if [ "$ok" != "false" ]; then echo 'File:' $b ' (for package: ' $a ')'; fi
  done
done >> $steps/1 2> $steps/1-errors

if [ -e $steps/1-errors ] && [ ! "$(wc -c $steps/1-errors | cut -d' ' -f1 )" -eq 0 ]; then
   cat $steps/1-errors >> $steps/1-errors-issue
   cat $steps/1 >> $steps/1-errors-issue
   rm $steps/1
   mv $steps/1-errors-issue $steps/1
fi

$display_file $steps/1
$ask_to_continue 'Continue?'
fl_runtime_name=""
fl_runtime_version=""
fl_runtime_branch=""

IFS=':'; 

 while read -r field_name field_value; do
   field_name=`echo $field_name | tr -d '[ \t\n]'`
   field_value=`echo $field_value | tr -d '[ \t\n]'`
   if [ "$field_name" == "runtime-name" ]; then
     fl_runtime_name="$field_value"
   elif [ "$field_name" == "runtime-version" ]; then
     echo 'Version field is not supported'
     fl_runtime_version="$field_value"
   elif [ "$field_name" == "runtime-branch" ]; then
     fl_runtime_branch="$field_value"
   fi
done < $output/metainfo-flatpak
unset IFS
$ask_to_continue 'It will going be '$fl_runtime_name' runned (version '$fl_runtime_version' branch '$fl_runtime_branch'). Continue?'

flatpak run -p --system --socket=pulseaudio --socket=fallback-x11 --filesystem=$output --filesystem=$runtime:rw --command=/bin/bash $fl_runtime_name//$fl_runtime_version -c "mkdir -p /GCS/; ln -s $output /GCS/application; ln -s $runtime /GCS/runtime; /GCS/application/config-app"

echo Bellow are attached errors during calculating the changes made by tool you was run > $steps/2-errors-issue
echo Bellow are attached changes made by tool you was run \(ALL FILES WITH POSSIBLE CHANGES ARE: $runtime \) > $steps/2
  
pushd $runtime
find . -type f -exec /bin/bash /dev/stdin {} \;  >> $steps/2 2> $steps/2-errors <<EOF
cmp $runtime/\$1 /\$1 2> /dev/null || (
  echo \$1
  diff $runtime/\$1 /\$1
  )
EOF
popd
  
if [ -e $steps/2-errors ] && [ ! "$(wc -c $steps/2-errors | cut -d' ' -f1 )" -eq 0 ]; then
cat $steps/2-errors >> $steps/2-errors-issue
cat $steps/2 >> $steps/2-errors-issue
rm $steps/2
mv $steps/2-errors-issue $steps/2
fi

$display_file $steps/2
$ask_to_continue 'Replace?'

cp -r $runtime /
