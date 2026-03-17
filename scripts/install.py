#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OpenClaw Harmony Security Plugin 一键安装脚本（含 MCP Adapter 集成）
跨平台统一安装逻辑
"""

import os
import sys
import subprocess
import json
import shutil
import platform
from pathlib import Path
from urllib.request import urlopen
from tempfile import mkstemp

# Windows 控制台编码修复
if platform.system() == "Windows":
    try:
        import locale
        import codecs
        sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
        sys.stderr = codecs.getwriter("utf-8")(sys.stderr.detach())
    except:
        # 如果上述方法失败，设置环境变量
        os.environ['PYTHONIOENCODING'] = 'utf-8'

# 颜色输出（跨平台）
class Colors:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

    @staticmethod
    def green(text):
        return f"{Colors.GREEN}{text}{Colors.NC}"

    @staticmethod
    def yellow(text):
        return f"{Colors.YELLOW}{text}{Colors.NC}"

    @staticmethod
    def red(text):
        return f"{Colors.RED}{text}{Colors.NC}"

    @staticmethod
    def blue(text):
        return f"{Colors.BLUE}{text}{Colors.NC}"


def run_command(cmd, check=True, capture=False, cwd=None):
    """运行命令并返回结果"""
    print(f"  $ {' '.join(cmd)}")
    try:
        if capture:
            result = subprocess.run(
                cmd,
                check=check,
                capture_output=True,
                text=True,
                shell=platform.system() == "Windows",
                cwd=cwd
            )
            return result.stdout.strip()
        else:
            subprocess.run(
                cmd,
                check=check,
                shell=platform.system() == "Windows",
                cwd=cwd
            )
    except subprocess.CalledProcessError as e:
        if check:
            print(Colors.red(f"Command failed: {e}"))
            sys.exit(1)
        return None


def print_header():
    """打印标题"""
    print()
    print("=" * 60)
    print("  OpenClaw Harmony Security Plugin 安装脚本")
    print("        (含 MCP Adapter 集成)")
    print("=" * 60)
    print()


def print_step(step_num, total, description):
    """打印步骤"""
    print()
    print(Colors.blue(f"[{step_num}/{total}] {description}"))


def get_project_dir():
    """获取项目目录"""
    script_dir = Path(__file__).parent.absolute()
    project_dir = script_dir.parent
    print(f"项目目录: {project_dir}")
    return project_dir


def check_openclaw_cli():
    """检查 OpenClaw CLI 是否安装"""
    print(Colors.blue("检查 OpenClaw CLI..."))

    result = run_command(["openclaw", "--version"], check=False, capture=True)
    if result:
        print(Colors.green("✓ OpenClaw CLI 已安装"))
        print(f"   版本: {result.split()[0] if result else 'unknown'}")
        return True

    print(Colors.red("❌ OpenClaw CLI 未安装"))
    print("请先安装: npm install -g @openclaw/cli")
    sys.exit(1)


def install_dependencies(project_dir):
    """安装项目依赖"""
    print_step(1, 11, "安装项目依赖")

    run_command(["npm", "install"], cwd=project_dir)
    print(Colors.green("✓ 依赖安装完成"))


def build_project(project_dir):
    """构建项目"""
    print_step(2, 11, "构建项目")

    run_command(["npm", "run", "build"], cwd=project_dir)
    print(Colors.green("✓ 项目构建完成"))


def create_data_directories(project_dir):
    """创建数据目录"""
    print_step(3, 11, "创建数据目录")

    data_dirs = [
        project_dir / "data" / "samples",
        project_dir / "data" / "knowledge",
        project_dir / "data" / "reports"
    ]

    for dir_path in data_dirs:
        dir_path.mkdir(parents=True, exist_ok=True)

    print(Colors.green("✓ 数据目录创建完成"))


def check_or_clone_mcp_adapter(project_dir):
    """检查或克隆 MCP Adapter"""
    print_step(4, 11, "检查 MCP Adapter")

    mcp_adapter_dir = project_dir.parent / "openclaw-mcp-adapter"

    if mcp_adapter_dir.exists():
        print(Colors.green("✓ MCP Adapter 已存在"))
        return str(mcp_adapter_dir)

    print(Colors.yellow("⚠️  MCP Adapter 未找到，正在克隆..."))

    # git clone <repo> <destination_dir>
    # destination_dir 会自动创建
    run_command([
        "git", "clone",
        "https://github.com/androidStern-personal/openclaw-mcp-adapter.git",
        str(mcp_adapter_dir)
    ])

    print(Colors.green("✓ MCP Adapter 克隆完成"))
    return str(mcp_adapter_dir)


def stop_gateway():
    """停止现有 Gateway"""
    print_step(5, 11, "停止现有 Gateway (如果正在运行)")

    run_command(["openclaw", "gateway", "stop"], check=False)

    # 等待进程停止
    import time
    time.sleep(2)

    print(Colors.green("✓ Gateway 已停止"))


def remove_old_plugins():
    """移除旧插件目录"""
    print()
    print("  清理旧插件目录...")

    def handle_remove_readonly(func, path, exc):
        """处理 Windows 只读文件"""
        import stat
        os.chmod(path, stat.S_IWRITE)
        func(path)

    home = Path.home()
    old_plugins = [
        home / ".openclaw" / "extensions" / "harmony-security",
        home / ".openclaw" / "extensions" / "openclaw-mcp-adapter"
    ]

    for plugin_path in old_plugins:
        if plugin_path.exists():
            try:
                shutil.rmtree(plugin_path, onerror=handle_remove_readonly)
                print(f"    已删除: {plugin_path.name}")
            except Exception as e:
                print(Colors.yellow(f"    跳过 {plugin_path.name}: {e}"))

    print(Colors.green("  ✓ 清理完成"))


def fix_config():
    """修复配置文件"""
    print_step(9, 11, "修复配置文件")

    # 运行 doctor --fix 自动修复
    run_command(["openclaw", "doctor", "--fix"], check=False)

    # 手动清理 plugins.allow 中的无效条目
    openclaw_config = get_openclaw_config_path()
    if openclaw_config.exists():
        with open(openclaw_config, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 清理 plugins.allow 中的无效插件
        if "plugins" in data and "allow" in data["plugins"]:
            invalid_plugins = []
            valid_plugins = []

            # 检查哪些插件实际存在
            ext_dir = Path.home() / ".openclaw" / "extensions"
            for plugin_id in data["plugins"]["allow"]:
                plugin_dir = ext_dir / plugin_id
                if not plugin_dir.exists():
                    invalid_plugins.append(plugin_id)
                else:
                    valid_plugins.append(plugin_id)

            # 移除无效插件
            for plugin_id in invalid_plugins:
                print(f"    移除无效插件引用: {plugin_id}")

            data["plugins"]["allow"] = valid_plugins

            # 保存配置
            with open(openclaw_config, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

    print(Colors.green("  ✓ 配置已修复"))


def install_plugins(project_dir, mcp_adapter_dir):
    """安装插件"""
    print_step(6, 11, "安装插件")

    plugin_dir = project_dir / "plugins" / "openclaw-harmony-security"

    # 检查插件文件
    if not (plugin_dir / "index.js").exists():
        print(Colors.red(f"❌ 插件入口文件缺失: {plugin_dir / 'index.js'}"))
        sys.exit(1)

    if not (plugin_dir / "openclaw.plugin.json").exists():
        print(Colors.red(f"❌ 插件清单文件缺失: {plugin_dir / 'openclaw.plugin.json'}"))
        sys.exit(1)

    print(Colors.green("✓ 插件文件检查通过"))

    # 安装 harmony-security 插件
    print()
    print("  安装 harmony-security 插件...")
    run_command(["openclaw", "plugins", "install", str(plugin_dir)])
    run_command(["openclaw", "plugins", "enable", "harmony-security"])
    print(Colors.green("  ✓ harmony-security 已启用"))

    # 安装 MCP Adapter 插件
    print()
    print("  安装 mcp-adapter 插件...")
    run_command(["openclaw", "plugins", "install", str(mcp_adapter_dir)])
    print(Colors.green("  ✓ mcp-adapter 已安装"))

    print()
    print(Colors.green("✓ 所有插件安装完成"))


def configure_mcp_servers(project_dir):
    """配置 MCP Servers"""
    print_step(7, 11, "配置 MCP Servers")

    # 转换路径为字符串，使用正斜杠（跨平台兼容）
    project_str = str(project_dir).replace("\\", "/")

    config = {
        "servers": [
            {
                "name": "sample-store",
                "transport": "stdio",
                "command": "node",
                "args": [f"{project_str}/dist/mcp/sample-store/index.js"],
                "env": {"SAMPLE_STORE_PATH": f"{project_str}/data/samples"}
            },
            {
                "name": "knowledge-base",
                "transport": "stdio",
                "command": "node",
                "args": [f"{project_str}/dist/mcp/knowledge-base/index.js"],
                "env": {"KNOWLEDGE_BASE_PATH": f"{project_str}/data/knowledge"}
            },
            {
                "name": "report-store",
                "transport": "stdio",
                "command": "node",
                "args": [f"{project_str}/dist/mcp/report-store/index.js"],
                "env": {"REPORT_OUTPUT_PATH": f"{project_str}/data/reports"}
            }
        ]
    }

    # 检查是否安装了 jq
    jq_available = shutil.which("jq") is not None

    if jq_available:
        print("检测到 jq，自动配置...")
        configure_with_jq(config)
    else:
        print(Colors.yellow("⚠️  jq 未安装，尝试使用 Python 配置..."))
        try:
            configure_with_python(config)
        except Exception as e:
            print(Colors.red(f"自动配置失败: {e}"))
            print_manual_config(project_str)
            input("\n配置完成后按回车键继续...")

    print(Colors.green("✓ MCP Servers 配置完成"))


def configure_with_jq(config):
    """使用 jq 配置"""
    import json

    openclaw_config = get_openclaw_config_path()

    # 构造 jq 查询
    jq_query = f'''
    .plugins.entries["openclaw-mcp-adapter"].config = {json.dumps(config)} |
        .plugins.entries["openclaw-mcp-adapter"].enabled = true
    '''

    # 使用临时文件
    with mkstemp(suffix=".json") as (fd, temp_path):
        os.close(fd)
        try:
            subprocess.run([
                "jq", jq_query, str(openclaw_config)
            ], check=True, capture_output=True, stdout=open(temp_path, 'w'))

            # 备份原文件
            backup_path = str(openclaw_config) + ".backup"
            shutil.copy2(openclaw_config, backup_path)

            # 替换配置文件
            shutil.move(temp_path, openclaw_config)
            print(Colors.green("  ✓ 配置已更新"))
            print(f"  备份: {backup_path}")
        except Exception as e:
            os.unlink(temp_path)
            raise


def configure_with_python(config):
    """使用 Python 配置"""
    openclaw_config = get_openclaw_config_path()

    with open(openclaw_config, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 确保 plugins.entries 存在
    if "plugins" not in data:
        data["plugins"] = {}
    if "entries" not in data["plugins"]:
        data["plugins"]["entries"] = {}

    # 配置 mcp-adapter
    if "openclaw-mcp-adapter" not in data["plugins"]["entries"]:
        data["plugins"]["entries"]["openclaw-mcp-adapter"] = {}

    data["plugins"]["entries"]["openclaw-mcp-adapter"]["enabled"] = True
    data["plugins"]["entries"]["openclaw-mcp-adapter"]["config"] = config

    # 备份原文件
    backup_path = str(openclaw_config) + ".backup"
    shutil.copy2(openclaw_config, backup_path)

    # 写入新配置
    with open(openclaw_config, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(Colors.green("  ✓ 配置已更新"))
    print(f"  备份: {backup_path}")


def print_manual_config(project_str):
    """打印手动配置说明"""
    print()
    print("=" * 60)
    print("请手动添加以下配置到 ~/.openclaw/openclaw.json:")
    print("=" * 60)
    print()

    config_example = {
        "openclaw-mcp-adapter": {
            "enabled": True,
            "config": {
                "servers": [
                    {
                        "name": "sample-store",
                        "transport": "stdio",
                        "command": "node",
                        "args": [f"{project_str}/dist/mcp/sample-store/index.js"],
                        "env": {"SAMPLE_STORE_PATH": f"{project_str}/data/samples"}
                    },
                    {
                        "name": "knowledge-base",
                        "transport": "stdio",
                        "command": "node",
                        "args": [f"{project_str}/dist/mcp/knowledge-base/index.js"],
                        "env": {"KNOWLEDGE_BASE_PATH": f"{project_str}/data/knowledge"}
                    },
                    {
                        "name": "report-store",
                        "transport": "stdio",
                        "command": "node",
                        "args": [f"{project_str}/dist/mcp/report-store/index.js"],
                        "env": {"REPORT_OUTPUT_PATH": f"{project_str}/data/reports"}
                    }
                ]
            }
        }
    }

    print(json.dumps(config_example, indent=2))
    print()


def get_openclaw_config_path():
    """获取 OpenClaw 配置文件路径"""
    home = Path.home()
    return home / ".openclaw" / "openclaw.json"


def start_gateway():
    """启动 Gateway"""
    print_step(8, 11, "启动 Gateway")

    import time

    # 查找 openclaw 命令路径
    openclaw_cmd = "openclaw"
    if platform.system() == "Windows":
        # Windows 上可能需要完整路径
        openclaw_paths = [
            Path(os.environ.get("USERPROFILE", "")) / "AppData" / "Roaming" / "npm" / "openclaw.cmd",
            Path("C:/Users") / os.environ.get("USERNAME", "") / "AppData" / "Roaming" / "npm" / "openclaw.cmd",
        ]
        for path in openclaw_paths:
            if path.exists():
                openclaw_cmd = str(path)
                break
        else:
            # 尝试 which 命令
            result = run_command(["where", "openclaw"], capture=True, check=False)
            if result:
                openclaw_cmd = result.split('\n')[0].strip()

    # 后台启动
    if platform.system() == "Windows":
        log_file = Path(os.environ.get("TEMP", "/tmp")) / "openclaw-gateway.log"
        subprocess.Popen(
            [openclaw_cmd, "gateway"],
            stdout=open(log_file, 'w'),
            stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW,
            shell=True
        )
    else:
        log_file = Path("/tmp/openclaw-gateway.log")
        subprocess.Popen(
            [openclaw_cmd, "gateway"],
            stdout=open(log_file, 'w'),
            stderr=subprocess.STDOUT
        )

    time.sleep(5)
    print(Colors.green("✓ Gateway 已启动"))
    print(f"  日志: {log_file}")


def verify_installation():
    """验证安装"""
    print_step(10, 11, "验证安装")
    print()

    # 获取插件列表
    result = run_command(["openclaw", "plugins", "list"], capture=True, check=False)

    # 检查 harmony-security
    print("Harmony Security 插件状态:")
    if "harmony-security" in result and "loaded" in result:
        print(Colors.green("  ✅ 已加载"))
        for line in result.split('\n'):
            if 'HarmonyOS' in line or 'harmony-security' in line:
                print(f"    {line.strip()}")
    else:
        print(Colors.red("  ❌ 未加载"))
    print()

    # 检查 MCP Adapter
    print("MCP Adapter 插件状态:")
    if "openclaw-mcp-adapter" in result and "loaded" in result:
        print(Colors.green("  ✅ 已加载"))
        for line in result.split('\n'):
            if 'MCP Adapter' in line or 'mcp-adapter' in line:
                print(f"    {line.strip()}")
    else:
        print(Colors.red("  ❌ 未加载"))
    print()

    # 显示已注册的工具
    print("=" * 60)
    print("📊 已注册的 MCP 工具:")
    print("  • sample-store: 6 个工具 (样本信息、代码、报告)")
    print("  • knowledge-base: 1 个工具 (HATL 查询)")
    print("  • report-store: 2 个工具 (报告存储)")
    print("=" * 60)


def print_completion():
    """打印完成信息"""
    print()
    print("=" * 60)
    print(Colors.green("🎉 安装完成！"))
    print("=" * 60)
    print()
    print("📖 使用说明:")
    print("  1. 访问 http://localhost:18789 查看 Gateway Control UI")
    print("  2. Agent 现在可以直接调用 MCP 工具：")
    print("     - sample-store_get_sample_info")
    print("     - knowledge-base_query_hatl")
    print("     - report-store_save_report")
    print("     - 等 9 个工具...")
    print()

    if platform.system() == "Windows":
        print("  查看日志: type %TEMP%\\openclaw-gateway.log")
    else:
        print("  查看日志: tail -f /tmp/openclaw-gateway.log")
    print()


def main():
    """主函数"""
    try:
        print_header()

        # 获取项目目录
        project_dir = get_project_dir()

        # 检查 OpenClaw CLI
        check_openclaw_cli()

        # 安装依赖
        install_dependencies(project_dir)

        # 构建项目
        build_project(project_dir)

        # 创建数据目录
        create_data_directories(project_dir)

        # 检查/克隆 MCP Adapter
        mcp_adapter_dir = check_or_clone_mcp_adapter(project_dir)

        # 停止 Gateway
        stop_gateway()

        # 清理旧插件
        remove_old_plugins()

        # 修复配置
        fix_config()

        # 配置 MCP Servers（在安装插件之前配置，避免"未配置"警告）
        configure_mcp_servers(project_dir)

        # 安装插件
        install_plugins(project_dir, mcp_adapter_dir)

        # 启动 Gateway
        start_gateway()

        # 验证安装
        verify_installation()

        # 打印完成信息
        print_completion()

    except KeyboardInterrupt:
        print()
        print(Colors.yellow("安装已取消"))
        sys.exit(1)
    except Exception as e:
        print()
        print(Colors.red(f"安装失败: {e}"))
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
