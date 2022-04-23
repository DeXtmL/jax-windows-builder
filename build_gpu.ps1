curl -k -L https://github.com/bazelbuild/bazelisk/releases/download/v1.10.1/bazelisk-windows-amd64.exe -o $env:BAZEL_PATH

curl -k -L https://whls.blob.core.windows.net/ci-files/v11.1.7z -o cuda.7z
7z x cuda.7z -o'D:/CUDA'
rm cuda.7z
ls D:/CUDA/v11.1


$cuda_prefix = "D:/CUDA" -replace '\\', '/'
$cuda_version = '11.1'
switch ($cuda_version) {
        '11.2' {
                $cuda_cap = '6.1,7.0,7.5,8.0,8.6'
                $cudnn_version = '8.2.2'
        }
        '11.1' {
                $cuda_cap = '6.1,7.0,7.5,8.0,8.6'
                $cudnn_version = '8.2.2'
        }
        '10.1' {
                $cuda_cap = '6.1,7.0,7.5'
                $cudnn_version = '7.6.5'
        }
}
$cuda_version = [System.Version]$cuda_version
$cudnn_version = [System.Version]$cudnn_version
$cuda_path = "$cuda_prefix/v$cuda_version"
$cudnn_path = $cuda_path

# https://github.com/tensorflow/tensorflow/blob/9e2743271dd09609e8726edaffdd7c6762d3bf05/third_party/gpus/find_cuda_config.py#L26-L33
# and tf 2.0 release note
if ($cuda_path -eq $cudnn_path) {
        # https://github.com/tensorflow/tensorflow/issues/51040
        $env:TF_CUDA_PATHS="$cuda_path"
}
else {
        $env:TF_CUDA_PATHS="$cuda_path,$cudnn_path"
}

# https://github.com/tensorflow/tensorflow/blob/master/third_party/gpus/cuda_configure.bzl
$env:TF_CUDA_COMPUTE_CAPABILITIES = $cuda_cap


$bazel_path = $env:BAZEL_PATH
$pythonBinPath = "C:\Python\python.exe"
$msysPythonBinPath= $pythonBinPath -replace '\\', '/'
$out_path = "C:\Users\Win11Dev\Documents\jax\bzl_out"
python .\build\build.py `
        --enable_cuda `
        --cuda_version="$cuda_version" `
        --cuda_path="$cuda_path" `
        --cudnn_version="$cudnn_version" `
        --cudnn_path="$cudnn_path" `
        --bazel_path="$bazel_path" `
        --bazel_options="--action_env=PYTHON_BIN_PATH=$msysPythonBinPath" `
        --bazel_startup_options="--output_user_root=$out_path"

if ($LASTEXITCODE -ne 0) {
        throw "last command exit with $LASTEXITCODE"
}

if ((ls dist).Count -ne 1) {
        throw "number of whl files != 1"
}
$name = (ls dist)[0].Name
$cuda_dir = "cuda$($cuda_version.Major)$($cuda_version.Minor)"
$cuda_cudnn_tag = "cuda$($cuda_version.Major).cudnn$($cudnn_version.Major)$($cudnn_version.Minor)"
$new_name = $name.Insert($name.IndexOf("-", $name.IndexOf("-") + 1), "+$cuda_cudnn_tag")

mkdir "bazel-dist/$cuda_dir" -ErrorAction 0
mv -Force "dist/$name" "bazel-dist/$cuda_dir/$new_name"