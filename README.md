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
