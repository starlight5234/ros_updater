#!/bin/bash
# Giovix92 was here, 15/04/2021, 13:56 GMT+1
set -e
a=()
mainpath=$(pwd)
devices_dir=$(pwd)/official_devices
ota_scripts=$(pwd)/ota_scripts

checkchangelog() {
    if [ ! -f "$(pwd)/changelog.txt" ]; then
        echo "Create changelog.txt file in build directory"
        echo "Aborting..."
        return 1
    else
        return 0
    fi
}

checkconfig() {
    if [ -e "$(pwd)/push_config.conf" ]; then
        return 0
    else
        return 1
    fi
}

checkupload() {
    if [ ! -e $(pwd)/RevengeOS*${target_device}*.zip ]; then
        return 0
    else
        return 1
    fi
}

auto_process() {
    echo "Found push_config.conf! Importing vars."
    set -a
    . "$(pwd)/push_config.conf"
    set +a
    if [ "$uservar" == "" ]; then
        echo "uservar not exported, aborting."
        return 0
    elif [ "$target_device" == "" ]; then
        echo "target_device not exported, aborting."
        return 0
    fi
    echo "Picking automatically the newer zip file..."
    zipname=$(ls -t *.zip | head -n1)
}

manual() {
    # Ask the maintainer for login details
    read -p 'Sourceforge Username: ' uservar
    read -p 'Insert your device codename: ' target_device
    if [ "$target_device" == "" ]; then
        echo "Please select a device."
        return 0
    fi
}

checkremotedir() {
    echo "Checking if remote device folder exists."
    if sftp ${uservar}@frs.sourceforge.net:/home/frs/project/revengeos/${target_device} <<< $'!'; then
        echo "Exists! Proceeding."
    else
        echo "Does not exist. Creating one."
        mkdir ${target_device}
        scp -r ${target_device} ${uservar}@frs.sourceforge.net:/home/frs/p/revengeos
        rm -rf ${target_device}/
    fi
}

push_od() {
    echo "Pushing to Official devices"
    cd $devices_dir
    git add $target_device && git commit -m "Update $target_device"
    git push https://github.com/RevengeOS-Devices/official_devices.git HEAD:master
    cd $mainpath
    rm -rf $devices_dir
}

trigger() {
    echo "Triggering ota_scripts"
    git clone https://github.com/RevengeOS-Devices/ota_scripts.git $ota_scripts
    cd $ota_scripts
    echo "$(date)" > file && git add . && git commit -m "trigger"
    git push https://github.com/RevengeOS-Devices/ota_scripts.git HEAD:master
    cd $mainpath
    rm -rf $ota_scripts
}


if checkconfig; then
    auto_process
else
    manual
fi

if checkupload; then
    read -p 'Enter the zip filename here: ' zipname
    echo "Your file zip will be now downloaded from ROS server. Please, be patient."
    wget http://files.revengeos.com/${target_device}/${zipname}
else
    zipname=$(ls -t RevengeOS*${target_device}*.zip)
fi

if [ "$zipname" == "" ]; then
    echo "Something wrong happened."
    return 0
fi

for s in $(echo $zipname | tr "-" "\n")
do
    a+=("$s")
done

version=${a[1]}
size=$(stat -c%s "$out_dir/$zipname")
md5=$(md5sum "$out_dir/$zipname")

echo -n "Do you want to upload it to SourceForge? (y/n) "
read zipupload_choice
case $zipupload_choice in
    y | Y)
        checkremotedir
        echo "Uploading build to Sourceforge... This may take a while."
        scp $(pwd)/$zipname ${uservar}@frs.sourceforge.net:/home/frs/p/revengeos/$target_device
        ;;
    n | N)
        echo "Okay, won't upload it."
        ;;
    *)
        echo "Try again."
        return 0
        ;;
esac

echo "Generating json"
python3 $(pwd)/tools/generatejson.py $target_device $zipname $version $size $md5
if [ -d "$devices_dir" ]; then
    rm -rf $devices_dir
fi

git clone https://github.com/RevengeOS-Devices/official_devices.git $devices_dir
if [ -d "$devices_dir/$target_device" ]; then
    mv $(pwd)/device.json $devices_dir/$target_device
    mv $(pwd)/changelog.txt $devices_dir/$target_device
else
    mkdir $devices_dir/$target_device
    mv $(pwd)/device.json $devices_dir/$target_device
    mv $(pwd)/changelog.txt $devices_dir/$target_device
fi

if [ -e "$(pwd)/notes.txt" ]; then
	echo "Notes found! Adding 'em to the Telegram's post."
	mv $(pwd)/notes.txt $devices_dir/$target_device
else
	echo "Removing the old notes, if any."
	rm -rf $devices_dir/$target_device/notes.txt
fi

push_od
trigger