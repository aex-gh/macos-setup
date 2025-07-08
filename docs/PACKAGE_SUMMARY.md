# Homebrew Package Summary

Comprehensive overview of all packages installed across different profiles and hardware configurations in this dotfiles repository.

## Overview

This dotfiles system includes **5 Brewfiles** with hardware-optimised configurations:
- **Base Brewfile**: Core tools for all systems
- **Development Profile**: Enhanced development tools
- **Data Science Profile**: ML/AI and analytics stack
- **Minimal Profile**: Essential tools only
- **Hardware-Specific**: MacBook Pro, Mac Studio, Mac Mini optimisations

---

## 📦 Package Categories

### 🔧 Core System Tools

Essential command-line utilities that enhance the macOS experience.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `git` | Distributed version control system | All | ~50MB | https://git-scm.com |
| `curl` | HTTP client and library | All | ~8MB | https://curl.se |
| `openssh` | SSH connectivity tools | All | ~15MB | https://www.openssh.com |
| `grep` | GNU grep (enhanced pattern matching) | All | ~5MB | https://www.gnu.org/software/grep |
| `rsync` | File synchronisation utility | Base | ~12MB | https://rsync.samba.org |
| `unzip` | Archive extraction utility | All | ~3MB | https://infozip.sourceforge.net |
| `tree` | Directory structure visualisation | All | ~2MB | http://mama.indstate.edu/users/ice/tree |
| `mas` | Mac App Store command-line interface | Base | ~8MB | https://github.com/mas-cli/mas |

### 🚀 Modern CLI Replacements

Next-generation command-line tools that improve productivity.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `eza` | Modern `ls` replacement with colours and icons | All | ~5MB | https://github.com/eza-community/eza |
| `bat` | Syntax-highlighted `cat` replacement | All | ~8MB | https://github.com/sharkdp/bat |
| `fzf` | Fuzzy finder for interactive selection | All | ~10MB | https://github.com/junegunn/fzf |
| `ripgrep` | Ultra-fast grep replacement in Rust | Base | ~6MB | https://github.com/BurntSushi/ripgrep |
| `fd` | Modern `find` replacement | Base | ~4MB | https://github.com/sharkdp/fd |
| `delta` | Syntax-highlighting pager for git | Base | ~12MB | https://github.com/dandavison/delta |
| `zoxide` | Smarter `cd` command with frecency | Base | ~4MB | https://github.com/ajeetdsouza/zoxide |
| `duf` | Modern `df` replacement | Base | ~3MB | https://github.com/muesli/duf |

### 🐍 Python Development
**Estimated disk usage**: ~800MB-1.2GB

Modern Python development environment built around `uv` and `ruff`.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `python@3.11` | Python 3.11 LTS for stability | Base | ~180MB | https://www.python.org |
| `python@3.12` | Latest Python release | Base | ~185MB | https://www.python.org |
| `uv` | Ultra-fast Python package installer, virtual env manager, and project tool | Base | ~25MB | https://github.com/astral-sh/uv |
| `ruff` | Extremely fast Python linter and formatter (replaces black, flake8, mypy) | Base | ~15MB | https://github.com/astral-sh/ruff |

**Note**: `uv` replaces `pipx`, `poetry`, and `pyenv` by providing:
- **Package management**: `uv pip install` (faster than pip)
- **Virtual environments**: `uv venv` (faster than venv)
- **Project management**: `uv init`, `uv add` (replaces poetry)
- **Python version management**: `uv python install` (replaces pyenv)
- **Tool installation**: `uv tool install` (replaces pipx)

### 🌐 Node.js & JavaScript

Modern JavaScript development environment.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `node` | JavaScript runtime built on V8 | Base | ~120MB | https://nodejs.org |
| `npm` | Node.js package manager | Base | ~35MB | https://www.npmjs.com |
| `yarn` | Fast, reliable package manager | Development | ~25MB | https://yarnpkg.com |
| `pnpm` | Fast, disk space efficient package manager | Development | ~20MB | https://pnpm.io |

### 🗄️ Databases & Data Stores
**Estimated disk usage**: ~2-4GB (varies significantly by profile)

