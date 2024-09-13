### How to fast build Flatcar

#### Requirements

1. Docker installed and to be able to run `docker run hello-world` from a non-root user
2. QEMU-KVM installed and working to be able to run Flatcar as a VM to test it out

```bash

git clone https://github.com/flatcar/scripts
pushd scripts

./run_sdk_container -t
# it should download the Docker image for the latest SDK and start the docker container and attach to it

# takes around ~2h
./build_packages

# takes around 30 minutes
./build_image

# takes around 5 minutes
# build_image should return this command as output with the proper args. Add compression format to none, so that it is not archived
./image_to_vm.sh --from=../build/images/arm64-usr/developer-latest --compression_format none

pushd ./build/images/arm64-usr/developer-latest
# start a Flatcar VM
# you need QEMU-KVM enabled and working
sudo bash flatcar_production_qemu.sh -nographic
