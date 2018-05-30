REM Modifies the number of CPUs and Memory assigned to the virtual machine that runs docker
docker-machine stop
"c:/Program Files/Oracle/VirtualBox/VBoxManage" modifyvm default --cpus 6
"c:/Program Files/Oracle/VirtualBox/VBoxManage" modifyvm default --memory 6144
docker-machine start