Database systems for development and production use.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `postgresql@15` | Object-relational database system | Development | ~240MB | https://www.postgresql.org |
| `mysql` | Open source relational database | Development | ~380MB | https://www.mysql.com |
| `redis` | In-memory data structure store | Development | ~45MB | https://redis.io |
| `sqlite` | Lightweight, serverless database | Base | ~8MB | https://www.sqlite.org |
| `mongodb-community` | Document-oriented NoSQL database | Data Science | ~450MB | https://www.mongodb.com |
| `elasticsearch` | Distributed search and analytics engine | Data Science | ~800MB | https://www.elastic.co |
| `influxdb` | Time series database | Data Science | ~120MB | https://www.influxdata.com |
| `neo4j` | Graph database platform | Data Science | ~350MB | https://neo4j.com |
| `duckdb` | In-process analytical database | Data Science | ~25MB | https://duckdb.org |
| `clickhouse` | Columnar database for analytics | Mac Studio | ~650MB | https://clickhouse.com |

### 🔬 Data Science & Machine Learning
**Estimated disk usage**: ~8-15GB (largest category)

Comprehensive tools for data analysis, machine learning, and scientific computing.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `r` | Statistical computing language | Data Science | ~280MB | https://www.r-project.org |
| `julia` | High-performance technical computing | Data Science | ~450MB | https://julialang.org |
| `scala` | Object-functional programming language | Data Science | ~320MB | https://www.scala-lang.org |
| `apache-spark` | Unified analytics engine for big data | Data Science | ~800MB | https://spark.apache.org |
| `apache-airflow` | Platform for workflow management | Data Science | ~600MB | https://airflow.apache.org |
| `kafka` | Distributed streaming platform | Data Science | ~180MB | https://kafka.apache.org |
| `openblas` | Optimised BLAS library | Data Science | ~45MB | https://www.openblas.net |
| `opencv` | Computer vision and machine learning library | Data Science | ~2.1GB | https://opencv.org |
| `gdal` | Geospatial data abstraction library | Data Science | ~450MB | https://gdal.org |
| `hdf5` | High-performance data management library | Data Science | ~80MB | https://www.hdfgroup.org |

### 🛠️ Development Tools
**Estimated disk usage**: ~3-6GB (includes Docker and container tools)

Essential tools for software development and DevOps.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `gh` | GitHub CLI | Base | ~45MB | https://cli.github.com |
| `jq` | Lightweight JSON processor | All | ~5MB | https://jqlang.github.io/jq |
| `yq` | YAML, JSON, XML processor | Base | ~12MB | https://github.com/mikefarah/yq |
| `direnv` | Environment variable management | Base | ~8MB | https://direnv.net |
| `tmux` | Terminal multiplexer | Base | ~15MB | https://github.com/tmux/tmux |
| `neovim` | Hyperextensible Vim-based text editor | Base | ~45MB | https://neovim.io |
| `docker` | Container platform | Development | ~2.8GB | https://www.docker.com |
| `kubernetes-cli` | Kubernetes command-line tool | Development | ~120MB | https://kubernetes.io |
| `terraform` | Infrastructure as code | Development | ~85MB | https://www.terraform.io |
| `ansible` | IT automation platform | Development | ~250MB | https://www.ansible.com |
| `helm` | Kubernetes package manager | Development | ~50MB | https://helm.sh |

### 🎯 CI/CD & Code Quality

Tools for continuous integration, deployment, and code quality.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `pre-commit` | Git pre-commit hook framework | Development | ~35MB | https://pre-commit.com |
| `commitizen` | Conventional commit message tool | Development | ~25MB | https://commitizen-tools.github.io |
| `gitleaks` | Git secrets scanner | Development | ~15MB | https://github.com/gitleaks/gitleaks |
| `act` | Run GitHub Actions locally | Development | ~30MB | https://github.com/nektos/act |
| `shellcheck` | Shell script static analysis | Base | ~8MB | https://www.shellcheck.net |

### ☁️ Cloud Tools

Command-line interfaces for major cloud platforms.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `awscli` | Amazon Web Services CLI | Data Science | ~320MB | https://aws.amazon.com/cli |
| `google-cloud-sdk` | Google Cloud Platform CLI | Data Science | ~850MB | https://cloud.google.com/sdk |
| `azure-cli` | Microsoft Azure CLI | Data Science | ~450MB | https://docs.microsoft.com/cli/azure |

### 🌐 Web Development

Tools for web server configuration and API development.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `nginx` | High-performance web server | Development | ~25MB | https://nginx.org |
| `caddy` | Web server with automatic HTTPS | Development | ~40MB | https://caddyserver.com |
| `httpie` | User-friendly HTTP client | Development | ~55MB | https://httpie.io |
| `ngrok` | Secure tunnels to localhost | Development | ~15MB | https://ngrok.com |
| `mkcert` | Simple tool for making locally-trusted certificates | Development | ~8MB | https://github.com/FiloSottile/mkcert |

### 📱 Mobile Development

