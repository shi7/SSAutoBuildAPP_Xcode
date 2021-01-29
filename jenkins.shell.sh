#!/bin/bash
# Created by xiangmu on 2020/11/27.
# Copyright © 2020年 jusekj. All rights reserved.


configFile='./src/config/config.js'

echo build for ${platform}


function buildIOS()
{

cd ios && pod install

# ios params
is_workspace="true"

# set for you code 'you project workspace name'
workspace_name="you project workspace name"

project_name=""
# set for you code 'you project scheme_name'
scheme_name="you project scheme_name"
build_configuration="Release"
method="ad-hoc"

script_dir="$( cd "$( dirname "$0"  )" && pwd  )"
project_dir=$script_dir

DATE=`date '+%Y%m%d_%H%M%S'`
export_path="$project_dir/build/$scheme_name-$DATE"
export_archive_path="$export_path/$scheme_name.xcarchive"
export_ipa_path="$export_path/"
ipa_name="${scheme_name}_${DATE}"
export_options_plist_path="$project_dir/ExportOptions.plist"


if [ -d "$export_path" ] ; then
    echo $export_path
else
    mkdir -pv $export_path
fi

xcodebuild clean -workspace ${workspace_name}.xcworkspace \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -workspace ${workspace_name}.xcworkspace \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}

if [ -d "$export_archive_path" ] ; then
    echo "👀  congratulation you  🚀 🚀 🚀     👀"
else
    echo "👀  build fail 😢 😢 😢  👀"
    exit 1
fi
echo "------------------------------------------------------"

echo " archive ipa ...  👀"

if [ -f "$export_options_plist_path" ] ; then
    rm -f $export_options_plist_path
fi
/usr/libexec/PlistBuddy -c  "Add :method String ${method}"  $export_options_plist_path
/usr/libexec/PlistBuddy -c  "Add :provisioningProfiles:"  $export_options_plist_path
/usr/libexec/PlistBuddy -c  "Add :provisioningProfiles:${bundle_identifier} String ${mobileprovision_name}"  $export_options_plist_path
/usr/libexec/PlistBuddy -c  "Add :compileBitcode Bool true" $export_options_plist_path


xcodebuild  -exportArchive \
            -archivePath ${export_archive_path} \
            -exportPath ${export_ipa_path} \
            -exportOptionsPlist ${export_options_plist_path} \
            -allowProvisioningUpdates

if [ -f "$export_ipa_path/$scheme_name.ipa" ] ; then
    echo "👀👀👀 exportArchive ipa succeed 👀👀👀"
else
    echo "👀👀👀 exportArchive ipa fail 😢 😢 😢     👀👀👀"
    exit 1
fi

mv $export_ipa_path/$scheme_name.ipa $export_ipa_path/$ipa_name.ipa

if [ -f "$export_ipa_path/$ipa_name.ipa" ] ; then
    echo "👀 export ${ipa_name}.ipa succeed 🎉  🎉  🎉   👀"
    open $export_path
else
    echo "👀 export ${ipa_name}.ipa fail 😢 😢 😢     👀"
    exit 1
fi

if [ -f "$export_options_plist_path" ] ; then
    echo "${export_options_plist_path} deleted"
	  rm -f $export_options_plist_path
fi
  echo "👀  AutoPackageScript : ${SECONDS}s 👀"
  upload "${export_ipa_path}/${ipa_name}.ipa"
  cd ..  
}

function buildAndroid()
{
  # cd android &&  ./gradlew assembleRelease
   cd android && rm -fr app/build/ &&  ./gradlew assembleRelease
   ./gradlew assembleRelease
   cd ..  
   upload "${WORKSPACE}/android/app/build/outputs/apk/release/app-armeabi-v7a-release.apk"
}

function upload()
{
  local filePath=$1
  if [[ $dev_or_product = "develop" ]];then
    #statements
    uploadFirim ${filePath}
  else
        # set for you code 'youkey'
    curl -F "file=@${filePath}" -F '_api_key=youkey' https://www.pgyer.com/apiv2/app/upload
  fi
}

#api
function uploadFirim(){
  local filePath2=$1
    # set for you code 'youkey'
  fir p $filePath2 -c 'new upload ' -Q -T youkey
}

function changeConfig(){
  gitlog=`git log -n1 --format=format:"%h"`
  # set for you special code '0120a' for sign to replease
  p='s/0120a/'${gitlog}'/g' 
  echo v = $p
  sed -i '' $p ./src/config/config.js

  if [[ $dev_or_product = "develop" ]];then
    sed -i '' 's/production/develop/' ${configFile}
    echo 'change develop config ==== ' && cat ${configFile}
  else
    sed -i '' 's/develop/production/' ${configFile}  
    echo 'change production config ==== ' && cat ${configFile}
  fi
}

function resetConfig(){
  git checkout ${configFile}
  echo 'resetConfig ==== ' && cat ${configFile}
}

npm install
changeConfig
if  [[ $platform = "all" ]];then
buildIOS
buildAndroid
elif [[ $platform = "iOS" ]];  then
  buildIOS
elif [[ $platform = "android" ]];  then 
  buildAndroid
fi
resetConfig

