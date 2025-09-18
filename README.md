# Intel Graphics Compiler (IGC) Build Script for Debian 13 (Trixie)

This script builds Debian packages (`intel-igc-core`, `intel-igc-opencl`, `intel-igc-dev`) for the Intel Graphics Compiler (IGC) version 2.14.1, using LLVM 15.0.7, on Debian 13 (Trixie). It is adapted from the official IGC build instructions.

## Prerequisites

- **Operating System**: Debian 13 (Trixie)
- **Hardware**:
  - Recommended: ≥16 GB RAM (for parallel builds with `-j$(nproc)`)
  - Disk space: ~20–30 GB
- **Permissions**: Sudo access for installing dependencies

## Dependencies

The script installs the following packages via `apt`:
- `build-essential`, `cmake`, `git`, `ninja-build`, `bison`, `flex`, `libstdc++-13-dev`, `zlib1g-dev`, `libncurses-dev`, `libelf-dev`, `libpciaccess-dev`, `libdrm-dev`, `libva-dev`, `libnuma-dev`, `libtbb-dev`, `python3`, `python3-mako`, `pkg-config`, `ocl-icd-libopencl1`, `ocl-icd-dev`, `libprotobuf-dev`, `protobuf-compiler`, `libxml2-dev`, `libedit-dev`, `libzstd-dev`, `binutils-gold`

## Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/igc-debian-build.git
   cd igc-debian-build