Tools for iOS, Android, and cross-platform mobile development.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `ios-deploy` | Deploy iOS apps from command line | MacBook Pro | ~25MB | https://github.com/ios-control/ios-deploy |
| `ideviceinstaller` | Install apps on iOS devices | MacBook Pro | ~35MB | https://github.com/libimobiledevice/ideviceinstaller |
| `watchman` | File watching service for React Native | MacBook Pro | ~45MB | https://facebook.github.io/watchman |
| `cocoapods` | Dependency manager for Swift/Objective-C | MacBook Pro | ~180MB | https://cocoapods.org |
| `fastlane` | Mobile app deployment automation | MacBook Pro | ~250MB | https://fastlane.tools |
| `cordova` | Mobile app development framework | MacBook Pro | ~120MB | https://cordova.apache.org |

### 🎨 Media & Creative Tools

Tools for image, video, and audio processing.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `imagemagick` | Image manipulation tools | Base | ~280MB | https://imagemagick.org |
| `ffmpeg` | Multimedia framework | Base | ~850MB | https://ffmpeg.org |
| `youtube-dl` | Download videos from YouTube and other sites | Mac Mini | ~35MB | https://youtube-dl.org |
| `imageoptim-cli` | Image optimisation command line | Development | ~25MB | https://github.com/JamieMason/ImageOptim-CLI |

### 📊 System Monitoring

Tools for monitoring system performance and resource usage.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `htop` | Interactive process viewer | Base | ~8MB | https://htop.dev |
| `iotop` | I/O monitoring | Mac Studio | ~12MB | https://guichaz.free.fr/iotop |
| `nload` | Network usage monitor | Mac Studio | ~5MB | https://github.com/rolandriegel/nload |
| `iftop` | Network bandwidth monitor | Mac Studio | ~8MB | https://www.ex-parrot.com/pdw/iftop |
| `bandwhich` | Network bandwidth monitor per process | Mac Studio | ~6MB | https://github.com/imsnif/bandwhich |
| `hyperfine` | Command-line benchmarking tool | Mac Studio | ~4MB | https://github.com/sharkdp/hyperfine |

### 🔒 Security Tools

Network security and vulnerability scanning tools.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `nmap` | Network discovery and security auditing | Base | ~35MB | https://nmap.org |
| `wireshark` | Network protocol analyser | Mac Studio | ~450MB | https://www.wireshark.org |
| `sqlmap` | SQL injection testing tool | Mac Studio | ~85MB | https://sqlmap.org |
| `nikto` | Web vulnerability scanner | Mac Studio | ~25MB | https://cirt.net/Nikto2 |

### 🏠 Home Automation & IoT

Tools for home automation and Internet of Things development.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `mosquitto` | MQTT message broker | Mac Mini | ~15MB | https://mosquitto.org |
| `homebridge` | HomeKit integration platform | Mac Mini | ~180MB | https://homebridge.io |
| `wake` | Wake-on-LAN utility | Mac Mini | ~3MB | https://github.com/jloh/wake |

### 🗂️ File Management & Sync

Tools for file synchronisation, backup, and cloud storage.

| Package | Description | Profile | Disk Usage | URL |
|---------|-------------|---------|------------|-----|
| `rclone` | Cloud storage sync utility | Base | ~85MB | https://rclone.org |
| `restic` | Fast, secure backup program | Mac Studio | ~25MB | https://restic.net |
| `borgbackup` | Deduplicating backup program | Mac Studio | ~120MB | https://www.borgbackup.org |
| `sshfs` | SSH filesystem client | Base | ~18MB | https://github.com/libfuse/sshfs |
| `cifs-utils` | SMB/CIFS filesystem utilities | Base | ~35MB | https://wiki.samba.org/index.php/LinuxCIFS_utils |

---

## 🖥️ Hardware-Specific Configurations

### MacBook Pro (M1 Pro, 32GB)
**Focus**: Mobile productivity, battery optimisation, full development stack

- **Unique Tools**: iOS development tools, battery monitoring, mobile sync
- **Resource Management**: Power-aware services, battery optimisation tools
- **Connectivity**: Enhanced remote access and mobile device integration

### Mac Studio (M1 Max, 32GB)
**Focus**: Always-on server, high-performance workstation, network services

- **Server Tools**: Multiple databases, web servers, monitoring systems
- **Performance**: Full compiler toolchains, virtualisation, big data processing
- **Network**: File sharing services, backup solutions, development servers

### Mac Mini (M4, 16GB)
**Focus**: Home office productivity, media centre, efficient resource usage

