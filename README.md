# dxc_windows_build

GitHub Actions 仓库：在 Windows 上构建 [DirectXShaderCompiler](https://github.com/microsoft/DirectXShaderCompiler) 并上传二进制产物。

## 工作流

文件：`.github/workflows/build.yml`

| 项 | 说明 |
|----|------|
| Runner | `windows-2022` |
| Generator | Visual Studio 17 2022 |
| 默认 toolset | **v142**（可改 v143） |
| 默认配置 | Release |
| 架构 | x64 |
| 源码 | `microsoft/DirectXShaderCompiler`（workflow 内 checkout） |

### 触发

- `push`
- `workflow_dispatch`（可选手动参数）

### `workflow_dispatch` 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `dxc_ref` | `main` | DXC 分支 / tag / SHA |
| `toolset` | `v142` | `v142` 或 `v143` |
| `configuration` | `Release` | `Release` / `RelWithDebInfo` / `Debug` |
| `build_spirv` | `true` | 是否开 SPIR-V codegen |

### 产物

Artifact 名：`dxc-windows-x64-<toolset>-<configuration>`

通常包含：

- `dxc.exe`
- `dxcompiler.dll`
- `dxv.exe`（如有）
- `dxil.dll`（如有）
- `build-info.txt`

## 本地等价命令

```bat
git clone --recursive https://github.com/microsoft/DirectXShaderCompiler.git
cd DirectXShaderCompiler

cmake -S . -B build ^
  -G "Visual Studio 17 2022" ^
  -A x64 ^
  -T v142 ^
  -DLLVM_INCLUDE_TESTS=OFF ^
  -DCLANG_INCLUDE_TESTS=OFF ^
  -DHLSL_INCLUDE_TESTS=OFF ^
  -DSPIRV_BUILD_TESTS=OFF ^
  -DENABLE_SPIRV_CODEGEN=ON ^
  -DCMAKE_SYSTEM_VERSION=10.0.26100.0 ^
  -C cmake\caches\PredefinedParams.cmake

cmake --build build --config Release --parallel --target dxc dxcompiler dxv dxildll
```

## 备注

- 本仓库本身不包含 DXC 源码，CI 每次从上游拉取。
- 构建较久（常 1h+），workflow `timeout-minutes: 180`。
- ATL 来自本仓库 `atlmfc.7z`：CI 解压后拷贝到选中 MSVC 工具集目录
  `VC\Tools\MSVC\<ver>\atlmfc\{include,lib}`（VS generator 认这个路径）。
- 若 image 上缺少 v142 编译器本身，会装
  `Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64`。
- 也可把 `toolset` 改成 `v143`。
- MSVC 优化 flags：`cmake/DxcMsvcOptFlags.cmake`，CI 会动态注入到 DXC
  `CMakeLists.txt` 的 `project(LLVM)` 之后。

## MSVC flags 冲突审查

| flag | 结论 |
|------|------|
| `/GR-` | **硬冲突**，已剔除。DXC `LLVM_ENABLE_RTTI=ON` + `LLVM_ENABLE_EH=ON` |
| `/MD` `/MDd` | 冗余，CMake/ChooseMSVCCRT 已管 CRT |
| `/Zi`(Debug) | 冗余 |
| `/GL` + `/LTCG` | 与 `LLVM_ENABLE_LTO` 重叠，可加 |
| `/OPT:REF` | 与 HandleLLVMOptions 重叠，可加；`/OPT:ICF` 额外 |
| `/MANIFEST:NO` | 省略，避免砍掉有用 manifest |
| `/Os` | 可能覆盖默认 `/O2`（D9025） |
| `/GS-` | 刻意关 cookie |
| `/arch:AVX2` `/fp:fast` | 无 CMake 冲突；部署/语义需自担 |
| `/guard:cf` `/CETCOMPAT` `/INCREMENTAL:NO` | **上游默认开启，CI 从 CMakeLists 删掉** |
| Release `/Zi` `/DEBUG` | **HandleLLVMOptions 默认强制，CI 删掉 + `/DEBUG:NONE`** |
| `LLVM_ENABLE_ASSERTIONS` | CI 设为 **OFF**（再抠体积/性能） |
| `/MANIFEST:NO` | 开启（更小镜像） |
