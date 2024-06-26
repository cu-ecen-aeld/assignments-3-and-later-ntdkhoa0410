#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
CC_SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # Remove “deep clean” the kernel build tree - removing the .config file with any existing configurations
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    # Set default config for the kernel build
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    # Build kernel image
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    # Build the device tree
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image  ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p rootfs
cd "${OUTDIR}/rootfs" 
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make -j4 distclean
    make -j4 defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make -j4 CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp     ${CC_SYSROOT}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp     ${CC_SYSROOT}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64
cp     ${CC_SYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64
cp     ${CC_SYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
# TODO: Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make -j4 clean
${CROSS_COMPILE}gcc -o ${OUTDIR}/rootfs/home/writer writer.c

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cd ${FINDER_APP_DIR}
cp   -r * ${OUTDIR}/rootfs/home/
rm ${OUTDIR}/rootfs/home/conf
mkdir -p ${OUTDIR}/rootfs/home/conf
cp   conf/username.txt conf/assignment.txt ${OUTDIR}/rootfs/home/conf/
cp   autorun-qemu.sh $OUTDIR/rootfs/home/

# TODO: Chown the root directory
cd "$OUTDIR/rootfs"
sudo chown -R root:root ${OUTDIR}/rootfs/*
# TODO: Create initramfs.cpio.gz
find . | cpio -H newc -o --owner root:root > ${OUTDIR}/initramfs.cpio
cd "$OUTDIR"
gzip -f initramfs.cpio