- **Memory Conscious**: Lightweight alternatives, efficient applications
- **Home Features**: Media server, home automation, IoT integration
- **Productivity**: Office suites, file management, system maintenance

---

## 🏷️ Profile Mapping

### Minimal Profile (11 packages)
Essential tools only - perfect for servers or testing environments.
**Key Tools**: git, curl, eza, bat, fzf, jq, 1Password, Raycast

### Base Profile (50+ packages)
Core development environment with modern CLI tools.
**Adds**: Python ecosystem, Node.js, databases, monitoring tools

### Development Profile (80+ packages)
Full development stack with CI/CD, containers, and advanced tooling.
**Adds**: Docker, Kubernetes, pre-commit hooks, code quality tools

### Data Science Profile (100+ packages)
Comprehensive ML/AI environment with multiple languages and frameworks.
**Adds**: R, Julia, Spark, TensorFlow/PyTorch ecosystem, cloud tools

---

## 📈 Resource Impact & Disk Usage

### Low Impact (Minimal Profile)
- **Disk space**: ~1.5GB
- **RAM usage**: < 2GB
- **Services**: None auto-started
- **Target**: Basic productivity, testing
- **Key space usage**: Core CLI tools (200MB), GUI apps (1.2GB)

### Medium Impact (Base/Development Profile)
- **Disk space**: ~8-12GB
- **RAM usage**: 4-8GB
- **Services**: Essential databases, web servers
- **Target**: Daily development work
- **Key space usage**: Development tools (3GB), databases (2GB), containers (4-6GB)

### High Impact (Data Science Profile)
- **Disk space**: ~20-35GB
- **RAM usage**: 10-20GB
- **Services**: Multiple databases, analytics platforms
- **Target**: Heavy computational workloads
- **Key space usage**: ML frameworks (8GB), big data tools (5GB), multiple language runtimes (7GB), scientific libraries (10GB)

### Hardware-Specific Additional Usage
- **MacBook Pro**: +2-3GB (iOS dev tools, mobile frameworks)
- **Mac Studio**: +5-8GB (server tools, monitoring, multiple databases)
- **Mac Mini**: +1-2GB (media tools, home automation)

---

## 💾 Disk Space Summary

### Total Installation Size by Profile

| Profile | Package Count | Estimated Disk Usage | RAM Impact |
|---------|---------------|---------------------|------------|
| **Minimal** | ~11 packages | 1.5GB | < 2GB |
| **Base** | ~50 packages | 8-12GB | 4-6GB |
| **Development** | ~80 packages | 15-20GB | 6-10GB |
| **Data Science** | ~100+ packages | 25-35GB | 10-20GB |

### Hardware-Specific Additions

| Hardware | Additional Packages | Extra Disk Usage |
|----------|-------------------|------------------|
| **MacBook Pro** | iOS dev tools, mobile frameworks | +2-3GB |
| **Mac Studio** | Server tools, monitoring, multiple DBs | +5-8GB |
| **Mac Mini** | Media tools, home automation | +1-2GB |

### Largest Space Contributors
1. **Container platforms** (Docker): ~2.8GB per install
2. **Data Science frameworks** (OpenCV: ~2.1GB, Apache Spark: ~800MB)
3. **Cloud SDKs** (Google Cloud SDK: ~850MB, Azure CLI: ~450MB, AWS CLI: ~320MB)
4. **Media tools** (FFmpeg: ~850MB, ImageMagick: ~280MB)
5. **Database systems** (Elasticsearch: ~800MB, ClickHouse: ~650MB, MongoDB: ~450MB)
6. **Security tools** (Wireshark: ~450MB)
7. **Language runtimes** (Julia: ~450MB, Python versions: ~180MB each, Node.js: ~120MB)

*Note: Actual usage may vary based on cached data, virtual environments, and additional packages installed via pip/npm/gem.*

## 🔗 Quick Install Commands

```bash
# Minimal setup (~1.5GB)
brew bundle --file=config/Brewfile.minimal

# Full development environment (~15-20GB)
brew bundle --file=config/Brewfile.development

# Data science stack (~25-35GB)
brew bundle --file=config/Brewfile.data-science

# Hardware-specific (auto-detected)
./install.sh --profile=auto
```

---

## 📚 Additional Resources

- **Homebrew Documentation**: https://docs.brew.sh
- **Profile Configuration**: See `profiles/` directory
- **Hardware Detection**: `scripts/helpers/detect-hardware.zsh`
- **Service Management**: `scripts/services/`

*This summary covers **200+ packages** across all profiles and hardware configurations.*