# Intel Graphics Compiler (IGC) Build Script for Debian 13 (Trixie)

This repository provides a Bash script to build Debian packages for the Intel Graphics Compiler (IGC) version 2.14.1, using LLVM 15.0.7, on Debian 13 (Trixie). The script generates the following packages:
- `intel-igc-core`
- `intel-igc-opencl`
- `intel-igc-dev`

The build process is adapted from the official IGC documentation:
- [build_ubuntu.md](https://github.com/intel/intel-graphics-compiler/blob/master/documentation/build_ubuntu.md)
- [configuration_flags.md](https://github.com/intel/intel-graphics-compiler/blob/master/documentation/configuration_flags.md)

## Generated Packages Location

After a successful build, the Debian packages (`*.deb` and debug symbol packages `*.ddeb`) are created in the following directory:

**`$HOME/apps/igc-build/igc/build`**

The packages include:
- `intel-igc-core-2_2.14.0-dev.0_amd64.deb`
- `intel-igc-opencl-2_2.14.0-dev.0_amd64.deb`
- `intel-igc-opencl-devel_2.14.0-dev.0_amd64.deb`
- Corresponding debug symbol packages (`*.ddeb`)

## Prerequisites

### Operating System
- Debian 13 (Trixie)

### Hardware Requirements
- **RAM**: ≥8 GB is sufficient for the build process. The script uses `-j4` for LLVM to minimize memory usage.
- **Disk Space**: ~20–30 GB free space for source code, build artifacts, and packages.

### Permissions
- Sudo access is required to install dependencies via `apt`.

## Dependencies

The script automatically installs the following Debian packages:
- `build-essential`
- `cmake` (≥3.18)
- `git`
- `ninja-build` (≥1.10)
- `bison`
- `flex`
- `libstdc++-13-dev`
- `zlib1g-dev`
- `libncurses-dev`
- `libelf-dev`
- `libpciaccess-dev`
- `libdrm-dev`
- `libva-dev`
- `libnuma-dev`
- `libtbb-dev`
- `python3`
- `python3-mako`
- `pkg-config`
- `ocl-icd-libopencl1`
- `ocl-icd-dev`
- `libprotobuf-dev`
- `protobuf-compiler`
- `libxml2-dev`
- `libedit-dev`
- `libzstd-dev`
- `binutils-gold`

Ensure your `/etc/apt/sources.list` includes the following line to access these packages:
```bash
deb http://deb.debian.org/debian trixie main contrib non-free
```

Run `sudo apt update` to refresh the package lists.

## Installation and Usage

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/igc-debian-build.git
   cd igc-debian-build
   ```

2. **Make the Script Executable**
   ```bash
   chmod +x build_igc_deb.sh
   ```

3. **Run the Script**
   ```bash
   ./build_igc_deb.sh
   ```

4. **Check the Output**
   - The script will create the working directory `$HOME/apps/igc-build`.
   - Build logs are saved to `$HOME/apps/igc-build/build.log`.
   - Upon successful completion, the Debian packages will be located in `$HOME/apps/igc-build/igc/build`.

5. **Install the Generated Packages**
   After the build, you can install the packages using:
   ```bash
   sudo dpkg -i $HOME/apps/igc-build/igc/build/*.deb
   sudo apt-get install -f  # To resolve any missing dependencies
   ```

## Notes

- **Build Performance**: The script uses `ninja -j4` for LLVM to minimize memory usage on systems with 8 GB RAM. For faster builds on systems with ≥8 GB RAM, you can edit `build_igc_deb.sh` to replace `-j4` with `-j$(nproc)` in the LLVM build step.
- **CPack Warning**: You may encounter a CPack warning about a missing `postrm` file. This is non-critical and does not affect the functionality of the generated packages.
- **Repository Configuration**: Ensure your system is configured for Debian 13 (Trixie) with `main`, `contrib`, and `non-free` repositories enabled.
- **Gold Linker**: The script uses the `gold` linker (`-fuse-ld=gold`) for LLVM to ensure compatibility. The `binutils-gold` package is included in the dependencies.

## Troubleshooting

- **Build Fails**: Check the build log at `$HOME/apps/igc-build/build.log` for detailed error messages. Common issues include:
  - Missing dependencies: Run `sudo apt install -y <package-list>` to ensure all dependencies are installed.
  - Insufficient memory: Verify with `free -h`. The script is optimized for 8 GB RAM with `-j4`.
  - Insufficient disk space: Check with `df -h`. Ensure ~20–30 GB is available.
- **Dependency Installation Fails**: Verify your `sources.list` and run `sudo apt update`. Check package availability with `apt search <package>`.
- **CPack Issues**: If CPack fails to generate packages, ensure `cmake` and `ninja` versions meet the requirements (CMake ≥3.18, Ninja ≥1.10).

For further assistance, open an issue on this repository with the relevant log output.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Intel Graphics Compiler: [https://github.com/intel/intel-graphics-compiler](https://github.com/intel/intel-graphics-compiler)
- LLVM Project: [https://github.com/llvm/llvm-project](https://github.com/llvm/llvm-project)
- Based on Intel's official build instructions: [build_ubuntu.md](https://github.com/intel/intel-graphics-compiler/blob/master/documentation/build_ubuntu.md)

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bug reports, improvements, or feature requests.