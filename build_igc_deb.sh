#!/bin/bash
# Скрипт для сборки deb-пакетов Intel Graphics Compiler для Debian 13 с использованием CPack.
# Адаптировано из https://github.com/intel/intel-graphics-compiler/blob/master/documentation/build_ubuntu.md
# и https://github.com/intel/intel-graphics-compiler/blob/master/documentation/configuration_flags.md
# Пакеты: intel-igc-core, intel-igc-opencl, intel-igc-dev.
# Сборка LLVM 15 из исходников (llvmorg-15.0.7) для IGC 2.18.5.
# Выполняется от имени пользователя, кроме установки зависимостей.

set -e
set -o pipefail  # Важно для правильной обработки ошибок в пайпах

# Функция для логирования сообщений
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$WORK_DIR/build.log"
}

# Функция для выполнения команд с логированием и проверкой ошибок
run_with_log() {
    local cmd="$1"
    local error_msg="$2"

    log "Выполнение: $cmd"
    if ! eval "$cmd" 2>&1 | tee -a "$WORK_DIR/build.log"; then
        log "ОШИБКА: $error_msg"
        exit 1
    fi
}

# Установка рабочей директории
WORK_DIR="$HOME/apps/igc-build"

# Создание рабочей директории и проверка прав
mkdir -p "$WORK_DIR"
if [ ! -w "$WORK_DIR" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ОШИБКА: Нет прав на запись в $WORK_DIR" >&2
    exit 1
fi

# Создание и проверка лог-файла
touch "$WORK_DIR/build.log" || { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ОШИБКА: Не удалось создать $WORK_DIR/build.log" >&2; exit 1; }
chmod u+rw "$WORK_DIR/build.log" || { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ОШИБКА: Не удалось установить права на $WORK_DIR/build.log" >&2; exit 1; }
: > "$WORK_DIR/build.log"  # Очистка лога

# Проверка на Debian 13 (Trixie)
if ! grep -q "VERSION_CODENAME=trixie" /etc/os-release; then
    log "ОШИБКА: Требуется Debian 13 (Trixie)."
    exit 1
fi

# Проверка версий инструментов
CMAKE_VERSION=$(cmake --version | head -n1 | awk '{print $3}')
NINJA_VERSION=$(ninja --version)
log "Версия CMake: $CMAKE_VERSION"
log "Версия Ninja: $NINJA_VERSION"
if [[ "$CMAKE_VERSION" < "3.18" ]]; then
    log "ОШИБКА: Требуется CMake версии 3.18 или выше."
    exit 1
fi
if [[ "$NINJA_VERSION" < "1.10" ]]; then
    log "ОШИБКА: Требуется Ninja версии 1.10 или выше."
    exit 1
fi

log "Запуск сборки Intel Graphics Compiler с CPack..."

# Установка зависимостей (включая binutils-gold, используем zlib1g-dev)
log "Установка зависимостей (требуется sudo)..."
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    ninja-build \
    bison \
    flex \
    libstdc++-13-dev \
    zlib1g-dev \
    libncurses-dev \
    libelf-dev \
    libpciaccess-dev \
    libdrm-dev \
    libva-dev \
    libnuma-dev \
    libtbb-dev \
    python3 \
    python3-mako \
    pkg-config \
    ocl-icd-libopencl1 \
    ocl-icd-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libxml2-dev \
    libedit-dev \
    libzstd-dev \
    binutils-gold || { log "ОШИБКА: Не удалось установить зависимости"; exit 1; }

cd "$WORK_DIR"

# Клонирование репозиториев согласно документации IGC
run_with_log "git clone https://github.com/intel/vc-intrinsics vc-intrinsics" "Не удалось клонировать vc-intrinsics"
run_with_log "git clone -b llvmorg-15.0.7 https://github.com/llvm/llvm-project llvm-project" "Не удалось клонировать llvm-project"
run_with_log "git clone -b ocl-open-150 https://github.com/intel/opencl-clang llvm-project/llvm/projects/opencl-clang" "Не удалось клонировать opencl-clang"
run_with_log "git clone -b llvm_release_150 https://github.com/KhronosGroup/SPIRV-LLVM-Translator llvm-project/llvm/projects/llvm-spirv" "Не удалось клонировать SPIRV-LLVM-Translator"
run_with_log "git clone https://github.com/KhronosGroup/SPIRV-Tools.git SPIRV-Tools" "Не удалось клонировать SPIRV-Tools"
run_with_log "git clone https://github.com/KhronosGroup/SPIRV-Headers.git SPIRV-Headers" "Не удалось клонировать SPIRV-Headers"
run_with_log "git clone https://github.com/intel/intel-graphics-compiler igc" "Не удалось клонировать intel-graphics-compiler"

cd igc
run_with_log "git fetch --all --tags --prune" "Не удалось обновить теги репозитория igc"
run_with_log "git checkout tags/v2.18.5 -b 2.18.5" "Не удалось переключиться на тег v2.18.5"

# Сборка LLVM 15.0.7 из исходников (без openmp)
log "Сборка LLVM 15.0.7 из исходников..."
cd "$WORK_DIR/llvm-project"
mkdir -p build && cd build
run_with_log "cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS='clang' \
    -DCMAKE_INSTALL_PREFIX=$WORK_DIR/llvm-install \
    -DCMAKE_EXE_LINKER_FLAGS='-fuse-ld=gold' \
    ../llvm" "Не удалось выполнить конфигурацию CMake для LLVM"
run_with_log "ninja -j4" "Не удалось выполнить сборку LLVM"  # Используйте -j$(nproc) если RAM >=16GB
run_with_log "ninja install" "Не удалось установить LLVM"

# Сборка IGC с использованием собранного LLVM
log "Сборка Intel Graphics Compiler..."
cd "$WORK_DIR/igc"
mkdir -p build && cd build
run_with_log "cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DIGC_OPTION__LLVM_MODE=Source \
    -DLLVM_DIR=$WORK_DIR/llvm-project/build/lib/cmake/llvm \
    -DOPENCL_CLANG_DIR=$WORK_DIR/llvm-project/llvm/projects/opencl-clang \
    -DLLVMSPIRVLib_DIR=$WORK_DIR/llvm-project/llvm/projects/llvm-spirv \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCPACK_GENERATOR=DEB \
    -DCPACK_PACKAGE_NAME=intel-igc \
    -DCPACK_PACKAGE_VERSION=2.18.5 \
    -DCPACK_PACKAGE_CONTACT='Intel Graphics Compiler Team <graphics@intel.com>' \
    -DCPACK_PACKAGE_DESCRIPTION_SUMMARY='Intel Graphics Compiler for OpenCL' \
    -DCPACK_DEBIAN_PACKAGE_MAINTAINER='Intel Corporation' \
    -DCPACK_DEBIAN_PACKAGE_SECTION='libs' \
    -DCPACK_DEBIAN_PACKAGE_SHLIBDEPS=ON \
    -DCPACK_COMPONENTS_ALL='core;opencl;dev' \
    -DCPACK_DEB_COMPONENT_INSTALL=ON \
    -DCPACK_DEBIAN_CORE_PACKAGE_NAME='intel-igc-core' \
    -DCPACK_DEBIAN_OPENCL_PACKAGE_NAME='intel-igc-opencl' \
    -DCPACK_DEBIAN_DEV_PACKAGE_NAME='intel-igc-dev' \
    -DCPACK_DEBIAN_CORE_PACKAGE_DEPENDS='ocl-icd-libopencl1, libstdc++6, zlib1g' \
    -DCPACK_DEBIAN_OPENCL_PACKAGE_DEPENDS='intel-igc-core, ocl-icd-libopencl1' \
    -DCPACK_DEBIAN_DEV_PACKAGE_DEPENDS='intel-igc-core, intel-igc-opencl, libstdc++-13-dev'" \
    "Не удалось выполнить конфигурацию CMake для IGC"

# Сборка проекта
run_with_log "ninja -j$(nproc)" "Не удалось выполнить сборку IGC"

# Создание deb-пакетов
touch "$WORK_DIR/igc/build/postrm"
run_with_log "cpack -G DEB" "Не удалось создать deb-пакеты"

log "Сборка завершена успешно. Пакеты intel-igc-core.deb, intel-igc-opencl.deb, intel-igc-dev.deb созданы в $WORK_DIR/igc/build"

